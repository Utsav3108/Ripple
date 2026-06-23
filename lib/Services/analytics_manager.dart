import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';

class AnalyticsManager {
  static final AnalyticsManager _instance = AnalyticsManager._internal();
  factory AnalyticsManager() => _instance;

  SharedPreferences? _prefs;
  final Dio _dio = Dio();
  DateTime? _sessionStartTime;
  String _clientId = '';

  AnalyticsManager._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load or generate client ID
    _clientId = _prefs?.getString('ga_client_id') ?? '';
    if (_clientId.isEmpty) {
      _clientId = _generateClientId();
      await _prefs?.setString('ga_client_id', _clientId);
    }

    // Check if the app was killed while in the foreground in the previous run
    final lastStart = _prefs?.getInt('last_session_start_time') ?? 0;
    final hasPending = _prefs?.getBool('has_pending_session_end') ?? false;

    if (lastStart > 0 && !hasPending) {
      final lastAction = _prefs?.getInt('last_action_time') ?? lastStart;
      final elapsedSeconds = ((lastAction - lastStart) / 1000).round();
      if (elapsedSeconds > 0) {
        await _prefs?.setInt('pending_session_duration', elapsedSeconds);
        await _prefs?.setBool('has_pending_session_end', true);
        await _prefs?.setInt('total_duration_seconds', (_prefs?.getInt('total_duration_seconds') ?? 0) + elapsedSeconds);
      }
    }

    // Start initial session
    startSession();
  }

  String get clientId => _clientId;

  String _generateClientId() {
    final random = Random();
    final part1 = DateTime.now().millisecondsSinceEpoch;
    final part2 = random.nextInt(1000000);
    return 'client_${part1}_$part2';
  }

  // Dispatch any queued session ends (from crash, force-close, or background transitions)
  Future<void> dispatchQueuedEvents() async {
    final hasPending = _prefs?.getBool('has_pending_session_end') ?? false;
    if (hasPending) {
      final elapsed = _prefs?.getInt('pending_session_duration') ?? 0;
      await _logGAEvent('session_end', {'session_duration_seconds': elapsed});
      await _prefs?.setBool('has_pending_session_end', false);
      await _prefs?.remove('last_session_start_time');
    }
  }

  // Session Tracking
  void startSession() {
    if (_sessionStartTime != null) return;
    
    // First, dispatch any queued session end from a previous run or background transition
    dispatchQueuedEvents();

    _sessionStartTime = DateTime.now();
    final nowMs = _sessionStartTime!.millisecondsSinceEpoch;
    
    // Track session timing metadata in SharedPreferences for crash/force-close recovery
    _prefs?.setInt('last_session_start_time', nowMs);
    _prefs?.setInt('last_action_time', nowMs);
    _prefs?.setBool('has_pending_session_end', false);

    _prefs?.setInt('total_sessions', (_prefs?.getInt('total_sessions') ?? 0) + 1);
    _logGAEvent('session_start', {});
  }

  void endSession() {
    if (_sessionStartTime == null) return;
    final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
    
    _prefs?.setInt('total_duration_seconds', (_prefs?.getInt('total_duration_seconds') ?? 0) + elapsed);
    
    // Queue the session end event to be sent reliably
    _prefs?.setInt('pending_session_duration', elapsed);
    _prefs?.setBool('has_pending_session_end', true);

    _sessionStartTime = null;
    
    // Attempt best-effort immediate dispatch (works on fast background connections)
    _logGAEvent('session_end', {'session_duration_seconds': elapsed});
  }

  // Persona Tracking
  void trackPlayPersona(int id, String name) {
    _incrementPlayCount('persona_plays', name);
    _prefs?.setInt('chats_started', (_prefs?.getInt('chats_started') ?? 0) + 1);
    _logGAEvent('play_persona', {'persona_id': id, 'persona_name': name});
  }

  void trackLeaveChatMidway(int id, String name) {
    _prefs?.setInt('chats_left_midway', (_prefs?.getInt('chats_left_midway') ?? 0) + 1);
    _logGAEvent('leave_chat_midway', {'persona_id': id, 'persona_name': name});
  }

  // Challenge Tracking
  void trackPlayChallenge(String id, String title) {
    _incrementPlayCount('challenge_plays', title);
    _prefs?.setInt('challenges_started', (_prefs?.getInt('challenges_started') ?? 0) + 1);
    _logGAEvent('play_challenge', {'challenge_id': id, 'challenge_title': title});
  }

  void trackCompleteChallenge(String id, String title, bool won) {
    _prefs?.setInt('challenges_completed', (_prefs?.getInt('challenges_completed') ?? 0) + 1);
    _logGAEvent('complete_challenge', {
      'challenge_id': id,
      'challenge_title': title,
      'result': won ? 'won' : 'lost'
    });
  }

  void trackLeaveChallengeMidway(String id, String title) {
    _prefs?.setInt('challenges_left_midway', (_prefs?.getInt('challenges_left_midway') ?? 0) + 1);
    _logGAEvent('leave_challenge_midway', {'challenge_id': id, 'challenge_title': title});
  }

  // Local Metric Getters
  int get totalSessions => _prefs?.getInt('total_sessions') ?? 0;
  int get totalDurationSeconds => _prefs?.getInt('total_duration_seconds') ?? 0;

  double getAverageAppSessionTime() {
    final sessions = totalSessions;
    if (sessions == 0) return 0.0;
    return totalDurationSeconds / sessions;
  }

  MapEntry<String, int>? getMostPlayedPersona() {
    return _getMostPlayed('persona_plays');
  }

  MapEntry<String, int>? getMostPlayedChallenge() {
    return _getMostPlayed('challenge_plays');
  }

  double getChatMidwayExitRate() {
    final started = _prefs?.getInt('chats_started') ?? 0;
    if (started == 0) return 0.0;
    final left = _prefs?.getInt('chats_left_midway') ?? 0;
    return (left / started) * 100;
  }

  double getChallengeMidwayExitRate() {
    final started = _prefs?.getInt('challenges_started') ?? 0;
    if (started == 0) return 0.0;
    final left = _prefs?.getInt('challenges_left_midway') ?? 0;
    return (left / started) * 100;
  }

  // Internal Helpers
  void _incrementPlayCount(String key, String item) {
    final raw = _prefs?.getString(key);
    Map<String, int> counts = {};
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          counts = decoded.map((k, v) => MapEntry(k.toString(), v as int));
        }
      } catch (e) {
        print("Error decoding counts: $e");
      }
    }
    counts[item] = (counts[item] ?? 0) + 1;
    _prefs?.setString(key, jsonEncode(counts));
  }

  MapEntry<String, int>? _getMostPlayed(String key) {
    final raw = _prefs?.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded.isNotEmpty) {
        final counts = decoded.map((k, v) => MapEntry(k.toString(), v as int));
        MapEntry<String, int>? topEntry;
        for (final entry in counts.entries) {
          if (topEntry == null || entry.value > topEntry.value) {
            topEntry = entry;
          }
        }
        return topEntry;
      }
    } catch (e) {
      print("Error decoding counts: $e");
    }
    return null;
  }

  // Send Event to GA4 Measurement Protocol
  Future<void> _logGAEvent(String eventName, Map<String, dynamic> params) async {
    // Keep track of the last time the user did something in the app
    _prefs?.setInt('last_action_time', DateTime.now().millisecondsSinceEpoch);

    final measurementId = AppConfig.gaMeasurementId;
    final apiSecret = AppConfig.gaApiSecret;

    if (measurementId.isEmpty || apiSecret.isEmpty || measurementId == 'G-XXXXXXXXXX') {
      print("Google Analytics event '$eventName' skipped (Credentials not configured).");
      return;
    }

    final url = 'https://www.google-analytics.com/mp/collect?measurement_id=$measurementId&api_secret=$apiSecret';

    // Calculate actual active session duration in milliseconds for the GA4 engagement time parameter
    int engagementTimeMs = 100; // standard minimum value
    if (eventName == 'session_end' && params.containsKey('session_duration_seconds')) {
      engagementTimeMs = (params['session_duration_seconds'] as int) * 1000;
    } else if (_sessionStartTime != null) {
      engagementTimeMs = DateTime.now().difference(_sessionStartTime!).inMilliseconds;
      if (engagementTimeMs < 0) engagementTimeMs = 100;
    }

    final body = {
      'client_id': _clientId,
      'events': [
        {
          'name': eventName,
          'params': {
            ...params,
            'engagement_time_msec': engagementTimeMs, // type: integer
          },
        }
      ]
    };

    try {
      final response = await _dio.post(
        url,
        data: jsonEncode(body),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
      print("Google Analytics event '$eventName' sent. Status code: ${response.statusCode}");
    } catch (e) {
      print("Error sending Google Analytics event: $e");
    }
  }
}

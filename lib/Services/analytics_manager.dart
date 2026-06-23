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

  // Session Tracking
  void startSession() {
    if (_sessionStartTime != null) return;
    _sessionStartTime = DateTime.now();
    _prefs?.setInt('total_sessions', (_prefs?.getInt('total_sessions') ?? 0) + 1);
    _logGAEvent('session_start', {});
  }

  void endSession() {
    if (_sessionStartTime == null) return;
    final elapsed = DateTime.now().difference(_sessionStartTime!).inSeconds;
    _prefs?.setInt('total_duration_seconds', (_prefs?.getInt('total_duration_seconds') ?? 0) + elapsed);
    _sessionStartTime = null;
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
    final measurementId = AppConfig.gaMeasurementId;
    final apiSecret = AppConfig.gaApiSecret;

    if (measurementId.isEmpty || apiSecret.isEmpty || measurementId == 'G-XXXXXXXXXX') {
      print("Google Analytics event '$eventName' skipped (Credentials not configured).");
      return;
    }

    final url = 'https://www.google-analytics.com/mp/collect?measurement_id=$measurementId&api_secret=$apiSecret';

    final body = {
      'client_id': _clientId,
      'events': [
        {
          'name': eventName,
          'params': {
            ...params,
            'engagement_time_msec': '100', // standard metadata parameter
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

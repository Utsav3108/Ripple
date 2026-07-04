import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Network/network_manager.dart';
import '../Network/socket_manager.dart';
import '../Model/model.dart';
import '../core/config/app_config.dart';
import '../main.dart';
import '../Services/analytics_manager.dart';

class ChatProvider with ChangeNotifier, WidgetsBindingObserver {
  final Network _network = Network();
  final SocketManager _socketManager = SocketManager();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  List<Persona> _chats = [];
  List<Message> _messages = [];
  List<Persona> _searchResults = [];
  List<Challenge> _challengeSearchResults = [];
  List<Challenge> _challenges = [];
  List<Persona> _allPersonas = [];
  
  Challenge? _dailyChallenge;
  List<Challenge> _trendingChallenges = [];
  List<Challenge> _recommendedChallenges = [];
  List<Challenge> _recentlyAddedChallenges = [];
  bool _isDashboardLoading = false;
  
  String _userEmail = '';
  String _userRole = '';
  String _userBio = '';
  String _userImageUrl = '';
  Map<String, dynamic>? _userSettings;
  int _totalChallengesAttempted = 0;
  double _successRatePercentage = 0.0;
  int _totalPracticeSessions = 0;
  List<ProfileAttemptLogItem> _profileAttemptsLog = [];
  bool _isProfileLoading = false;
  bool _isLoading = false;
  bool _isMessagesLoading = false;
  bool _isSearching = false;
  bool _isChallengesLoading = false;
  String? _errorMessage;
  int? _activePersonaId;

  bool _hasMoreMessages = false;
  bool _isFetchingOlderMessages = false;
  int _currentMessagePage = 1;
  int _totalMessagePages = 1;

  bool get hasMoreMessages => _hasMoreMessages;
  bool get isFetchingOlderMessages => _isFetchingOlderMessages;

  List<ChallengeSession> _activeSessions = [];
  List<ChallengeSession> get activeSessions => _activeSessions;
  bool _isActiveSessionsLoading = false;
  bool get isActiveSessionsLoading => _isActiveSessionsLoading;

  final Map<String, int> _challengeAttemptCounts = {};
  Map<String, int> get challengeAttemptCounts => _challengeAttemptCounts;

  List<Persona> get chats => _chats;
  List<Message> get messages => _messages;
  List<Persona> get searchResults => _searchResults;
  List<Challenge> get challengeSearchResults => _challengeSearchResults;
  List<Challenge> get challenges => _challenges;
  List<Persona> get allPersonas => _allPersonas;

  Challenge? get dailyChallenge => _dailyChallenge;
  List<Challenge> get trendingChallenges => _trendingChallenges;
  List<Challenge> get recommendedChallenges => _recommendedChallenges;
  List<Challenge> get recentlyAddedChallenges => _recentlyAddedChallenges;
  bool get isDashboardLoading => _isDashboardLoading;
  
  String get userEmail => _userEmail;
  String get userRole => _userRole;
  String get userBio => _userBio;
  String get userImageUrl => _userImageUrl;
  Map<String, dynamic>? get userSettings => _userSettings;
  int get totalChallengesAttempted => _totalChallengesAttempted;
  double get successRatePercentage => _successRatePercentage;
  int get totalPracticeSessions => _totalPracticeSessions;
  List<ProfileAttemptLogItem> get profileAttemptsLog => _profileAttemptsLog;
  bool get isProfileLoading => _isProfileLoading;
  
  bool get isLoading => _isLoading;
  bool get isMessagesLoading => _isMessagesLoading;
  bool get isSearching => _isSearching;
  bool get isChallengesLoading => _isChallengesLoading;
  String? get errorMessage => _errorMessage;

  // Challenge flow states
  int? _currentChallengeSessionId;
  int? get currentChallengeSessionId => _currentChallengeSessionId;

  Map<String, dynamic>? _currentChallengeIntro;
  Map<String, dynamic>? get currentChallengeIntro => _currentChallengeIntro;

  String? _currentChallengeStatus;
  String? get currentChallengeStatus => _currentChallengeStatus;

  int? _currentChallengeDuration;
  int? get currentChallengeDuration => _currentChallengeDuration;

  int _currentChallengeElapsedSeconds = 0;
  int get currentChallengeElapsedSeconds => _currentChallengeElapsedSeconds;

  int? _currentUserId;
  int? get currentUserId => _currentUserId;
  bool get isAuthenticated => _currentUserId != null;
  String _userName = 'Utsav';
  String get userName => _userName;

  // Callback to propagate challenge_completed event to screen listener
  Function(Map<String, dynamic>)? onChallengeCompletedEvent;

  ChatProvider() {
    _network.onUnauthorised = () {
      logout();
    };
    _initSocket();
    _initGoogleSignIn();
    tryAutoLogin();
    WidgetsBinding.instance.addObserver(this);
    AnalyticsManager().init();
  }

  void _initGoogleSignIn() {
    _googleSignIn.initialize(serverClientId: AppConfig.serverClientId).then((_) {
      print("Google Sign In initialized successfully");
    }).catchError((error) {
      print("Failed to initialize Google Sign In: $error");
    });
  }

  void _initSocket() {
    _socketManager.onMessageReceived = (data) {
      if (_currentUserId == null) return;
      final newMessage = Message.fromJson(data, _currentUserId!);
      
      bool isRelevant = false;
      if (_currentChallengeSessionId != null) {
        // In challenge mode, check if challenge session matches
        final msgSessionId = data['challenge_session_id'] ?? data['challenge_session']?['id'];
        if (msgSessionId != null && msgSessionId.toString() == _currentChallengeSessionId.toString()) {
          isRelevant = true;
        }
      } else {
        // In normal mode, check if the message is between _currentUserId and _activePersonaId
        if (_activePersonaId != null && 
            ((newMessage.senderId == _currentUserId! && newMessage.receiverId == _activePersonaId) ||
             (newMessage.senderId == _activePersonaId && newMessage.receiverId == _currentUserId!))) {
          isRelevant = true;
        }
      }

      if (isRelevant) {
        // Check if message already exists (to avoid duplicates if server broadcasts back to sender)
        if (!_messages.any((m) => m.id == newMessage.id && m.id != 0)) {
          _messages.add(newMessage);
          notifyListeners();
        }
      }
    };
    _socketManager.onChallengeCompleted = (data) {
      if (onChallengeCompletedEvent != null) {
        onChallengeCompletedEvent!(data);
      }
    };
  }

  Future<void> fetchChattedPersonas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/personas/${_currentUserId!}',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        _chats = (response.data as List)
            .map((json) => Persona.fromJson(json))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChallenges() async {
    _isChallengesLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/challenges',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        _challenges = (response.data as List)
            .map((json) => Challenge.fromJson(json))
            .toList();
      }

      await fetchChallengesDashboard();
    } catch (e) {
      _errorMessage = e.toString();
      print("Error fetching challenges: $e");
    } finally {
      _isChallengesLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchChallengesDashboard() async {
    _isDashboardLoading = true;
    notifyListeners();

    try {
      final request = Request(
        url: '/challenges/dashboard',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        _dailyChallenge = data['daily_challenge'] != null
            ? Challenge.fromJson(Map<String, dynamic>.from(data['daily_challenge'] as Map))
            : null;
        _trendingChallenges = data['trending_challenges'] is List
            ? (data['trending_challenges'] as List)
                .map((json) => Challenge.fromJson(Map<String, dynamic>.from(json as Map)))
                .toList()
            : [];
        _recommendedChallenges = data['recommended_challenges'] is List
            ? (data['recommended_challenges'] as List)
                .map((json) => Challenge.fromJson(Map<String, dynamic>.from(json as Map)))
                .toList()
            : [];
        _recentlyAddedChallenges = data['recently_added_challenges'] is List
            ? (data['recently_added_challenges'] as List)
                .map((json) => Challenge.fromJson(Map<String, dynamic>.from(json as Map)))
                .toList()
            : [];
      }
    } catch (e) {
      print("Error fetching challenges dashboard: $e");
    } finally {
      _isDashboardLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActiveSessions() async {
    _isActiveSessionsLoading = true;
    notifyListeners();
    try {
      final request = Request(
        url: '/challenge-sessions/active',
        method: HTTPMethod.GET,
      );
      final response = await _network.performRequest(request);
      if (response.data is List) {
        _activeSessions = (response.data as List)
            .map((json) => ChallengeSession.fromJson(json))
            .toList();
            
        // Pre-fetch attempt counts for any active sessions
        for (var session in _activeSessions) {
          fetchAttemptCountForChallenge(session.challengeId);
        }
      }
    } catch (e) {
      print("Error fetching active sessions: $e");
    } finally {
      _isActiveSessionsLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAttemptCountForChallenge(String challengeId) async {
    if (_challengeAttemptCounts.containsKey(challengeId)) return;
    try {
      final attempts = await fetchChallengeAttempts(challengeId);
      _challengeAttemptCounts[challengeId] = attempts.length;
      notifyListeners();
    } catch (e) {
      print("Error fetching attempts for challenge $challengeId: $e");
    }
  }

  Future<void> searchPersonas(String query, {int limit = 10, int offset = 0, bool loadMore = false}) async {
    if (!loadMore) {
      _isSearching = true;
      if (query.isEmpty) {
        _searchResults = [];
      }
      notifyListeners();
    }

    try {
      final url = query.isEmpty 
          ? '/all-persona' 
          : '/search-personas/$query';

      final request = Request(
        url: url,
        method: HTTPMethod.GET,
        body: {
          'limit': limit,
          'offset': offset,
        },
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        final newResults = (response.data as List)
            .map((json) => Persona.fromJson(json))
            .toList();
        if (loadMore) {
          _searchResults.addAll(newResults);
        } else {
          _searchResults = newResults;
        }
      }
    } catch (e) {
      print("Error searching personas: $e");
      if (!loadMore) {
        _searchResults = [];
      }
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> searchChallenges(String query, {int limit = 10, int offset = 0, bool loadMore = false}) async {
    if (!loadMore) {
      _isSearching = true;
      if (query.isEmpty) {
        _challengeSearchResults = [];
      }
      notifyListeners();
    }

    try {
      final request = Request(
        url: '/challenges',
        method: HTTPMethod.GET,
        body: {
          if (query.isNotEmpty) 'q': query,
          'limit': limit,
          'offset': offset,
        },
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        final newResults = (response.data as List)
            .map((json) => Challenge.fromJson(json))
            .toList();
        if (loadMore) {
          _challengeSearchResults.addAll(newResults);
        } else {
          _challengeSearchResults = newResults;
        }
      }
    } catch (e) {
      print("Error searching challenges: $e");
      if (!loadMore) {
        _challengeSearchResults = [];
      }
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void clearChallengeSearchResults() {
    _challengeSearchResults = [];
    notifyListeners();
  }

  Future<PaginatedMessages?> fetchConversationPage({
    int page = 1,
    int pageSize = 10,
    int? senderId,
    int? receiverId,
    int? challengeSessionId,
    int? attemptSessionId,
  }) async {
    try {
      final bodyParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
      };
      if (senderId != null) bodyParams['sender_id'] = senderId;
      if (receiverId != null) bodyParams['receiver_id'] = receiverId;
      if (challengeSessionId != null) bodyParams['challenge_session_id'] = challengeSessionId;
      if (attemptSessionId != null) bodyParams['attempt_session_id'] = attemptSessionId;

      final request = Request(
        url: '/conversations',
        method: HTTPMethod.GET,
        body: bodyParams,
      );

      final response = await _network.performRequest(request);

      if (response.data is Map) {
        return PaginatedMessages.fromJson(
          Map<String, dynamic>.from(response.data as Map),
          _currentUserId!,
        );
      }
    } catch (e) {
      print("Error fetching conversation page: $e");
    }
    return null;
  }

  Future<void> fetchMessages(int receiverId) async {
    _activePersonaId = receiverId;
    
    // Track play_persona event
    String personaName = 'Unknown Persona';
    try {
      final p = getPersonaById(receiverId);
      if (p != null) {
        personaName = p.name;
      }
    } catch (_) {}
    AnalyticsManager().trackPlayPersona(receiverId, personaName);

    _socketManager.emitJoin(_currentUserId!); // Join user's socket room
    _isMessagesLoading = true;
    _messages = [];
    
    // Reset pagination state
    _currentMessagePage = 1;
    _hasMoreMessages = false;
    _totalMessagePages = 1;
    
    notifyListeners();

    try {
      final result = await fetchConversationPage(
        page: 1,
        pageSize: 10,
        senderId: _currentUserId!,
        receiverId: receiverId,
      );

      if (result != null) {
        _messages = result.messages;
        _hasMoreMessages = result.hasMore;
        _totalMessagePages = result.totalPages;
      }
    } catch (e) {
      print("Error fetching messages: $e");
    } finally {
      _isMessagesLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMessages() async {
    if (_isFetchingOlderMessages || !_hasMoreMessages) return;
    _isFetchingOlderMessages = true;
    notifyListeners();

    final nextPage = _currentMessagePage + 1;
    PaginatedMessages? result;

    if (_currentChallengeSessionId != null) {
      result = await fetchConversationPage(
        page: nextPage,
        pageSize: 10,
        challengeSessionId: _currentChallengeSessionId,
      );
    } else if (_activePersonaId != null) {
      result = await fetchConversationPage(
        page: nextPage,
        pageSize: 10,
        senderId: _currentUserId!,
        receiverId: _activePersonaId,
      );
    }

    if (result != null) {
      _messages.insertAll(0, result.messages); // Prepend older messages
      _currentMessagePage = nextPage;
      _hasMoreMessages = result.hasMore;
    }
    
    _isFetchingOlderMessages = false;
    notifyListeners();
  }

  Future<void> fetchAllPersonas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/all-persona',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        _allPersonas = (response.data as List)
            .map((json) => Persona.fromJson(json))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
      print("Error fetching all personas: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createPersona({
    required String name,
    required String desc,
    required String traits,
    required String imageUrl,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final request = Request(
        url: '/personas',
        method: HTTPMethod.POST,
        body: {
          'name': name,
          'desc': desc,
          'traits': traits,
          'image_url': imageUrl,
        },
      );
      await _network.performRequest(request);
      await fetchAllPersonas();
      await fetchChattedPersonas();
    } catch (e) {
      print("Error creating persona: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createChallenge(Map<String, dynamic> challengeData) async {
    _isLoading = true;
    notifyListeners();
    try {
      final request = Request(
        url: '/challenges',
        method: HTTPMethod.POST,
        body: challengeData,
      );
      await _network.performRequest(request);
      await fetchChallenges();
    } catch (e) {
      print("Error creating challenge: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedToken = prefs.getString('auth_token');
    if (storedToken == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _network.setToken(storedToken);
      
      // Call profile endpoint to verify token validity
      final request = Request(
        url: '/profile',
        method: HTTPMethod.GET,
      );
      final response = await _network.performRequest(request);
      
      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        _currentUserId = data['id'] is int ? data['id'] as int : int.parse(data['id'].toString());
        _userName = data['name']?.toString() ?? 'User';
        _userEmail = data['email']?.toString() ?? '';
        _userRole = data['role']?.toString() ?? '';
        _userBio = data['bio']?.toString() ?? '';
        _userImageUrl = data['image_url']?.toString() ?? '';
        _userSettings = data['settings'] is Map ? Map<String, dynamic>.from(data['settings'] as Map) : null;
        
        final stats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats'] as Map) : {};
        _totalChallengesAttempted = stats['total_challenges_attempted'] is int ? stats['total_challenges_attempted'] as int : 0;
        _successRatePercentage = stats['success_rate_percentage'] is num ? (stats['success_rate_percentage'] as num).toDouble() : 0.0;
        _totalPracticeSessions = stats['total_practice_sessions'] is int ? stats['total_practice_sessions'] as int : 0;

        if (data['attempts_log'] is List) {
          _profileAttemptsLog = (data['attempts_log'] as List)
              .map((json) => ProfileAttemptLogItem.fromJson(Map<String, dynamic>.from(json as Map)))
              .take(5)
              .toList();
        } else {
          _profileAttemptsLog = [];
        }

        // Connect Socket
        _socketManager.connect(_currentUserId!);
        
        // Fetch data
        await fetchChattedPersonas();
        await fetchChallenges();
        await fetchActiveSessions();
        await fetchAllPersonas();
      }
    } catch (e) {
      print("Stored token verification failed, trying Google silent sign-in: $e");
      // If we failed due to 401/expired token, try Google Silent Sign-In
      try {
        final Future<GoogleSignInAccount?>? autoAuthFuture = _googleSignIn.attemptLightweightAuthentication();
        if (autoAuthFuture != null) {
          final GoogleSignInAccount? googleUser = await autoAuthFuture;
          if (googleUser != null) {
            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
            final String? idToken = googleAuth.idToken;
            if (idToken != null) {
              _network.setToken(idToken);
              await prefs.setString('auth_token', idToken);
              
              // Login with fresh token
              final loginRequest = Request(
                url: '/auth/google',
                method: HTTPMethod.POST,
                body: {
                  'id_token': idToken,
                },
              );
              final response = await _network.performRequest(loginRequest);
              if (response.data is Map) {
                final data = Map<String, dynamic>.from(response.data as Map);
                _currentUserId = data['id'] is int ? data['id'] as int : int.parse(data['id'].toString());
                _userName = data['name']?.toString() ?? googleUser.displayName ?? 'User';
                _userImageUrl = data['image_url']?.toString() ?? googleUser.photoUrl ?? '';
                
                _socketManager.connect(_currentUserId!);
                await fetchChattedPersonas();
                await fetchChallenges();
                await fetchActiveSessions();
                await fetchAllPersonas();
                await fetchUserProfile();
              }
              return;
            }
          }
        }
      } catch (silentError) {
        print("Google silent sign-in failed: $silentError");
      }
      
      // If silent sign in also fails, clean up
      _network.clearToken();
      await prefs.remove('auth_token');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _googleSignIn.initialize(serverClientId: AppConfig.serverClientId);
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        throw Exception("Google Sign-In was cancelled by user.");
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      
      if (idToken == null) {
        throw Exception("Failed to retrieve Google ID Token.");
      }

      _network.setToken(idToken);
      
      // Store token in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', idToken);

      final request = Request(
        url: '/auth/google',
        method: HTTPMethod.POST,
        body: {
          'id_token': idToken,
        },
      );
      final response = await _network.performRequest(request);
      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        _currentUserId = data['id'] is int ? data['id'] as int : int.parse(data['id'].toString());
        _userName = data['name']?.toString() ?? googleUser.displayName ?? 'User';
        _userImageUrl = data['image_url']?.toString() ?? googleUser.photoUrl ?? '';
        
        // Connect Socket
        _socketManager.connect(_currentUserId!);
        
        // Fetch data
        await fetchChattedPersonas();
        await fetchChallenges();
        await fetchActiveSessions();
        await fetchAllPersonas();
        await fetchUserProfile();
      }
    } catch (e) {
      _errorMessage = e.toString();
      print("Error logging in: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _currentUserId = null;
    _socketManager.disconnect();
    _chats = [];
    _challenges = [];
    _messages = [];
    _network.clearToken();
    
    // Clear token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    _googleSignIn.disconnect().catchError((error) {
      print("Error disconnecting Google Sign In: $error");
    });
    // Pop all screens to root (LoginScreen/ChatListScreen)
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    notifyListeners();
  }


  Persona? getPersonaById(int id) {
    try {
      return _allPersonas.firstWhere((p) => p.id == id);
    } catch (_) {
      try {
        return _chats.firstWhere((p) => p.id == id);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> setupChallenge({
    required String challengeId,
    required int personaId,
    int? attemptSessionId,
  }) async {
    _activePersonaId = personaId;
    _isLoading = true;
    _errorMessage = null;
    
    // Wipe stale challenge session variables immediately on entry
    _currentChallengeSessionId = null;
    _currentChallengeIntro = null;
    _currentChallengeStatus = null;
    _currentChallengeDuration = null;
    _currentChallengeElapsedSeconds = 0;
    _messages = [];
    notifyListeners();

    try {
      if (attemptSessionId == null) {
        String challengeTitle = 'Unknown Challenge';
        try {
          final ch = _challenges.firstWhere((c) => c.id == challengeId);
          challengeTitle = ch.title;
        } catch (_) {
          try {
            final ch = _challengeSearchResults.firstWhere((c) => c.id == challengeId);
            challengeTitle = ch.title;
          } catch (_) {}
        }
        AnalyticsManager().trackPlayChallenge(challengeId, challengeTitle);
      }

      final request = Request(
        url: '/setup_challenge',
        method: HTTPMethod.POST,
        body: {
          'challenge_id': challengeId,
          'persona_id': personaId,
          'user_id': _currentUserId!,
          if (attemptSessionId != null) 'attempt_session_id': attemptSessionId,
        },
      );

      final response = await _network.performRequest(request);

      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        
        final rawSessionId = data['challenge_session_id'];
        _currentChallengeSessionId = rawSessionId is int 
            ? rawSessionId 
            : (rawSessionId != null ? int.tryParse(rawSessionId.toString()) : null);

        _currentChallengeIntro = data['intro'] is Map ? Map<String, dynamic>.from(data['intro']) : null;
        _currentChallengeStatus = data['status']?.toString();
        
        final rawDuration = data['total_duration_minutes'];
        _currentChallengeDuration = rawDuration is int 
            ? rawDuration 
            : (rawDuration != null ? int.tryParse(rawDuration.toString()) : null);

        final rawElapsed = data['elapsed_seconds'];
        _currentChallengeElapsedSeconds = rawElapsed is int 
            ? rawElapsed 
            : (rawElapsed != null ? int.tryParse(rawElapsed.toString()) ?? 0 : 0);

        // Reset pagination state
        _currentMessagePage = 1;
        _hasMoreMessages = false;
        _totalMessagePages = 1;
        _messages = [];

        if (_currentChallengeSessionId != null) {
          final result = await fetchConversationPage(
            page: 1,
            pageSize: 10,
            challengeSessionId: _currentChallengeSessionId,
          );
          if (result != null) {
            _messages = result.messages;
            _hasMoreMessages = result.hasMore;
            _totalMessagePages = result.totalPages;
          }
        }

        // Bypassing socket connections for read-only historical attempt viewers
        if (_currentChallengeSessionId != null && attemptSessionId == null) {
          // Socket order: Setup API, Emit Join, Emit Join Challenge
          _socketManager.emitJoin(_currentUserId!);
          _socketManager.emitJoinChallenge(_currentChallengeSessionId!);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      print("Error setting up challenge: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ChallengeAttempt>> fetchChallengeAttempts(String challengeId) async {
    try {
      final request = Request(
        url: '/challenge-attempts/$challengeId',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        return (response.data as List)
            .map((json) => ChallengeAttempt.fromJson(json))
            .toList();
      }
    } catch (e) {
      print("Error fetching challenge attempts: $e");
    }
    return [];
  }

  Future<void> completeChallenge(String status, {String? reason}) async {
    if (_currentChallengeSessionId == null) return;
    
    try {
      _socketManager.emitCompleteChallenge(
        _currentChallengeSessionId!,
        status,
        reason: reason,
      );
      _currentChallengeStatus = status;
      notifyListeners();
    } catch (e) {
      print("Error completing challenge: $e");
    }
  }

  void clearChallengeSession() {
    _currentChallengeSessionId = null;
    _currentChallengeIntro = null;
    _currentChallengeStatus = null;
    _currentChallengeDuration = null;
    _activePersonaId = null;
    notifyListeners();
  }

  void sendMessage(int receiverId, String text) {
    if (text.trim().isEmpty) return;

    // Optimistically add to list
    final tempMessage = Message(
      id: 0, // Temporary ID
      senderId: _currentUserId!,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
      isUser: true,
    );
    
    _messages.add(tempMessage);
    notifyListeners();

    // Send via socket
    _socketManager.sendMessage(
      _currentUserId!,
      receiverId,
      text,
      challengeSessionId: _currentChallengeSessionId,
    );
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    _isProfileLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/profile',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        _userEmail = data['email']?.toString() ?? '';
        _userRole = data['role']?.toString() ?? '';
        _userBio = data['bio']?.toString() ?? '';
        _userImageUrl = data['image_url']?.toString() ?? '';
        _userSettings = data['settings'] is Map ? Map<String, dynamic>.from(data['settings'] as Map) : null;
        
        final stats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats'] as Map) : {};
        _totalChallengesAttempted = stats['total_challenges_attempted'] is int ? stats['total_challenges_attempted'] as int : 0;
        _successRatePercentage = stats['success_rate_percentage'] is num ? (stats['success_rate_percentage'] as num).toDouble() : 0.0;
        _totalPracticeSessions = stats['total_practice_sessions'] is int ? stats['total_practice_sessions'] as int : 0;

        if (data['attempts_log'] is List) {
          _profileAttemptsLog = (data['attempts_log'] as List)
              .map((json) => ProfileAttemptLogItem.fromJson(Map<String, dynamic>.from(json as Map)))
              .take(5)
              .toList();
        } else {
          _profileAttemptsLog = [];
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      print("Error fetching user profile: $e");
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserProfile({
    required String role,
    required String bio,
    Map<String, dynamic>? settings,
  }) async {
    _isProfileLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/profile',
        method: HTTPMethod.PUT,
        body: {
          'role': role,
          'bio': bio,
          if (settings != null) 'settings': settings,
        },
      );

      await _network.performRequest(request);
      
      // Update local state
      _userRole = role;
      _userBio = bio;
      if (settings != null) {
        _userSettings = settings;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print("Error updating user profile: $e");
      rethrow;
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  List<Category> _categories = [];
  List<Category> get categories => _categories;
  bool _isCategoriesLoading = false;
  bool get isCategoriesLoading => _isCategoriesLoading;

  Future<void> fetchCategories() async {
    _isCategoriesLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/categories',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        _categories = (response.data as List)
            .map((json) => Category.fromJson(json))
            .toList();
      }
    } catch (e) {
      _errorMessage = e.toString();
      print("Error fetching categories: $e");
    } finally {
      _isCategoriesLoading = false;
      notifyListeners();
    }
  }

  String? getPromptForMessage(Message msg) {
    final index = _messages.indexOf(msg);
    if (index > 0 && _messages[index - 1].isUser) {
      return _messages[index - 1].text;
    }
    return null;
  }

  Future<bool> reportAIContent({
    required int messageId,
    required int personaId,
    required String aiResponse,
    required String reason,
    int? conversationId,
    String? userPrompt,
    String? comment,
  }) async {
    try {
      final request = Request(
        url: '/reports/ai-content',
        method: HTTPMethod.POST,
        body: {
          'message_id': messageId,
          'persona_id': personaId,
          'ai_response': aiResponse,
          'reason': reason,
          if (conversationId != null) 'conversation_id': conversationId,
          if (userPrompt != null) 'user_prompt': userPrompt,
          if (comment != null) 'description': comment,
        },
      );

      final response = await _network.performRequest(request);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Error reporting AI content: $e");
      return false;
    }
  }

  void leaveChat(int userId, {int? personaId, int? challengeSessionId}) {
    print("DEBUG: ChatProvider.leaveChat called for user $userId, persona $personaId, session $challengeSessionId");
    _socketManager.emitLeaveChat(
      userId,
      personaId: personaId,
      challengeSessionId: challengeSessionId,
    );
  }

  Future<void> pauseChallengeSession() async {
    if (_currentChallengeSessionId == null) return;
    try {
      final request = Request(
        url: '/challenge-sessions/$_currentChallengeSessionId/pause',
        method: HTTPMethod.POST,
      );
      await _network.performRequest(request);
    } catch (e) {
      print("Error pausing challenge session: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      AnalyticsManager().endSession();
    } else if (state == AppLifecycleState.resumed) {
      AnalyticsManager().startSession();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _socketManager.disconnect();
    super.dispose();
  }
}

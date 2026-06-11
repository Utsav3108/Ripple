import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../Network/network_manager.dart';
import '../Network/socket_manager.dart';
import '../Model/model.dart';
import '../core/config/app_config.dart';

class ChatProvider with ChangeNotifier {
  final Network _network = Network();
  final SocketManager _socketManager = SocketManager();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  List<Persona> _chats = [];
  List<Message> _messages = [];
  List<Persona> _searchResults = [];
  List<Challenge> _challenges = [];
  List<Persona> _allPersonas = [];
  
  bool _isLoading = false;
  bool _isMessagesLoading = false;
  bool _isSearching = false;
  bool _isChallengesLoading = false;
  String? _errorMessage;
  int? _activePersonaId;

  List<Persona> get chats => _chats;
  List<Message> get messages => _messages;
  List<Persona> get searchResults => _searchResults;
  List<Challenge> get challenges => _challenges;
  List<Persona> get allPersonas => _allPersonas;
  
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

  int? _currentUserId;
  int? get currentUserId => _currentUserId;
  bool get isAuthenticated => _currentUserId != null;
  String _userName = 'Utsav';
  String get userName => _userName;

  // Callback to propagate challenge_completed event to screen listener
  Function(Map<String, dynamic>)? onChallengeCompletedEvent;

  ChatProvider() {
    _initSocket();
    _initGoogleSignIn();
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
    } catch (e) {
      _errorMessage = e.toString();
      print("Error fetching challenges: $e");
    } finally {
      _isChallengesLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPersonas(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final request = Request(
        url: '/search-personas/$query',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        _searchResults = (response.data as List)
            .map((json) => Persona.fromJson(json))
            .toList();
      }
    } catch (e) {
      print("Error searching personas: $e");
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(int receiverId) async {
    _activePersonaId = receiverId;
    _socketManager.emitJoin(receiverId); // Join persona's socket room
    _isMessagesLoading = true;
    _messages = [];
    notifyListeners();

    try {
      final request = Request(
        url: '/messages',
        method: HTTPMethod.GET,
        body: {
          'sender_id': _currentUserId!,
          'receiver_id': receiverId,
        },
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        _messages = (response.data as List)
            .map((json) => Message.fromJson(json, _currentUserId!))
            .toList();
      }
    } catch (e) {
      print("Error fetching messages: $e");
    } finally {
      _isMessagesLoading = false;
      notifyListeners();
    }
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
        
        // Connect Socket
        _socketManager.connect(_currentUserId!);
        
        // Fetch data
        await fetchChattedPersonas();
        await fetchChallenges();
        await fetchAllPersonas();
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



  void logout() {
    _currentUserId = null;
    _socketManager.disconnect();
    _chats = [];
    _challenges = [];
    _messages = [];
    _network.clearToken();
    _googleSignIn.disconnect().catchError((error) {
      print("Error disconnecting Google Sign In: $error");
    });
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
    _messages = [];
    notifyListeners();

    try {
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

        // Parse conversation history from setup challenge directly
        if (data['conversation_history'] is List) {
          _messages = (data['conversation_history'] as List)
              .map((json) => Message.fromJson(Map<String, dynamic>.from(json as Map), _currentUserId!))
              .toList();
        } else {
          _messages = [];
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

  @override
  void dispose() {
    _socketManager.disconnect();
    super.dispose();
  }
}

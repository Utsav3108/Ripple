import 'package:flutter/material.dart';
import '../Network/network_manager.dart';
import '../Network/socket_manager.dart';
import '../Model/model.dart';

class ChatProvider with ChangeNotifier {
  final Network _network = Network();
  final SocketManager _socketManager = SocketManager();
  
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

  // For demo purposes, we'll use a hardcoded user_id
  final int currentUserId = 1;

  ChatProvider() {
    _initSocket();
  }

  void _initSocket() {
    _socketManager.connect(currentUserId);
    _socketManager.onMessageReceived = (data) {
      final newMessage = Message.fromJson(data, currentUserId);
      // Check if message already exists (to avoid duplicates if server broadcasts back to sender)
      if (!_messages.any((m) => m.id == newMessage.id && m.id != 0)) {
        _messages.add(newMessage);
        notifyListeners();
      }
    };
  }

  Future<void> fetchChattedPersonas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/personas/$currentUserId',
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
    _isMessagesLoading = true;
    _messages = [];
    notifyListeners();

    try {
      final request = Request(
        url: '/messages',
        method: HTTPMethod.GET,
        body: {
          'sender_id': currentUserId,
          'receiver_id': receiverId,
        },
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        _messages = (response.data as List)
            .map((json) => Message.fromJson(json, currentUserId))
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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/setup_challenge',
        method: HTTPMethod.POST,
        body: {
          'challenge_id': challengeId,
          'persona_id': personaId,
          'user_id': currentUserId,
        },
      );

      final response = await _network.performRequest(request);

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        _currentChallengeSessionId = data['challenge_session_id'];
        _currentChallengeIntro = data['intro'] is Map ? Map<String, dynamic>.from(data['intro']) : null;
        _currentChallengeStatus = data['status'];
        _currentChallengeDuration = data['total_duration_minutes'];

        if (_currentChallengeSessionId != null) {
          // Socket order: Setup API, Emit Join, Emit Join Challenge
          _socketManager.emitJoin(currentUserId);
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
    notifyListeners();
  }

  void sendMessage(int receiverId, String text) {
    if (text.trim().isEmpty) return;

    // Optimistically add to list
    final tempMessage = Message(
      id: 0, // Temporary ID
      senderId: currentUserId,
      receiverId: receiverId,
      text: text,
      timestamp: DateTime.now(),
      isUser: true,
    );
    
    _messages.add(tempMessage);
    notifyListeners();

    // Send via socket
    _socketManager.sendMessage(
      currentUserId,
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

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
  
  bool _isLoading = false;
  bool _isMessagesLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  List<Persona> get chats => _chats;
  List<Message> get messages => _messages;
  List<Persona> get searchResults => _searchResults;
  
  bool get isLoading => _isLoading;
  bool get isMessagesLoading => _isMessagesLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  // For demo purposes, we'll use a hardcoded user_id
  final int currentUserId = -1;

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

  Future<void> fetchChattedPresidents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = Request(
        url: '/presidents/$currentUserId',
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

  Future<void> searchPresidents(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final request = Request(
        url: '/search-presidents/$query',
        method: HTTPMethod.GET,
      );

      final response = await _network.performRequest(request);

      if (response.data is List) {
        _searchResults = (response.data as List)
            .map((json) => Persona.fromJson(json))
            .toList();
      }
    } catch (e) {
      print("Error searching presidents: $e");
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
    _socketManager.sendMessage(currentUserId, receiverId, text);
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

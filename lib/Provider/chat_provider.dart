import 'package:flutter/material.dart';
import '../Network/network_manager.dart';
import '../Model/model.dart';

class ChatProvider with ChangeNotifier {
  final Network _network = Network();
  List<Persona> _chats = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Persona> get chats => _chats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // For demo purposes, we'll use a hardcoded user_id
  final int currentUserId = 1;

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
      print("Error fetching chats: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchChats(String query) {
    // This could be local filtering or another API call
    // For now, let's keep it simple. The UI will handle local filtering of the current list.
  }
}

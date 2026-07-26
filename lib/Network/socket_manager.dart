import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'network_manager.dart';

class SocketManager {
  late IO.Socket socket;
  final String _baseUrl = Network.getBaseURL();
  
  // Callback when a message is received
  Function(Map<String, dynamic>)? onMessageReceived;

  // Callback when a challenge is completed from server
  Function(Map<String, dynamic>)? onChallengeCompleted;

  // Callback when a persona is blocked
  Function(Map<String, dynamic>)? onPersonaBlocked;

  // Callback when a persona is unblocked
  Function(Map<String, dynamic>)? onPersonaUnblocked;

  void connect(int userId) {
    socket = IO.io(_baseUrl, IO.OptionBuilder()
      .setTransports(['websocket']) // for Flutter or Dart VM
      .disableAutoConnect()  // disable auto-connection
      .build());

    socket.connect();

    socket.onConnect((_) {
      print('Connected to socket server');
      // Join after connecting
      socket.emit('join', {'user_id': userId});
    });

    socket.on('receive_message', (data) {
      print('Received message: $data');
      if (onMessageReceived != null) {
        try {
          Map<String, dynamic> messageData;
          if (data is String) {
            messageData = jsonDecode(data);
          } else if (data is Map) {
            messageData = Map<String, dynamic>.from(data);
          } else {
            print('Unexpected message data type: ${data.runtimeType}');
            return;
          }
          onMessageReceived!(messageData);
        } catch (e) {
          print('Error parsing received message: $e');
        }
      }
    });

    socket.on('challenge_completed', (data) {
      print('Received challenge_completed event: $data');
      if (onChallengeCompleted != null) {
        try {
          Map<String, dynamic> completedData;
          if (data is String) {
            completedData = jsonDecode(data);
          } else if (data is Map) {
            completedData = Map<String, dynamic>.from(data);
          } else {
            print('Unexpected challenge_completed data type: ${data.runtimeType}');
            return;
          }
          onChallengeCompleted!(completedData);
        } catch (e) {
          print('Error parsing challenge_completed event: $e');
        }
      }
    });

    socket.on('persona_blocked', (data) {
      print('Received persona_blocked: $data');
      if (onPersonaBlocked != null) {
        try {
          Map<String, dynamic> blockedData;
          if (data is String) {
            blockedData = jsonDecode(data);
          } else if (data is Map) {
            blockedData = Map<String, dynamic>.from(data);
          } else {
            print('Unexpected persona_blocked data type: ${data.runtimeType}');
            return;
          }
          onPersonaBlocked!(blockedData);
        } catch (e) {
          print('Error parsing persona_blocked event: $e');
        }
      }
    });

    socket.on('persona_unblocked', (data) {
      print('Received persona_unblocked: $data');
      if (onPersonaUnblocked != null) {
        try {
          Map<String, dynamic> unblockedData;
          if (data is String) {
            unblockedData = jsonDecode(data);
          } else if (data is Map) {
            unblockedData = Map<String, dynamic>.from(data);
          } else {
            print('Unexpected persona_unblocked data type: ${data.runtimeType}');
            return;
          }
          onPersonaUnblocked!(unblockedData);
        } catch (e) {
          print('Error parsing persona_unblocked event: $e');
        }
      }
    });

    socket.onDisconnect((_) => print('Disconnected from socket server'));
    socket.onConnectError((err) => print('Connect Error: $err'));
  }

  void emitCheckUnblockStatus(int userId, int personaId) {
    socket.emit('check_unblock_status', {
      'user_id': userId,
      'persona_id': personaId,
    });
  }

  void emitJoin(int userId) {
    socket.emit('join', {'user_id': userId});
  }

  void emitJoinChallenge(int challengeSessionId) {
    socket.emit('join_challenge', {'challenge_session_id': challengeSessionId});
  }

  void sendMessage(int senderId, int receiverId, String text, {int? challengeSessionId}) {
    final payload = {
      "sender_id": senderId,
      "receiver_id": receiverId,
      "text": text,
      if (challengeSessionId != null) "challenge_session_id": challengeSessionId,
    };
    socket.emit('send_message', payload);
  }

  void emitCompleteChallenge(int challengeSessionId, String status, {String? reason}) {
    final payload = {
      "challenge_session_id": challengeSessionId,
      "status": status,
      if (reason != null) "reason": reason,
    };
    socket.emit('complete_challenge', payload);
  }

  void emitLeaveChat(int userId, {int? personaId, int? challengeSessionId}) {
    print("DEBUG: SocketManager.emitLeaveChat emitting leave_chat event for user $userId, persona $personaId, session $challengeSessionId");
    socket.emit('leave_chat', {
      'user_id': userId,
      if (personaId != null) 'persona_id': personaId,
      if (challengeSessionId != null) 'challenge_session_id': challengeSessionId,
    });
  }

  void disconnect() {
    socket.disconnect();
  }
}

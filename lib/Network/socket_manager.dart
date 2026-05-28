import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'network_manager.dart';

class SocketManager {
  late IO.Socket socket;
  final String _baseUrl = Network.getBaseURL();
  
  // Callback when a message is received
  Function(Map<String, dynamic>)? onMessageReceived;

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

    socket.onDisconnect((_) => print('Disconnected from socket server'));
    socket.onConnectError((err) => print('Connect Error: $err'));
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

  void disconnect() {
    socket.disconnect();
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:ripple/Network/socket_manager.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MockSocket implements IO.Socket {
  final List<MapEntry<String, dynamic>> emits = [];

  @override
  void emit(String event, [dynamic data]) {
    emits.add(MapEntry(event, data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('SocketManager payload shape tests', () {
    late SocketManager socketManager;
    late MockSocket mockSocket;

    setUp(() {
      socketManager = SocketManager();
      mockSocket = MockSocket();
      socketManager.socket = mockSocket;
    });

    test('sendMessage includes correct persona_session_id', () {
      socketManager.sendMessage(
        123,
        45,
        "hello",
        personaSessionId: 5190,
      );

      expect(mockSocket.emits.length, 1);
      final emit = mockSocket.emits[0];
      expect(emit.key, 'send_message');
      
      final payload = emit.value as Map<String, dynamic>;
      expect(payload['sender_id'], 123);
      expect(payload['receiver_id'], 45);
      expect(payload['text'], "hello");
      expect(payload['persona_session_id'], 5190);
      expect(payload.containsKey('challenge_session_id'), isFalse);
    });

    test('sendMessage omits persona_session_id when null', () {
      socketManager.sendMessage(
        123,
        45,
        "hello",
      );

      expect(mockSocket.emits.length, 1);
      final emit = mockSocket.emits[0];
      expect(emit.key, 'send_message');
      
      final payload = emit.value as Map<String, dynamic>;
      expect(payload['sender_id'], 123);
      expect(payload['receiver_id'], 45);
      expect(payload['text'], "hello");
      expect(payload.containsKey('persona_session_id'), isFalse);
    });

    test('emitLeaveChat includes correct persona_session_id', () {
      socketManager.emitLeaveChat(
        123,
        personaId: 45,
        personaSessionId: 5190,
      );

      expect(mockSocket.emits.length, 1);
      final emit = mockSocket.emits[0];
      expect(emit.key, 'leave_chat');

      final payload = emit.value as Map<String, dynamic>;
      expect(payload['user_id'], 123);
      expect(payload['persona_id'], 45);
      expect(payload['persona_session_id'], 5190);
    });

    test('emitLeaveChat omits persona_session_id when null', () {
      socketManager.emitLeaveChat(
        123,
        personaId: 45,
      );

      expect(mockSocket.emits.length, 1);
      final emit = mockSocket.emits[0];
      expect(emit.key, 'leave_chat');

      final payload = emit.value as Map<String, dynamic>;
      expect(payload['user_id'], 123);
      expect(payload['persona_id'], 45);
      expect(payload.containsKey('persona_session_id'), isFalse);
    });

    test('emitCheckUnblockStatus includes correct persona_session_id', () {
      socketManager.emitCheckUnblockStatus(
        123,
        45,
        personaSessionId: 5190,
      );

      expect(mockSocket.emits.length, 1);
      final emit = mockSocket.emits[0];
      expect(emit.key, 'check_unblock_status');

      final payload = emit.value as Map<String, dynamic>;
      expect(payload['user_id'], 123);
      expect(payload['persona_id'], 45);
      expect(payload['persona_session_id'], 5190);
    });

    test('emitCheckUnblockStatus omits persona_session_id when null', () {
      socketManager.emitCheckUnblockStatus(
        123,
        45,
      );

      expect(mockSocket.emits.length, 1);
      final emit = mockSocket.emits[0];
      expect(emit.key, 'check_unblock_status');

      final payload = emit.value as Map<String, dynamic>;
      expect(payload['user_id'], 123);
      expect(payload['persona_id'], 45);
      expect(payload.containsKey('persona_session_id'), isFalse);
    });
  });
}

import 'dart:collection';
import 'dart:io';

import 'package:netframework/src/message.dart';

import 'connection.dart';

abstract class Client {
  Connection? _connection;
  final Queue<OwnedMessage> _messagesQueueIn;

  Client() : _messagesQueueIn = Queue<OwnedMessage>();

  Queue<OwnedMessage> get incoming => _messagesQueueIn;
  Connection? get connection => _connection;

  Future<void> connect(String ip, int port) async {
    final socket = await Socket.connect(ip, port);
    _connection = Connection(
      owner: ConnectionOwner.client,
      socket: socket,
      messagesQueueIn: _messagesQueueIn,
    );
  }

  Future<void> disconnect() async {
    await _connection?.close();
  }

  void send(Message message) {
    assert(_connection != null, "Connect first before sending messages");
    message.pack();
    _connection!.send(message);
  }
}

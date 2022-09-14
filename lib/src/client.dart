import 'dart:collection';
import 'dart:io';

import 'package:netframework/src/message.dart';

import 'connection.dart';

abstract class Client<T extends Enum> {
  Connection<T>? _connection;
  final Queue<OwnedMessage<T>> _messagesQueueIn;

  Client() : _messagesQueueIn = Queue<OwnedMessage<T>>();

  Queue<OwnedMessage<T>> get incoming => _messagesQueueIn;
  Connection<T>? get connection => _connection;

  /// Connect to the server with an [ip] and a [port].
  Future<bool> connect(String ip, int port) async {
    final socket = await Socket.connect(ip, port);
    _connection = Connection<T>(
      owner: ConnectionOwner.client,
      socket: socket,
      messagesQueueIn: _messagesQueueIn,
      onDoneCallback: onDone,
      onErrorCallback: onError,
    );

    bool handshakeOk = await _connection!.handshake();
    if (!handshakeOk) return false;
    _connection!.startListening();

    onConnected();
    return true;
  }

  /// Called when the connection is established.
  void onConnected() {
    print("[CLIENT]connected");
  }

  /// Called when the connection is closed.
  void onDone(Connection connection) {
    print("[CLIENT]done");
  }

  /// Called when the connection is closed.
  void onError(Connection connection, Object error) {
    print("[CLIENT]error: $error");
  }

  /// called when a message is received.
  ///
  /// To get access to the message, use [incoming].
  void onEvent(Connection connection) {}

  /// Disconnect from the server.
  Future<void> disconnect() async {
    await _connection?.close();
  }

  /// Send a [message] to the server.
  void send(Message<T> message) {
    assert(_connection != null, "Connect first before sending messages");
    message.pack();
    _connection!.send(message);
  }
}

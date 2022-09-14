import 'dart:collection';
import 'dart:io';

import 'package:netframework/src/message.dart';
import 'package:netframework/src/utils/log.dart';

import 'connection.dart';

abstract class Client {
  Connection? _connection;
  final Queue<OwnedMessage> _messagesQueueIn;
  final Printer? _printer;

  Client({Printer? printer})
      : _printer = printer,
        _messagesQueueIn = Queue<OwnedMessage>();

  Queue<OwnedMessage> get incoming => _messagesQueueIn;
  Connection? get connection => _connection;

  /// Connect to the server with an [ip] and a [port].
  Future<bool> connect(String ip, int port) async {
    final socket = await Socket.connect(ip, port);
    _connection = Connection(
      owner: ConnectionOwner.client,
      socket: socket,
      messagesQueueIn: _messagesQueueIn,
      onDoneCallback: onDone,
      onErrorCallback: onError,
      printer: _printer,
    );

    bool handshakeOk = await _connection!.handshake();
    if (!handshakeOk) return false;
    _connection!.startListening();

    _printer?.call(
      LogLevel.info,
      LogActor.client,
      'Connected to the server',
    );
    onConnected();
    return true;
  }

  /// Called when the connection is established.
  void onConnected() {}

  /// Called when the connection is closed.
  void onDone(Connection connection) {}

  /// Called when the connection is closed.
  void onError(Connection connection, Object error) {}

  /// called when a message is received.
  ///
  /// To get access to the message, use [incoming].
  void onEvent(Connection connection) {}

  /// Disconnect from the server.
  Future<void> disconnect() async {
    await _connection?.close();
  }

  /// Send a [message] to the server.
  void send(Message message) {
    assert(_connection != null, "Connect first before sending messages");
    message.pack();
    _connection!.send(message);
  }
}

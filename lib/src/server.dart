import 'dart:collection';
import 'dart:io';

import 'connection.dart';
import 'message.dart';

const int intMax = 9223372036854775807;

abstract class Server {
  final Queue<OwnedMessage> _messagesQueueIn = Queue();
  final List<Connection> _connections = [];
  final int port;

  ServerSocket? _serverSocket;

  Server(this.port);

  Future<void> start() async {
    _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    _serverSocket!
        .listen(_handleConnection, onDone: _onDone, onError: _onError);
  }

  Future<void> stop() async {
    _serverSocket?.close();
  }

  void update({int messageNumber = intMax}) {
    while (_messagesQueueIn.isNotEmpty) {
      final OwnedMessage message = _messagesQueueIn.removeFirst();
      onMessage(message.connection, message.message);
    }
  }

  void _onDone() {
    _serverSocket?.close();
  }

  void _onError(Object error) {
    _serverSocket?.close();
  }

  void _handleConnection(Socket socket) {
    //Create a connection
    final connection = Connection(
      owner: ConnectionOwner.server,
      socket: socket,
      messagesQueueIn: _messagesQueueIn,
    );

    // Give a chance to deny the connection
    if (!onClientConnected(connection)) {
      print("Connection denied.");
      return;
    }

    //Add the connection to the list of connections
    _connections.add(connection);

    print("Connection accepted.");
  }

  /// Called when a message is received from a connection.
  void onMessage(Connection connection, Message message) {
    print("Message received.");
  }

  /// Called when a client connects to the server.
  ///
  /// Return false to deny the connection.
  bool onClientConnected(Connection connection) {
    print("Client connected.");
    return true;
  }
}

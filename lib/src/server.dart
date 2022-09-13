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
    for (var conn in _connections) {
      conn.close();
    }
    _connections.clear();
    await _serverSocket?.close();
    onServerSttopped();
  }

  void update({int numberOfMessageToRead = intMax}) {
    while (_messagesQueueIn.isNotEmpty && (numberOfMessageToRead--) != 0) {
      final OwnedMessage message = _messagesQueueIn.removeFirst();
      onMessage(message.connection, message.message);
    }
  }

  void sendToClient(Connection connection, Message message) {
    if (connection.isOpen) {
      connection.send(message);
    }
  }

  void sendToAllClients(Message message) {
    for (final connection in _connections) {
      if (connection.isOpen) {
        connection.send(message);
      }
    }
  }

  void _onDone() {
    _serverSocket?.close();
  }

  void _onError(Object error) {
    _serverSocket?.close();
  }

  /// Called when a new connection is established.
  void _handleConnection(Socket socket) {
    // This function remove the connection from the list of connections when it is closed.
    void cleanConnection(Connection connection) {
      onClientDisconnected(connection);
      _connections.remove(connection);
    }

    //Create a connection
    final connection = Connection(
      owner: ConnectionOwner.server,
      socket: socket,
      messagesQueueIn: _messagesQueueIn,
      onDoneCallback: (Connection connection) {
        cleanConnection(connection);
      },
      onErrorCallback: (Connection connection, Object error) {
        cleanConnection(connection);
      },
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

  void onServerSttopped() {
    print("Server stopped.");
  }

  /// Called when a client connects to the server.
  ///
  /// Return false to deny the connection.
  bool onClientConnected(Connection connection) {
    print("Client ${connection.id} connected.");
    return true;
  }

  void onClientDisconnected(Connection connection) {
    print("Client ${connection.id} disconnected.");
  }
}

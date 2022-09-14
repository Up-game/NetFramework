import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'connection.dart';
import 'message.dart';

const int intMax = 9223372036854775807;

abstract class Server<T extends Enum> {
  final Queue<OwnedMessage<T>> _messagesQueueIn = Queue();
  final List<Connection> _connections = [];
  final int port;
  // This StreamController is used to block the update loop.
  final StreamController<void> _incomingStreamController =
      StreamController.broadcast();

  ServerSocket? _serverSocket;

  Server(this.port);

  Queue<OwnedMessage<T>> get incoming => _messagesQueueIn;

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
    onServerStopped();
  }

  /// Call this to process new messages
  ///
  /// If [blocking] is true, this will block until one message is received.
  ///
  /// **Important** If [blocking] is true you must await this function.
  Future<void> update(
      {int numberOfMessageToRead = intMax, blocking = false}) async {
    if (blocking) {
      // wait for new messages
      await _incomingStreamController.stream.first;
    }

    while (_messagesQueueIn.isNotEmpty && (numberOfMessageToRead--) != 0) {
      print(_messagesQueueIn.length);
      final OwnedMessage<T> message = _messagesQueueIn.removeFirst();
      onMessage(message.connection, message.message);
    }
  }

  /// Send a [message] to a [connection].
  void sendToClient(Connection connection, Message<T> message) {
    if (connection.isOpen) {
      connection.send(message);
    }
  }

  /// Send a [message] to all connected clients.
  void sendToAllClients(Message<T> message) {
    for (final connection in _connections) {
      if (connection.isOpen) {
        connection.send(message);
      }
    }
  }

  /// Called when the serverSocket is done.
  void _onDone() {
    _serverSocket?.close();
  }

  /// Called when the serverSocket has an error.
  void _onError(Object error) {
    _serverSocket?.close();
  }

  /// Called when a new connection is established.
  void _handleConnection(Socket socket) async {
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
      streamController: _incomingStreamController,
    );

    // Give a chance to deny the connection
    if (!onClientConnected(connection)) return;

    bool handshakeOk = await connection.handshake();
    if (!handshakeOk) return;
    //Add the connection to the list of connections
    _connections.add(connection);
    connection.startListening();

    print("[SERVER]Connection accepted.");
  }

  /// Called when a message is received from a connection.
  void onMessage(Connection connection, Message<T> message) {
    print("[SERVER]Message received.");
  }

  void onServerStopped() {
    print("[SERVER]Server stopped.");
  }

  /// Called when a client connects to the server.
  ///
  /// Return false to deny the connection.
  bool onClientConnected(Connection connection) {
    print("[SERVER]Client ${connection.id} connected.");
    return true;
  }

  void onClientDisconnected(Connection connection) {
    print("[SERVER]Client ${connection.id} disconnected.");
  }
}

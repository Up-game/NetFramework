import 'dart:collection';
import 'dart:io';

import 'connection.dart';
import 'message.dart';

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

  void _onDone() {}

  void _onError(Object error) {}

  void _handleConnection(Socket socket) {
    //Create a connection
    final connection =
        Connection(socket: socket, messagesQueueIn: _messagesQueueIn);

    // Give a chance to deny the connection
    if (!onClientConnected(connection)) {
      print("Connection denied.");
      return;
    }

    //Add the connection to the list of connections
    _connections.add(connection);

    print("Connection accepted.");
  }

  bool onClientConnected(Connection connection) {
    return true;
  }
}

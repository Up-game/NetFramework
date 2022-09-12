import 'dart:io';

class Connection {
  final Socket _socket;
  Connection({required Socket socket}) : _socket = socket;
}

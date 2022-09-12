import 'dart:io';

import 'package:netframework/src/message.dart';

abstract class Client {
  Socket? _socket;

  Client();

  Future<void> connect(String ip, int port) async {
    _socket = await Socket.connect(ip, port);
  }

  void send(Message message) {
    message.pack();
    _socket?.add(message.data!);
  }
}

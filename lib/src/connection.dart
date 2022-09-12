import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'message.dart';

class Connection {
  final Socket _socket;
  bool _isOpen = true;
  final Queue<Message> _messagesQueueIn;

  bool get isOpen => _isOpen;

  Connection({required Socket socket, required Queue<Message> messagesQueueIn})
      : _socket = socket,
        _messagesQueueIn = messagesQueueIn {
    socket.listen(onEvent, onDone: onDone, onError: onError);
  }

  void onEvent(Uint8List data) {}

  void onDone() {
    _isOpen = false;
  }

  void onError() {
    _isOpen = false;
  }
}

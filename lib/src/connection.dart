import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'message.dart';

class Connection {
  final Socket _socket;
  bool _isOpen = true;
  final Queue<OwnedMessage> _messagesQueueIn;

  bool get isOpen => _isOpen;

  Connection(
      {required Socket socket, required Queue<OwnedMessage> messagesQueueIn})
      : _socket = socket,
        _messagesQueueIn = messagesQueueIn {
    socket.listen(onEvent, onDone: onDone, onError: onError);
  }

  void onEvent(Uint8List data) {
    final message = Message.fromBytes(data);

    final ownedMessage = OwnedMessage(connection: this, message: message);
    _messagesQueueIn.add(ownedMessage);
  }

  void onDone() {
    _isOpen = false;
  }

  void onError() {
    _isOpen = false;
  }
}

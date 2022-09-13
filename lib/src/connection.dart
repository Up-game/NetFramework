import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'message.dart';

enum ConnectionOwner { server, client }

class Connection {
  static int idCounter = 0;
  final int id;
  final ConnectionOwner owner;
  final Socket _socket;
  final Queue<OwnedMessage> _messagesQueueIn;
  final void Function(Connection)? _onDoneCallback;
  final void Function(Connection, Object)? _onErrorCallback;
  bool _isOpen = true;

  bool get isOpen => _isOpen;

  Connection({
    required this.owner,
    required Socket socket,
    required Queue<OwnedMessage> messagesQueueIn,
    void Function(Connection)? onDoneCallback,
    void Function(Connection, Object)? onErrorCallback,
  })  : id = idCounter++,
        _onDoneCallback = onDoneCallback,
        _onErrorCallback = onErrorCallback,
        _socket = socket,
        _messagesQueueIn = messagesQueueIn {
    socket.listen(_onEvent, onDone: _onDone, onError: _onError);
  }

  void _onEvent(Uint8List data) {
    print("Event received: ${data.length} bytes");
    final message = Message.fromBytes(data);

    final ownedMessage = OwnedMessage(connection: this, message: message);
    _messagesQueueIn.add(ownedMessage);
  }

  void _onDone() {
    if (_onDoneCallback != null) {
      _onDoneCallback!(this);
    }
    _isOpen = false;
    _socket.close();
  }

  void _onError(Object error) {
    if (_onErrorCallback != null) {
      _onErrorCallback!(this, error);
    }
    _isOpen = false;
    _socket.close();
  }

  void send(Message message) {
    message.pack();
    _socket.add(message.data!);
  }

  Future<void> close() async {
    _isOpen = false;
    await _socket.flush();
    await _socket.close();
  }

  @override
  String toString() {
    return 'Connection{owner: $owner, messagesQueueInSize: ${_messagesQueueIn.length}}';
  }
}

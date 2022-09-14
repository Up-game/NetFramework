import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'message.dart';

enum ConnectionOwner {
  server,
  client;

  @override
  String toString() {
    switch (this) {
      case ConnectionOwner.server:
        return "SERVER";
      case ConnectionOwner.client:
        return "CLIENT";
    }
  }
}

class Connection<T extends Enum> {
  static int idCounter = 0;
  final int id;
  final ConnectionOwner owner;
  final Socket _socket;
  final Queue<OwnedMessage<T>> _messagesQueueIn;
  final void Function(Connection)? _onDoneCallback;
  final void Function(Connection)? _onEventCallback;
  final void Function(Connection, Object)? _onErrorCallback;
  final StreamController<void>? _incomingStreamController;
  bool _isOpen = true;

  /// This is used to be able to subscribe multiple times to the same stream.
  late Stream<Uint8List> _multiSubSocket;

  bool get isOpen => _isOpen;

  Connection({
    required this.owner,
    required Socket socket,
    required Queue<OwnedMessage<T>> messagesQueueIn,
    void Function(Connection)? onDoneCallback,
    void Function(Connection)? onEventCallback,
    void Function(Connection, Object)? onErrorCallback,
    StreamController<void>? streamController,
  })  : id = idCounter++,
        _onDoneCallback = onDoneCallback,
        _onErrorCallback = onErrorCallback,
        _onEventCallback = onEventCallback,
        _socket = socket,
        _incomingStreamController = streamController,
        _messagesQueueIn = messagesQueueIn {
    _multiSubSocket = _socket.asBroadcastStream();
  }

  Future<bool> handshake() async {
    var secret = utf8.encode('secret');
    var hmacSha256 = Hmac(sha256, secret);

    if (owner == ConnectionOwner.server) {
      final String randomString = "RandomString";
      _socket.write(randomString);
      var bytes = utf8.encode(randomString);
      var digest = hmacSha256.convert(bytes);

      final data = await _multiSubSocket.first;
      if (digest.toString() == String.fromCharCodes(data)) {
        print('[$owner]Handshake success');
        return true;
      } else {
        print('[$owner]Handshake failed');
        _isOpen = false;
        _socket.close();
        return false;
      }
    } else {
      final data = await _multiSubSocket.first;
      final String randomString = String.fromCharCodes(data);
      var bytes = utf8.encode(randomString);
      var digest = hmacSha256.convert(bytes);

      _socket.write(digest.toString());
      return true;
    }
  }

  void startListening() {
    assert(_isOpen == true);
    _multiSubSocket.listen(_onEvent, onDone: _onDone, onError: _onError);
  }

  void _onEvent(Uint8List data) {
    print("[$owner]received event: ${data.length} bytes");
    final message = Message<T>.fromBytes(data);

    final ownedMessage = OwnedMessage<T>(connection: this, message: message);
    _messagesQueueIn.add(ownedMessage);
    _incomingStreamController?.sink.add(null);
    if (_onEventCallback != null) {
      _onEventCallback!(this);
    }
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

  void send(Message<T> message) {
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

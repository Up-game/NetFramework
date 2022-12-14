import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:netframework/src/utils/log.dart';
import 'message.dart';
import 'utils/utils.dart';

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

class Connection {
  static int idCounter = 0;
  final int id;
  final ConnectionOwner owner;
  final Socket _socket;
  final Queue<OwnedMessage> _messagesQueueIn;
  final void Function(Connection)? _onDoneCallback;
  final void Function(Connection)? _onEventCallback;
  final void Function(Connection, Object)? _onErrorCallback;
  final StreamController<void>? _incomingStreamController;
  bool _isOpen = true;
  final Printer? _printer;

  /// This is used to be able to subscribe multiple times to the same stream.
  late Stream<Uint8List> _multiSubSocket;

  bool get isOpen => _isOpen;
  Socket get socket => _socket;

  Connection({
    required this.owner,
    required Socket socket,
    required Queue<OwnedMessage> messagesQueueIn,
    void Function(Connection)? onDoneCallback,
    void Function(Connection)? onEventCallback,
    void Function(Connection, Object)? onErrorCallback,
    StreamController<void>? streamController,
    Printer? printer,
  })  : id = idCounter++,
        _printer = printer,
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
      final String randomString = generateRandomString(20);
      _socket.write(randomString);
      var bytes = utf8.encode(randomString);
      var digest = hmacSha256.convert(bytes);
      late final Uint8List data;
      try {
        data = await _multiSubSocket.first;
      } catch (e) {
        _printer?.call(LogLevel.error, LogActor.server, 'Handshake failed');
        _isOpen = false;
        _socket.close();
        return false;
      }

      if (digest.toString() == String.fromCharCodes(data)) {
        _printer?.call(LogLevel.info, LogActor.server, 'Handshake success');
        return true;
      } else {
        _printer?.call(LogLevel.error, LogActor.server, 'Handshake failed');
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
    _printer?.call(
      LogLevel.info,
      owner == ConnectionOwner.server ? LogActor.server : LogActor.server,
      'Start listening',
    );
    _multiSubSocket.listen(_onEvent, onDone: _onDone, onError: _onError);
  }

  void _onEvent(Uint8List data) {
    _printer?.call(
      LogLevel.info,
      owner == ConnectionOwner.server ? LogActor.server : LogActor.client,
      'Received event: ${data.length} bytes',
    );
    final message = Message.fromBytes(data);

    final ownedMessage = OwnedMessage(connection: this, message: message);
    _messagesQueueIn.add(ownedMessage);

    // this will be called only by the server.
    // It will notify the update method that there is a new message.
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
    _printer?.call(
      LogLevel.info,
      owner == ConnectionOwner.server ? LogActor.server : LogActor.client,
      'Connection closed',
    );
  }

  void _onError(Object error) {
    if (_onErrorCallback != null) {
      _onErrorCallback!(this, error);
    }
    _isOpen = false;
    _socket.close();
    _printer?.call(
      LogLevel.error,
      owner == ConnectionOwner.server ? LogActor.server : LogActor.client,
      'Error: $error',
    );
  }

  void send(Message message) {
    message.pack();
    _socket.add(message.data!);
  }

  Future<void> close() async {
    _isOpen = false;
    await _socket.flush();
    await _socket.close();
    _printer?.call(
      LogLevel.error,
      owner == ConnectionOwner.server ? LogActor.server : LogActor.client,
      'Closing connection $id',
    );
  }

  @override
  String toString() {
    return 'Connection{owner: $owner, messagesQueueInSize: ${_messagesQueueIn.length}}';
  }
}

import 'dart:typed_data';
import 'package:messagepack/messagepack.dart';
import 'package:netframework/src/connection.dart';

class MessageHeader {
  int id;

  MessageHeader({required this.id});
}

class Message {
  late final MessageHeader header;
  final _packer = Packer();
  final Unpacker? _unpacker;
  Uint8List? _data;

  Message({required this.header, Unpacker? unpacker}) : _unpacker = unpacker;

  /// Creates a new Message from a [Uint8List].
  factory Message.fromBytes(Uint8List data) {
    final Unpacker unpacker = Unpacker(data);

    final id = unpacker.unpackInt();

    MessageHeader header = MessageHeader(id: id ?? -1);

    return Message(header: header, unpacker: unpacker);
  }

  /// Get the data as a [Uint8List].
  ///
  /// It will return null if the data is not yet packed.
  Uint8List? get data => _data;

  /// Get the data size, header included.
  int get size => _data?.length ?? 0;

  /// It adds the header to the message.
  ///
  /// It should be called before adding any data.
  void addHeader() {
    _packer.packInt(header.id);
  }

  /// Add an [int] to the message.
  void addInt(int value) {
    _packer.packInt(value);
  }

  /// Add a [String] to the message.
  void addString(String value) {
    _packer.packString(value);
  }

  /// Add a [bool] to the message.
  void addBool(bool value) {
    _packer.packBool(value);
  }

  /// Add a [double] to the message.
  void addDouble(double value) {
    _packer.packDouble(value);
  }

  /// get an [int] from the message.
  int? getInt() {
    assert(_unpacker != null);
    return _unpacker!.unpackInt();
  }

  /// get a [Double] from the message.
  double? getDouble() {
    assert(_unpacker != null);
    return _unpacker!.unpackDouble();
  }

  /// get a [String] from the message.
  String? getString() {
    assert(_unpacker != null);
    return _unpacker!.unpackString();
  }

  /// get a [bool] from the message.
  bool? getBool() {
    assert(_unpacker != null);
    return _unpacker!.unpackBool();
  }

  /// Pack the message.
  void pack() {
    if (_data != null) return;
    _data = _packer.takeBytes();
  }

  @override
  String toString() {
    return 'Message{id: ${header.id}}';
  }
}

class OwnedMessage {
  final Connection connection;
  final Message message;

  OwnedMessage({required this.connection, required this.message});
}

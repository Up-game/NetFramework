import 'dart:typed_data';
import 'package:messagepack/messagepack.dart';
import 'package:netframework/src/connection.dart';

class MessageHeader {
  String id;
  int size;

  MessageHeader({this.id = '', this.size = 0});
}

class Message {
  late final MessageHeader header;
  final _packer = Packer();
  final Unpacker? _unpacker;
  Uint8List? _data;

  Message({MessageHeader? header, Unpacker? unpacker})
      : _unpacker = unpacker,
        header = header ?? MessageHeader();

  factory Message.fromBytes(Uint8List data) {
    final Unpacker unpacker = Unpacker(data);

    final id = unpacker.unpackString();
    final size = unpacker.unpackInt()!;

    MessageHeader header = MessageHeader(id: id!, size: size);

    return Message(header: header, unpacker: unpacker);
  }

  Uint8List? get data => _data;
  int get size => _data?.length ?? 0;

  void addHeader() {
    _packer.packString(header.id.toString());
    _packer.packInt(header.size);
  }

  void addInt(int value) {
    _packer.packInt(value);
  }

  void addString(String value) {
    _packer.packString(value);
  }

  void addBool(bool value) {
    _packer.packBool(value);
  }

  void addDouble(double value) {
    _packer.packDouble(value);
  }

  int? getInt() {
    assert(_unpacker != null);
    return _unpacker!.unpackInt();
  }

  double? getDouble() {
    assert(_unpacker != null);
    return _unpacker!.unpackDouble();
  }

  String? getString() {
    assert(_unpacker != null);
    return _unpacker!.unpackString();
  }

  bool? getBool() {
    assert(_unpacker != null);
    return _unpacker!.unpackBool();
  }

  void pack() {
    if (_data != null) return;
    _data = _packer.takeBytes();
    header.size = _data!.length;
  }

  @override
  String toString() {
    return 'Message{id: ${header.id}, size: ${header.size}}';
  }
}

class OwnedMessage {
  final Connection connection;
  final Message message;

  OwnedMessage({required this.connection, required this.message});
}

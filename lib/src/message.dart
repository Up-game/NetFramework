import 'dart:typed_data';
import 'package:messagepack/messagepack.dart';
import 'package:netframework/src/connection.dart';

class MessageHeader<T> {
  T? id;
  int size;

  MessageHeader({this.id, this.size = 0});
}

class Message<T extends Enum> {
  final MessageHeader<T> header = MessageHeader<T>();
  final _packer = Packer();
  final Unpacker? _unpacker;
  Uint8List? _data;

  Message({Uint8List? data, T? id})
      : _data = data,
        _unpacker = data != null ? Unpacker(data) : null {
    header.id = id;
    if (data != null) {
      header.size = data.length;
    }
  }

  Uint8List? get data => _data;
  int get size => _data?.length ?? 0;

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
    return 'Message<${T.toString()}> {id: ${header.id}, size: ${header.size}}';
  }
}

class OwnedMessage<T extends Enum> {
  final Connection connection;
  final Message<T> message;

  OwnedMessage({required this.connection, required this.message});
}

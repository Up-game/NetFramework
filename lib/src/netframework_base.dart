// TODO: Put public facing types in this file.

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:messagepack/messagepack.dart';

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

void main(List<String> args) async {
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, 4567);

  server.listen((Socket socket) {
    print("connected");
    socket.listen((Uint8List message) {
      print('message:');
      final unpacked = Unpacker.fromList(message);
      print(unpacked.unpackString());
    });
  });

  await Future.delayed(Duration(seconds: 2));

  final socket = await Socket.connect('localhost', 4567);

  final p = Packer();
  p.packString('hi');
  final arr = p.takeBytes();
  socket.add(arr);
}

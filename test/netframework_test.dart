import 'dart:developer';

import 'package:netframework/netframework.dart';
import 'package:test/test.dart';
import 'package:messagepack/messagepack.dart';

void main() {
  group('A group of tests', () {
    final awesome = Awesome();

    setUp(() {
      // Additional setup goes here.
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });

    test('Byte read', () {
      final p = Packer();
      p.packString('hi');
      final b = p.takeBytes();
      final u = Unpacker.fromList(b);

      final s = u.unpackString();

      print('object');
      print(s.toString());

      expect(s, 'hi');
    });
  });
}

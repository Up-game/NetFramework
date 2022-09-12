import 'dart:typed_data';

import 'package:netframework/src/message.dart';
import 'package:test/test.dart';

enum MessageType { ping }

void main() {
  group('MesssageHeader', () {
    test('Constructor', () {
      final MessageHeader header = MessageHeader();
      expect(header.id, '');
      expect(header.size, 0);
    });

    test('Constructor with id', () {
      final MessageHeader header =
          MessageHeader(id: MessageType.ping.toString());
      expect(header.id, MessageType.ping.toString());
      expect(header.size, 0);
    });
  });

  group('Message', () {
    test('Constructor', () {
      final Message message = Message();
      expect(message.header.id, '');
      expect(message.header.size, 0);
    });

    test('Constructor with id', () {
      final Message message =
          Message(header: MessageHeader(id: MessageType.ping.toString()));
      expect(message.header.id, MessageType.ping.toString());
      expect(message.header.size, 0);
    });

    test('add int', () {
      const int value = 404;

      final Message message = Message();
      message.addHeader();
      message.addInt(value);
      message.pack();

      Uint8List? values = message.data;
      final Message message2 = Message.fromBytes(values!);

      expect(value, message2.getInt());
    });

    test('add double', () {
      const double value = 404.404;

      final Message message = Message();
      message.addHeader();
      message.addDouble(value);
      message.pack();

      Uint8List? values = message.data;
      final Message message2 = Message.fromBytes(values!);

      expect(value, message2.getDouble());
    });

    test('add bool', () {
      const bool value = true;

      final Message message = Message();
      message.addHeader();
      message.addBool(value);
      message.pack();

      Uint8List? values = message.data;
      final Message message2 = Message.fromBytes(values!);

      expect(value, message2.getBool());
    });

    test('add String', () {
      const String value = '404';

      final Message message = Message();
      message.addHeader();
      message.addString(value);
      message.pack();

      Uint8List? values = message.data;
      final Message message2 = Message.fromBytes(values!);

      expect(value, message2.getString());
    });
  });
}

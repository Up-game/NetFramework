import 'dart:typed_data';

import 'package:netframework/src/message.dart';
import 'package:test/test.dart';

enum MessageType { any, ping }

void main() {
  group('MesssageHeader', () {
    test('Constructor', () {
      final MessageHeader header = MessageHeader(id: MessageType.any.index);
      expect(MessageType.values[header.id], MessageType.any);
    });

    test('Constructor with id', () {
      final MessageHeader header = MessageHeader(id: MessageType.ping.index);
      expect(MessageType.values[header.id], MessageType.ping);
    });
  });

  group('Message', () {
    test('Constructor', () {
      final Message message =
          Message(header: MessageHeader(id: MessageType.ping.index));
      expect(MessageType.values[message.header.id], MessageType.ping);
    });

    test('Constructor with id', () {
      final Message message =
          Message(header: MessageHeader(id: MessageType.ping.index));
      expect(MessageType.values[message.header.id], MessageType.ping);
    });

    test('add int', () {
      const int value = 404;

      final Message message =
          Message(header: MessageHeader(id: MessageType.any.index));
      message.addHeader();
      message.addInt(value);
      message.pack();

      Uint8List? values = message.data;
      final Message message2 = Message.fromBytes(values!);

      expect(value, message2.getInt());
    });

    test('add double', () {
      const double value = 404.404;

      final Message message =
          Message(header: MessageHeader(id: MessageType.any.index));
      message.addHeader();
      message.addDouble(value);
      message.pack();

      Uint8List? values = message.data;
      final Message message2 = Message.fromBytes(values!);

      expect(value, message2.getDouble());
    });

    test('add bool', () {
      const bool value = true;

      final Message message =
          Message(header: MessageHeader(id: MessageType.any.index));
      message.addHeader();
      message.addBool(value);
      message.pack();

      Uint8List? values = message.data;
      final Message message2 = Message.fromBytes(values!);

      expect(value, message2.getBool());
    });

    test('add String', () {
      const String value = '404';

      final Message message =
          Message(header: MessageHeader(id: MessageType.any.index));
      message.addHeader();
      message.addString(value);
      message.pack();

      Uint8List? values = message.data;
      final Message message2 = Message.fromBytes(values!);

      expect(value, message2.getString());
    });
  });
}

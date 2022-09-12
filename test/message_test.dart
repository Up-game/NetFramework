import 'dart:typed_data';

import 'package:netframework/src/message.dart';
import 'package:test/test.dart';

enum MessageType { ping }

void main() {
  group('MesssageHeader', () {
    test('Constructor', () {
      final MessageHeader<MessageType> header = MessageHeader<MessageType>();
      expect(header.id, null);
      expect(header.size, 0);
    });

    test('Constructor with id', () {
      final MessageHeader<MessageType> header =
          MessageHeader<MessageType>(id: MessageType.ping);
      expect(header.id, MessageType.ping);
      expect(header.size, 0);
    });
  });

  group('Message', () {
    test('Constructor', () {
      final Message<MessageType> message = Message<MessageType>();
      expect(message.header.id, null);
      expect(message.header.size, 0);
    });

    test('Constructor with id', () {
      final Message<MessageType> message =
          Message<MessageType>(id: MessageType.ping);
      expect(message.header.id, MessageType.ping);
      expect(message.header.size, 0);
    });

    test('add int', () {
      const int value = 404;

      final Message<MessageType> message = Message<MessageType>();
      message.addInt(value);
      message.pack();

      Uint8List? values = message.data;
      final Message<MessageType> message2 = Message<MessageType>(data: values);

      expect(value, message2.getInt());
    });

    test('add double', () {
      const double value = 404.404;

      final Message<MessageType> message = Message<MessageType>();
      message.addDouble(value);
      message.pack();

      Uint8List? values = message.data;
      final Message<MessageType> message2 = Message<MessageType>(data: values);

      expect(value, message2.getDouble());
    });

    test('add bool', () {
      const bool value = true;

      final Message<MessageType> message = Message<MessageType>();
      message.addBool(value);
      message.pack();

      Uint8List? values = message.data;
      final Message<MessageType> message2 = Message<MessageType>(data: values);

      expect(value, message2.getBool());
    });

    test('add String', () {
      const String value = '404';

      final Message<MessageType> message = Message<MessageType>();
      message.addString(value);
      message.pack();

      Uint8List? values = message.data;
      final Message<MessageType> message2 = Message<MessageType>(data: values);

      expect(value, message2.getString());
    });
  });
}

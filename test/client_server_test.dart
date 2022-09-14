import 'dart:isolate';

import 'package:netframework/src/client.dart';
import 'package:netframework/src/connection.dart';
import 'package:netframework/src/message.dart';
import 'package:netframework/src/server.dart';
import 'package:test/test.dart';

enum Directives {
  test,
  other,
}

class MyClient extends Client {
  void sendHelloWolrd() {
    Message m = Message(header: MessageHeader(id: Directives.test.index));
    m.addHeader();
    m.addString('Hello world');
    print("[MyClient]Say hello world");
    send(m);
  }
}

class MyServer extends Server {
  MyServer(int port) : super(port);

  void handleTest(Connection connection, Message message) {
    String? s = message.getString();
    print("[MyServer]Handling message: $s");

    Message response =
        Message(header: MessageHeader(id: Directives.test.index));
    response.addHeader();
    response.addString(s!);

    print("[MyServer]Message sent.");
    sendToClient(connection, response);
  }

  @override
  void onMessage(Connection connection, Message message) {
    print("[MyServer]Server received message: $message");
    switch (Directives.values[message.header.id]) {
      case Directives.test:
        handleTest(connection, message);
        break;
      case Directives.other:
        break;
    }
  }
}

void main() async {
  group('Server and client test', () {
    test('Send data from client to server', () async {
      final rp = ReceivePort();
      await Isolate.spawn(startServer, rp.sendPort);
      // wait for server to start and send port
      final SendPort sp = await rp.first;

      MyClient client = MyClient();
      await client.connect('localhost', 6000);
      client.sendHelloWolrd();

      while (true) {
        await Future.delayed(Duration(milliseconds: 1));
        if (client.incoming.isNotEmpty) {
          OwnedMessage response = client.incoming.removeFirst();
          Message m = response.message;
          String? s = m.getString();
          print("[Client]Received: $s");
          await client.disconnect();
          sp.send(null);
          expect(s, 'Hello world');
          break;
        }
      }
    });
  });
}

void startServer(SendPort sp) async {
  final rp = ReceivePort();

  MyServer server = MyServer(6000);
  await server.start();
  print("[Server]Started.");
  sp.send(rp.sendPort);

  rp.listen((message) async {
    await server.stop();
    Isolate.exit();
  });

  while (true) {
    await server.update(blocking: true);
  }
}

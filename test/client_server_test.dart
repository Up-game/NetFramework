import 'package:netframework/src/client.dart';
import 'package:netframework/src/connection.dart';
import 'package:netframework/src/message.dart';
import 'package:netframework/src/server.dart';
import 'package:test/test.dart';

class MyClient extends Client {}

class MyServer extends Server {
  MyServer(int port) : super(port);

  void handleTest(Connection connection, Message message) {
    int? i = message.getInt();
    String? s = message.getString();
    print("Server received: $i, $s");

    Message response = Message(header: MessageHeader(id: "response"));
    response.addHeader();
    response.addString(s!);

    connection.send(message);
  }

  @override
  void onMessage(Connection connection, Message message) {
    print("Server received message: $message");
    switch (message.header.id) {
      case 'test':
        handleTest(connection, message);
    }
  }
}

void main() {
  group('Server and client test', () {
    test('Send data from client to server', () async {
      MyServer server = MyServer(6000);
      await server.start();

      MyClient client = MyClient();
      await client.connect('localhost', 6000);

      Message m = Message(header: MessageHeader(id: 'test'));
      m.addHeader();
      m.addInt(10);
      m.addString('Hello world');

      client.send(m);

      for (int i = 0; i < 10; i++) {
        server.update();

        if (client.incoming.isNotEmpty) {
          OwnedMessage response = client.incoming.removeFirst();
          Message m = response.message;
          print("Client received: ${m.getString()}");
          break;
        }

        await Future.delayed(Duration(seconds: 1));
      }
    });
  });
}
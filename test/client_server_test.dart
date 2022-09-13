import 'package:netframework/src/client.dart';
import 'package:netframework/src/connection.dart';
import 'package:netframework/src/message.dart';
import 'package:netframework/src/server.dart';
import 'package:test/test.dart';

enum Directives {
  test,
  other,
}

class MyClient extends Client<Directives> {}

class MyServer extends Server<Directives> {
  MyServer(int port) : super(port);

  void handleTest(Connection connection, Message<Directives> message) {
    int? i = message.getInt();
    String? s = message.getString();
    print("Handling message: $i, $s");

    Message<Directives> response =
        Message(header: MessageHeader(id: Directives.other));
    response.addHeader();
    response.addString(s!);

    sendToClient(connection, message);
  }

  @override
  void onMessage(Connection connection, Message<Directives> message) {
    print("Server received message: $message");
    switch (message.header.id) {
      case Directives.test:
        handleTest(connection, message);
        break;
      case Directives.other:
        break;
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

      Message<Directives> m =
          Message(header: MessageHeader(id: Directives.test));
      m.addHeader();
      m.addInt(10);
      m.addString('Hello world');

      client.send(m);

      for (int i = 0; i < 10; i++) {
        server.update();

        if (client.incoming.isNotEmpty) {
          OwnedMessage response = client.incoming.removeFirst();
          Message m = response.message;
          String? s = m.getString();
          print("Client received: $s");
          expect(s, 'Hello world');
          break;
        }

        await Future.delayed(Duration(milliseconds: 500));
      }
      await client.disconnect();
      await Future.delayed(Duration(milliseconds: 500));
      await server.stop();
    });
  });
}

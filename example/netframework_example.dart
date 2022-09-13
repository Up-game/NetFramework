import 'package:netframework/netframework.dart';

enum Directives {
  test,
  other,
}

class MyClient<T extends Enum> extends Client<T> {}

class MyServer<T extends Enum> extends Server<T> {
  MyServer(int port) : super(port);

  void handleTest(Connection connection, Message<T> message) {
    int? i = message.getInt();
    String? s = message.getString();
    print("Handling message: $i, $s");

    Message<T> response = Message(header: MessageHeader(id: Directives.other));
    response.addHeader();
    response.addString(s!);

    sendToClient(connection, message);
  }

  @override
  void onMessage(Connection connection, Message<T> message) {
    print("Server received message: $message");
    switch (message.header.id) {
      case Directives.test:
        handleTest(connection, message);
    }
  }
}

void main() async {
  MyServer server = MyServer<Directives>(6000);
  await server.start();

  MyClient client = MyClient<Directives>();
  await client.connect('localhost', 6000);

  Message m = Message(header: MessageHeader(id: Directives.test));
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
      break;
    }

    await Future.delayed(Duration(milliseconds: 500));
  }
  await client.disconnect();
  await Future.delayed(Duration(milliseconds: 500));
  await server.stop();
}

import 'dart:isolate';

import 'package:netframework/netframework.dart';

enum Directives {
  ping,
  other,
}

class MyClient extends Client<Directives> {
  void ping() {
    Message<Directives> m = Message(header: MessageHeader(id: Directives.ping));
    m.addHeader();
    m.addString(DateTime.now().toIso8601String());
    print("Ping");
    send(m);
  }
}

class MyServer extends Server<Directives> {
  MyServer(int port) : super(port);

  void handlePing(Connection connection, Message<Directives> message) {
    final time = message.getString();

    Message<Directives> response =
        Message(header: MessageHeader(id: Directives.ping));
    response.addHeader();
    response.addString(time!);

    sendToClient(connection, response);
  }

  @override
  void onMessage(Connection connection, Message<Directives> message) {
    print("Server received message: $message");
    switch (message.header.id) {
      case Directives.ping:
        handlePing(connection, message);
        break;
      case Directives.other:
        break;
    }
  }
}

void main() async {
  MyServer server = MyServer(6000);
  await server.start();

  await Isolate.spawn(startClient, null);

  for (int i = 0; i < 1000; i++) {
    await Future.delayed(Duration(milliseconds: 1));
    server.update();
  }

  await server.stop();
}

void startClient(int? _) async {
  MyClient client = MyClient();
  await client.connect('localhost', 6000);

  client.ping();

  while (true) {
    await Future.delayed(Duration(milliseconds: 1));
    if (client.incoming.isNotEmpty) {
      OwnedMessage<Directives> response = client.incoming.removeFirst();
      Message<Directives> m = response.message;
      if (m.header.id == Directives.ping) {
        final now = DateTime.now();
        String? s = m.getString();
        final old = DateTime.parse(s!);
        final duration = now.difference(old);
        print("Pong in ${duration.inMilliseconds}ms");
      }

      break;
    }
  }
  await client.disconnect();
}

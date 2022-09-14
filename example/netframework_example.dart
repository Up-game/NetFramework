import 'dart:io';
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
    print("[MyClient]Ping");
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
    print("[MyServer]Received message: $message");
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
  final rp = ReceivePort();
  await Isolate.spawn(startServer, rp.sendPort);
  // wait for server to start and send port
  final SendPort sp = await rp.first;

  MyClient client = MyClient();
  await client.connect('localhost', 6000);
  client.ping();

  ProcessSignal.sigint.watch().listen((signal) async {
    if (signal != ProcessSignal.sigusr1) {
      print("Killing server !");
      sp.send(null);
      await client.disconnect();
      exit(0);
    }
  });

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
        print("[MyClient]Pong in ${duration.inMilliseconds}ms");
      }
      break;
    }
  }
  await client.disconnect();
}

void startServer(SendPort sp) async {
  final rp = ReceivePort();
  MyServer server;
  try {
    server = MyServer(6000);
    await server.start();
  } catch (e) {
    print(e);
    exit(1);
  }

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

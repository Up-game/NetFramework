typedef Printer = void Function(LogLevel, LogActor, String);

enum LogLevel {
  none,
  error,
  warning,
  info,
  debug,
  verbose;

  @override
  String toString() {
    switch (this) {
      case LogLevel.none:
        return 'None';
      case LogLevel.error:
        return 'Error';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.info:
        return 'Info';
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.verbose:
        return 'Verbose';
    }
  }
}

enum LogActor {
  client,
  server;

  @override
  String toString() {
    switch (this) {
      case LogActor.client:
        return 'Client';
      case LogActor.server:
        return 'Server';
    }
  }
}

class ServerBindingException implements Exception {
  ServerBindingException();

  @override
  String toString() {
    return "Server failed binding with that port.";
  }
}

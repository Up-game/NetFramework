import 'dart:math';

/// Returns the values of an enum.
///
/// [type] is the type of the enum.
// List<T> callValuesOfEnum<T extends Enum>(Type type) {
//   final instanceMirror = reflectClass(type);
//   final List<T> values = instanceMirror.getField(#values).reflectee;
//   return values;
// }

/// Generates a random string of length [len].
String generateRandomString(int len) {
  var r = Random();
  return String.fromCharCodes(
      List.generate(len, (index) => r.nextInt(33) + 89));
}

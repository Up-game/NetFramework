import 'dart:mirrors';

/// Returns the values of an enum.
///
/// [type] is the type of the enum.
List<T> callValuesOfEnum<T extends Enum>(Type type) {
  final instanceMirror = reflectClass(type);
  final List<T> values = instanceMirror.getField(#values).reflectee;
  return values;
}

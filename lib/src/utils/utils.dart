import 'dart:mirrors';

List<T> callValuesOfEnum<T>(Type type) {
  final instanceMirror = reflectClass(type);
  final List<T> values = instanceMirror.getField(#values).reflectee;
  return values;
}

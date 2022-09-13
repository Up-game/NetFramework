import 'dart:mirrors';

List<T> callValuesOfEnum<T extends Enum>(T value) {
  final instanceMirror = reflect(value);
  var classMirror = instanceMirror.type;
  final v = classMirror.getField(#values).reflectee;
  return v;
}

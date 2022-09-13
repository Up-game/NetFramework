import 'dart:mirrors';

enum Test {
  A,
  B,
  C;
}

void main(List<String> args) {
  printGetterValues(reflect(Test.A));
}

void printGetterValues(InstanceMirror instanceMirror) {
  var classMirror = instanceMirror.type;
  final v = classMirror.getField(#values).reflectee;
  print(v.toString());
  classMirror.staticMembers.forEach((sym, met) {
    print(sym);
  });
}

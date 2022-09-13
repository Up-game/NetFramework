import 'package:netframework/src/utils/utils.dart';

enum Test {
  A,
  B,
  C;
}

class TestClass<T extends Enum> {
  T id;

  TestClass(this.id);

  T func() {
    return callValuesOfEnum<T>(T)[id.index];
  }
}

void main(List<String> args) {
  TestClass<Test> test = TestClass(Test.A);
  print(test.func());
}

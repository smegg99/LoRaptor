// lib/cli/argument.dart
import 'value.dart';

class Argument {
  String name;
  List<Value> values = [];

  Argument(this.name);

  Argument.withValues(this.name, this.values);
}

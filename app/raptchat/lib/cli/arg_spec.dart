// lib/cli/arg_spec.dart
import 'value.dart';

class ArgSpec {
  String name;
  ValueType type;
  bool required;
  bool hasDefault;
  Value? defaultValue;
  String helpText;

  ArgSpec(this.name, this.type,
      {this.required = false,
      this.helpText = "",
      this.hasDefault = false,
      this.defaultValue});

  ArgSpec.withDefault(
      this.name, this.type, bool req, this.defaultValue, this.helpText)
      : required = req,
        hasDefault = true;
}

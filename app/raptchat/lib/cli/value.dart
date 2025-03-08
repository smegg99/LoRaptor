// lib/cli/value.dart
enum ValueType { none, intType, doubleType, boolType, stringType, listType }

class Value {
  ValueType type;
  int? intValue;
  double? doubleValue;
  bool? boolValue;
  String? stringValue;
  List<Value>? listValue;

  Value() : type = ValueType.none;

  Value.intValueConstructor(int v)
      : type = ValueType.intType,
        intValue = v;

  Value.doubleValueConstructor(double v)
      : type = ValueType.doubleType,
        doubleValue = v;

  Value.boolValueConstructor(bool v)
      : type = ValueType.boolType,
        boolValue = v;

  Value.stringValueConstructor(String v)
      : type = ValueType.stringType,
        stringValue = v;

  Value.listValueConstructor(List<Value> v)
      : type = ValueType.listType,
        listValue = v;

  @override
  String toString() {
    switch (type) {
      case ValueType.intType:
        return intValue.toString();
      case ValueType.doubleType:
        return doubleValue.toString();
      case ValueType.boolType:
        return boolValue! ? "true" : "false";
      case ValueType.stringType:
        return stringValue!;
      case ValueType.listType:
        String result = "[";
        if (listValue != null && listValue!.isNotEmpty) {
          result += listValue!.map((v) => v.toString()).join(", ");
        }
        result += "]";
        return result;
      default:
        return "";
    }
  }
}

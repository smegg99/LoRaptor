// lib/cli/command.dart
import 'argument.dart';
import 'arg_spec.dart';
import 'cli_output.dart';
import 'value.dart';

typedef CommandCallback = void Function(Command cmd);

class Command {
  String name;
  String description;
  List<String> aliases = [];
  List<Command> subcommands = [];
  List<Argument> arguments = [];
  List<ArgSpec> argSpecs = [];
  bool variadic = false;
  CommandCallback? callback;

  CLIOutput? _output;

  Command({required this.name, this.description = "", this.callback});

  void setVariadic(bool v) {
    variadic = v;
  }

  bool addSubcommand(Command cmd) {
    // Check for duplicate names/aliases.
    for (var sub in subcommands) {
      if (sub.name == cmd.name || sub.aliases.contains(cmd.name)) {
        _reportError("Duplicate subcommand name: ${cmd.name}");
        return false;
      }
      for (var alias in cmd.aliases) {
        if (sub.name == alias || sub.aliases.contains(alias)) {
          _reportError("Duplicate subcommand alias: $alias");
          return false;
        }
      }
    }
    subcommands.add(cmd);
    return true;
  }

  bool addAlias(String alias) {
    if (alias == name || aliases.contains(alias)) {
      _reportError("Duplicate alias: $alias");
      return false;
    }
    aliases.add(alias);
    return true;
  }

  bool addArgSpec(ArgSpec spec) {
    for (var s in argSpecs) {
      if (s.name == spec.name) {
        _reportError("Duplicate argument name: ${spec.name}");
        return false;
      }
    }
    argSpecs.add(spec);
    return true;
  }

  void printUsage({String prefix = "", CLIOutput? output}) {
    CLIOutput out = output ?? _output ?? StdCLIOutput();
    String cmdLine = "$prefix$name";
    if (aliases.isNotEmpty) {
      cmdLine += " (aliases: ${aliases.join(", ")})";
    }
    out.println("$cmdLine - $description");
    if (argSpecs.isNotEmpty) {
      out.println("$prefix  Arguments:");
      for (var spec in argSpecs) {
        String typeStr;
        switch (spec.type) {
          case ValueType.intType:
            typeStr = "int";
            break;
          case ValueType.doubleType:
            typeStr = "double";
            break;
          case ValueType.boolType:
            typeStr = "bool";
            break;
          case ValueType.stringType:
            typeStr = "string";
            break;
          case ValueType.listType:
            typeStr = "list";
            break;
          default:
            typeStr = "unknown";
        }
        String argLine =
            "$prefix    -${spec.name} ($typeStr) ${spec.required ? "required" : "optional"}";
        if (spec.hasDefault && spec.defaultValue != null) {
          argLine += ", default = ${spec.defaultValue}";
        }
        if (spec.helpText.isNotEmpty) {
          argLine += " -- ${spec.helpText}";
        }
        out.println(argLine);
      }
    }
    if (subcommands.isNotEmpty) {
      out.println("$prefix  Subcommands:");
      for (var sub in subcommands) {
        sub.printUsage(prefix: "$prefix    ", output: out);
      }
    }
  }

  void registerOutput(CLIOutput output) {
    _output = output;
    for (var sub in subcommands) {
      sub.registerOutput(output);
    }
  }

  CLIOutput? getOutput() => _output;

  void _reportError(String msg) {
    if (_output != null) {
      _output!.println(msg);
    } else {
      print(msg);
    }
  }
}

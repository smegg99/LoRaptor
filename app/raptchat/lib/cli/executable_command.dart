// lib/cli/executable_command.dart
import 'command.dart';
import 'argument.dart';
import 'value.dart';
import 'cli_output.dart';

class ExecutableCommand {
  final Command baseCommand;
  List<Argument> presetArgs;

  ExecutableCommand(this.baseCommand, [List<Argument>? presetArgs])
      : presetArgs = presetArgs ?? [];

  ExecutableCommand.fromMap(this.baseCommand, Map<String, Value> presetArgsMap)
      : presetArgs = presetArgsMap.entries.map((e) {
          Argument arg = Argument(e.key);
          arg.values.add(e.value);
          return arg;
        }).toList();

  bool execute() {
    if (baseCommand.callback != null) {
      // Create a copy of the command with preset arguments.
      Command execCmd = Command(
        name: baseCommand.name,
        description: baseCommand.description,
        callback: baseCommand.callback,
      );
      execCmd.arguments = presetArgs;
      execCmd.argSpecs = baseCommand.argSpecs;
      execCmd.aliases = baseCommand.aliases;
      execCmd.subcommands = baseCommand.subcommands;
      baseCommand.callback!(execCmd);
      return true;
    } else {
      CLIOutput? out = baseCommand.getOutput();
      out?.println(
          "Error: No callback defined for command: ${baseCommand.name}");
      return false;
    }
  }

  bool executeWithArgs(Map<String, Value> argsMap) {
    List<Argument> args = argsMap.entries.map((e) {
      Argument arg = Argument(e.key);
      arg.values.add(e.value);
      return arg;
    }).toList();
    if (baseCommand.callback != null) {
      Command execCmd = Command(
        name: baseCommand.name,
        description: baseCommand.description,
        callback: baseCommand.callback,
      );
      execCmd.arguments = args;
      baseCommand.callback!(execCmd);
      return true;
    } else {
      CLIOutput? out = baseCommand.getOutput();
      out?.println(
          "Error: No callback defined for command: ${baseCommand.name}");
      return false;
    }
  }

  String toStringCommand() {
    String result = baseCommand.name;
    for (var arg in presetArgs) {
      result += " -${arg.name} ";
      result += arg.values.map((v) => v.toString()).join(", ");
    }
    return result;
  }

  String toStringWithArgs(Map<String, Value> argsMap) {
    String result = baseCommand.name;
    argsMap.forEach((key, value) {
      result += " -$key ${value.toString()}";
    });
    return result;
  }

  void toOutputWithArgs(Map<String, Value> argsMap) {
    CLIOutput? out = baseCommand.getOutput();
    if (out != null) {
      out.println(toStringWithArgs(argsMap));
    }
  }
}

class CommandSequence {
  final List<ExecutableCommand> commands = [];

  void addCommand(ExecutableCommand cmd) {
    commands.add(cmd);
  }

  bool execute() {
    bool overallSuccess = true;
    for (var cmd in commands) {
      bool result = cmd.execute();
      if (!result) overallSuccess = false;
    }
    return overallSuccess;
  }

  String toStringSequence() {
    return commands.map((cmd) => cmd.toStringCommand()).join("; ");
  }
}

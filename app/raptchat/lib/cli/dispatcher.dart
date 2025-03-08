// lib/cli/dispatcher.dart
import 'command.dart';
import 'argument.dart';
import 'value.dart';
import 'cli_output.dart';

typedef ErrorCallback = void Function(String message);

class Dispatcher {
  CLIOutput? output;
  ErrorCallback? errorCallback;
  final List<Command> _commands = [];

  void reportError(String msg) {
    if (output != null) {
      output!.println(msg);
    } else if (errorCallback != null) {
      errorCallback!(msg);
    } else {
      print(msg);
    }
  }

  void registerErrorCallback(ErrorCallback callback) {
    errorCallback = callback;
  }

  void registerOutput(CLIOutput output) {
    this.output = output;
  }

  bool registerCommand(Command cmd) {
    // Check for duplicate command names or aliases.
    for (var existing in _commands) {
      if (existing.name == cmd.name || existing.aliases.contains(cmd.name)) {
        reportError("Duplicate command name: ${cmd.name}");
        return false;
      }
      for (var alias in cmd.aliases) {
        if (existing.name == alias || existing.aliases.contains(alias)) {
          reportError("Duplicate command alias: $alias");
          return false;
        }
      }
    }
    _commands.add(cmd);
    return true;
  }

  /// Dispatch an input string. Multiple commands can be separated by ';'.
  bool dispatch(String input) {
    String cleanedInput = input.trim();
    List<String> commandStrings = _splitCommands(cleanedInput);
    bool overallSuccess = true;
    for (var cmdStr in commandStrings) {
      if (cmdStr.trim().isEmpty) continue;
      bool result = _dispatchSingleCommand(cmdStr.trim());
      if (!result) overallSuccess = false;
    }
    return overallSuccess;
  }

  List<String> _splitCommands(String input) {
    List<String> commands = [];
    StringBuffer current = StringBuffer();
    _SplitState state = _SplitState.outside;
    for (int i = 0; i < input.length; i++) {
      String c = input[i];
      switch (state) {
        case _SplitState.outside:
          if (c == ';') {
            commands.add(current.toString());
            current.clear();
          } else if (c == '"') {
            state = _SplitState.inQuote;
            current.write(c);
          } else if (c == '[') {
            state = _SplitState.inList;
            current.write(c);
          } else {
            current.write(c);
          }
          break;
        case _SplitState.inQuote:
          current.write(c);
          if (c == '"') state = _SplitState.outside;
          break;
        case _SplitState.inList:
          current.write(c);
          if (c == ']') state = _SplitState.outside;
          break;
      }
    }
    if (current.isNotEmpty) commands.add(current.toString());
    return commands;
  }

  bool _dispatchSingleCommand(String command) {
    List<String> tokens = _tokenize(command);
    if (tokens.isEmpty) return false;

    // Use _matchCommand with _MatchResult to update the token index.
    _MatchResult? matchResult = _matchCommand(tokens, 0);
    if (matchResult == null) {
      reportError("Unknown command: ${tokens[0]}");
      return false;
    }
    Command cmd = matchResult.command;
    int index = matchResult.nextIndex;

    List<Argument> parsedArgs = [];
    if (!_parseArguments(tokens, index, parsedArgs)) {
      return false;
    }
    // Check for help flag.
    bool foundHelp =
        parsedArgs.any((arg) => arg.name == "h" || arg.name == "help");
    if (foundHelp) {
      cmd.printUsage(prefix: "", output: output);
      return true;
    }
    // Merge parsed arguments with expected argument specifications.
    List<Argument> mergedArgs = [];
    for (var spec in cmd.argSpecs) {
      Argument? foundArg;
      try {
        foundArg = parsedArgs.firstWhere((a) => a.name == spec.name);
      } catch (e) {
        foundArg = null;
      }
      if (foundArg == null) {
        if (spec.required && !spec.hasDefault) {
          reportError("Required argument missing: ${spec.name}");
          return false;
        }
        if (spec.hasDefault && spec.defaultValue != null) {
          Argument defaultArg = Argument(spec.name);
          defaultArg.values.add(spec.defaultValue!);
          mergedArgs.add(defaultArg);
        }
      } else {
        if (foundArg.values.isEmpty) {
          reportError("Argument ${spec.name} has no value.");
          return false;
        }
        Value provided = foundArg.values[0];
        if (spec.type == ValueType.doubleType) {
          if (provided.type == ValueType.intType && provided.intValue != null) {
            provided =
                Value.doubleValueConstructor(provided.intValue!.toDouble());
          } else if (provided.type != ValueType.doubleType) {
            reportError("Type mismatch for argument: ${spec.name}");
            return false;
          }
        } else if (provided.type != spec.type) {
          reportError("Type mismatch for argument: ${spec.name}");
          return false;
        }
        mergedArgs.add(foundArg);
      }
    }
    // Prepare a command for execution.
    Command execCmd = Command(
        name: cmd.name, description: cmd.description, callback: cmd.callback);
    execCmd.arguments = mergedArgs;
    execCmd.argSpecs = cmd.argSpecs;
    execCmd.aliases = cmd.aliases;
    execCmd.subcommands = cmd.subcommands;
    if (execCmd.callback != null) {
      execCmd.callback!(execCmd);
      return true;
    } else {
      reportError("No callback defined for command: ${execCmd.name}");
      return false;
    }
  }

  List<String> _tokenize(String input) {
    List<String> tokens = [];
    StringBuffer token = StringBuffer();
    _TokenizerState state = _TokenizerState.outside;
    for (int i = 0; i < input.length; i++) {
      String c = input[i];
      switch (state) {
        case _TokenizerState.outside:
          if (c.trim().isEmpty) {
            if (token.isNotEmpty) {
              tokens.add(token.toString().trim());
              token.clear();
            }
          } else if (c == '"') {
            state = _TokenizerState.inQuote;
          } else if (c == '[') {
            state = _TokenizerState.inList;
            token.write(c);
          } else {
            token.write(c);
          }
          break;
        case _TokenizerState.inQuote:
          if (c == '\\') {
            state = _TokenizerState.inEscape;
          } else if (c == '"') {
            state = _TokenizerState.outside;
          } else {
            token.write(c);
          }
          break;
        case _TokenizerState.inEscape:
          token.write(c);
          state = _TokenizerState.inQuote;
          break;
        case _TokenizerState.inList:
          token.write(c);
          if (c == ']') state = _TokenizerState.outside;
          break;
      }
    }
    if (token.isNotEmpty) tokens.add(token.toString().trim());
    return tokens;
  }

  _MatchResult? _matchCommand(List<String> tokens, int startIndex) {
    // Look for a registered command whose name or alias matches the token at startIndex.
    String token0 = tokens[startIndex];
    for (var cmd in _commands) {
      if (cmd.name == token0 || cmd.aliases.contains(token0)) {
        int idx = startIndex + 1;
        Command current = cmd;
        while (idx < tokens.length && !tokens[idx].startsWith('-')) {
          bool foundSub = false;
          for (var sub in current.subcommands) {
            if (sub.name == tokens[idx] || sub.aliases.contains(tokens[idx])) {
              current = sub;
              foundSub = true;
              idx++;
              break;
            }
          }
          if (!foundSub) break;
        }
        return _MatchResult(command: current, nextIndex: idx);
      }
    }
    return null;
  }

  bool _parseArguments(List<String> tokens, int index, List<Argument> outArgs) {
    final seenArgs = <String>{};
    while (index < tokens.length) {
      String token = tokens[index];
      if (token.isEmpty || !token.startsWith('-')) {
        reportError("Unexpected token: $token");
        return false;
      }
      String argName = token.substring(1);
      if (seenArgs.contains(argName)) {
        reportError("Duplicate argument: $argName");
        return false;
      }
      seenArgs.add(argName);
      Argument arg = Argument(argName);
      index++;
      while (index < tokens.length && !tokens[index].startsWith('-')) {
        String valueToken = tokens[index];
        if (valueToken.startsWith('[') && valueToken.endsWith(']')) {
          arg.values.add(_parseList(valueToken));
        } else {
          arg.values.add(_parseValue(valueToken));
        }
        index++;
      }
      outArgs.add(arg);
    }
    return true;
  }

  Value _parseValue(String token) {
    int? intValue = int.tryParse(token);
    if (intValue != null) {
      return Value.intValueConstructor(intValue);
    }
    double? doubleValue = double.tryParse(token);
    if (doubleValue != null) {
      return Value.doubleValueConstructor(doubleValue);
    }
    if (token.toLowerCase() == "true") {
      return Value.boolValueConstructor(true);
    }
    if (token.toLowerCase() == "false") {
      return Value.boolValueConstructor(false);
    }
    return Value.stringValueConstructor(token);
  }

  Value _parseList(String token) {
    String inner = token.substring(1, token.length - 1);
    List<String> items = inner.split(',').map((s) => s.trim()).toList();
    List<Value> listValues = [];
    for (var item in items) {
      if (item.isNotEmpty) {
        listValues.add(_parseValue(item));
      }
    }
    return Value.listValueConstructor(listValues);
  }

  void printGlobalHelp() {
    if (output != null) {
      for (var cmd in _commands) {
        cmd.printUsage(prefix: "  ", output: output);
      }
    }
  }

  CLIOutput? getOutput() => output;
}

enum _TokenizerState { outside, inQuote, inEscape, inList }

enum _SplitState { outside, inQuote, inList }

class _MatchResult {
  final Command command;
  final int nextIndex;
  _MatchResult({required this.command, required this.nextIndex});
}

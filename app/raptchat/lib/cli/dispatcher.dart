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
    print("Dispatching command: '$command'");
    print("Tokens: $tokens");
    if (tokens.isEmpty) return false;


    _MatchResult? matchResult = _matchCommand(tokens, 0);
    if (matchResult == null) {
      reportError("Unknown command: ${tokens[0]}");
      return false;
    }
    print("Matched command: ${matchResult.command.name}");
    Command cmd = matchResult.command;
    int index = matchResult.nextIndex;

    // Parse arguments using the common parser.
    List<Argument> parsedArgs = [];
    if (!_parseArguments(tokens, index, parsedArgs)) {
      return false;
    }

    print("Parsed arguments:");
    for (var arg in parsedArgs) {
      print("  ${arg.name}: ${arg.values}");
    }

    // Check for help flag.
    bool foundHelp = parsedArgs.any((arg) =>
        arg.name == "h" ||
        arg.name == "help" ||
        arg.values.any((v) =>
            v.type == ValueType.stringType &&
            (v.stringValue == "h" || v.stringValue == "help")));
    if (foundHelp) {
      cmd.printUsage(prefix: "", output: output);
      return true;
    }

    // For non-variadic commands, merge parsed arguments with expected argSpecs.
    List<Argument> mergedArgs = [];
    if (!cmd.variadic) {
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
            if (provided.type == ValueType.intType &&
                provided.intValue != null) {
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
    } else {
      // For variadic commands, keep the parsed arguments as they are.
      mergedArgs = parsedArgs;
    }

    // Prepare and execute the command.
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
    int i = 0;
    while (i < input.length) {
      // Skip any leading whitespace.
      while (i < input.length && input[i].trim().isEmpty) {
        i++;
      }
      if (i >= input.length) break;
      // If token starts with a quote, read until the closing quote.
      if (input[i] == '"') {
        int start = i + 1;
        i++; // skip opening quote
        StringBuffer sb = StringBuffer();
        while (i < input.length && input[i] != '"') {
          if (input[i] == '\\' && i + 1 < input.length) {
            // Handle escaped characters.
            sb.write(input[i + 1]);
            i += 2;
          } else {
            sb.write(input[i]);
            i++;
          }
        }
        i++; // skip closing quote
        tokens.add(sb.toString().trim());
      }
      // If token starts with a bracket, consume until the matching bracket.
      else if (input[i] == '[') {
        int start = i;
        int bracketCount = 0;
        while (i < input.length) {
          if (input[i] == '[') {
            bracketCount++;
          } else if (input[i] == ']') {
            bracketCount--;
            if (bracketCount == 0) {
              i++; // include the closing bracket
              break;
            }
          }
          i++;
        }
        tokens.add(input.substring(start, i).trim());
      }
      // Otherwise, read until the next whitespace.
      else {
        int start = i;
        while (i < input.length && input[i].trim().isNotEmpty) {
          i++;
        }
        tokens.add(input.substring(start, i).trim());
      }
    }
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
      // Skip empty tokens rather than erroring out.
      if (token.isEmpty) {
        index++;
        continue;
      }
      if (!token.startsWith('-')) {
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
        // Skip if valueToken is empty.
        if (valueToken.isEmpty) {
          index++;
          continue;
        }
        if (valueToken.startsWith('[') && valueToken.endsWith(']')) {
          arg.values.add(_parseList(valueToken));
        } else {
          arg.values.add(_parseValue(valueToken));
        }
        index++;
      }
      outArgs.add(arg);
    }

    print("Parsed arguments:");
    for (var arg in outArgs) {
      print("  ${arg.name}: ${arg.values}");
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

  List<String> _splitTopLevelList(String input) {
    List<String> parts = [];
    int bracketLevel = 0;
    StringBuffer current = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      String c = input[i];
      if (c == '[') {
        bracketLevel++;
        current.write(c);
      } else if (c == ']') {
        bracketLevel--;
        current.write(c);
      } else if (c == ',' && bracketLevel == 0) {
        // At top level, a comma indicates a split.
        String token = current.toString().trim();
        // Only add non-empty tokens.
        if (token.isNotEmpty) {
          parts.add(token);
        }
        current.clear();
      } else {
        current.write(c);
      }
    }
    // Add the final token if present.
    if (current.isNotEmpty) {
      String token = current.toString().trim();
      if (token.isNotEmpty) {
        parts.add(token);
      }
    }
    return parts;
  }

  List<Value> _parseListItems(String input) {
    List<Value> values = [];
    int index = 0;
    while (index < input.length) {
      // Skip commas and whitespace.
      while (index < input.length &&
          (input[index] == ',' || input[index].trim().isEmpty)) {
        index++;
      }
      if (index >= input.length) break;
      if (input[index] == '[') {
        // Found a nested list; locate its matching closing bracket.
        int start = index;
        int bracketCount = 0;
        while (index < input.length) {
          if (input[index] == '[') {
            bracketCount++;
          } else if (input[index] == ']') {
            bracketCount--;
          }
          index++;
          if (bracketCount == 0) break;
        }
        String nestedStr = input.substring(start, index);
        values.add(_parseList(nestedStr));
      } else {
        // Parse a non-list token (until the next comma or closing bracket).
        int start = index;
        while (index < input.length &&
            input[index] != ',' &&
            input[index] != ']') {
          index++;
        }
        String token = input.substring(start, index).trim();
        if (token.isNotEmpty) {
          values.add(_parseValue(token));
        }
      }
    }
    return values;
  }

  Value _parseList(String token) {
    // Assume token starts with '[' and ends with ']'
    // Remove the outer brackets.
    String inner = token.substring(1, token.length - 1).trim();
    // Use our helper to split only on top-level commas.
    List<String> parts = _splitTopLevelList(inner);
    List<Value> values = [];
    for (var part in parts) {
      if (part.isEmpty) continue;
      // If a part is itself a list (starts with '[' and ends with ']'),
      // parse it recursively.
      if (part.startsWith('[') && part.endsWith(']')) {
        values.add(_parseList(part));
      } else {
        values.add(_parseValue(part));
      }
    }
    return Value.listValueConstructor(values);
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

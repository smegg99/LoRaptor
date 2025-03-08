// lib/cli/cli_output.dart
import 'dart:io';

abstract class CLIOutput {
  void print(String s);
  void println(String s);
  void printlnEmpty();
}

class StdCLIOutput implements CLIOutput {
  @override
  void print(String s) {
    stdout.write(s);
  }

  @override
  void println(String s) {
    stdout.writeln(s);
  }

  @override
  void printlnEmpty() {
    stdout.writeln();
  }
}

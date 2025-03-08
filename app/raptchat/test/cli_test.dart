// test/cli_test.dart
import 'package:raptchat/cli/raptor_cli.dart';

void main() {
  final dispatcher = Dispatcher();
  dispatcher.registerOutput(StdCLIOutput());

  // -------------------------
  // Register "send" command.
  // -------------------------
  final sendCommand = Command(
    name: "send",
    description: "Send a message to a connection",
    callback: (cmd) {
      final idArg = cmd.arguments.firstWhere((arg) => arg.name == "id");
      final mArg = cmd.arguments.firstWhere((arg) => arg.name == "m");
      print("Send command callback:");
      print("ID: ${idArg.values.first}");
      print("Message: ${mArg.values.first}");
    },
  );

  sendCommand.addArgSpec(ArgSpec("id", ValueType.stringType,
      required: true, helpText: "Connection identifier"));
  sendCommand.addArgSpec(ArgSpec("m", ValueType.stringType,
      required: true, helpText: "Message text"));

  dispatcher.registerCommand(sendCommand);

  // ---------------------------
  // Register "return" command.
  // ---------------------------
  final returnCommand = Command(
    name: "return",
    description: "Return message from device",
    callback: (cmd) {
      final mArg = cmd.arguments.firstWhere((arg) => arg.name == "m");
      print("Return command callback:");
      print("Message: ${mArg.values.first}");
    },
  );

  returnCommand.addArgSpec(ArgSpec("m", ValueType.stringType,
      required: true, helpText: "Return message text"));

  dispatcher.registerCommand(returnCommand);

  // ---------------------------
  // Register "setlist" command.
  // ---------------------------
  final setListCommand = Command(
    name: "setlist",
    description: "Set a list of items",
    callback: (cmd) {
      final listArg = cmd.arguments.firstWhere((arg) => arg.name == "items");
      print("Setlist command callback:");
      print("Items: ${listArg.values.first}");
    },
  );

  setListCommand.addArgSpec(ArgSpec("items", ValueType.listType,
      required: true, helpText: "List of items (e.g., [item1, item2, item3])"));

  dispatcher.registerCommand(setListCommand);

  // ---------------------------
  // Register "device" command with subcommands.
  // ---------------------------
  final deviceCommand = Command(
    name: "device",
    description: "Manage devices",
    callback: (cmd) {
      print("Device command callback: no subcommand provided.");
    },
  );

  final connectSubcommand = Command(
    name: "connect",
    description: "Connect to a device",
    callback: (cmd) {
      final idArg = cmd.arguments.firstWhere((arg) => arg.name == "id");
      print("Device connect subcommand callback:");
      print("Connecting to device: ${idArg.values.first}");
    },
  );
  connectSubcommand.addArgSpec(ArgSpec("id", ValueType.stringType,
      required: true, helpText: "Device identifier"));

  final disconnectSubcommand = Command(
    name: "disconnect",
    description: "Disconnect from device",
    callback: (cmd) {
      print("Device disconnect subcommand callback: Disconnecting device.");
    },
  );

  deviceCommand.addSubcommand(connectSubcommand);
  deviceCommand.addSubcommand(disconnectSubcommand);

  dispatcher.registerCommand(deviceCommand);

  // -------------------------------------
  // Dispatch some example command strings.
  // -------------------------------------
  String input1 = 'send -id "connection 1" -m "hello world"';
  print("Dispatching command: $input1");
  dispatcher.dispatch(input1);

  String inputHelp = 'send -help';
  print("\nDispatching help command: $inputHelp");
  dispatcher.dispatch(inputHelp);

  String input2 = 'return -m "conn.send.success"';
  print("\nDispatching command: $input2");
  dispatcher.dispatch(input2);

  String input3 =
      'setlist -items "[apple, balls, ligma, sugma, bofa, deez, nuts, ligma, sugma]"';
  print("\nDispatching command: $input3");
  dispatcher.dispatch(input3);

  String input4 = 'device connect -id "device1"';
  print("\nDispatching command: $input4");
  dispatcher.dispatch(input4);

  String input5 = 'device disconnect';
  print("\nDispatching command: $input5");
  dispatcher.dispatch(input5);
}

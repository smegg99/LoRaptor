// src/commands.cpp
#include "config.h"
#include "commands.h"
#include "connection_manager.h"
#include "RaptorCLI.h"

#ifdef RGB_FEEDBACK_ENABLED
#include "rgb_feedback.h"
extern RGBFeedback rgbFeedback;
#endif

extern ConnectionManager connectionManager;
extern Dispatcher dispatcher;

void createConnectionCallback(const Command& cmd) {
	String id = String(cmd.arguments[0].values[0].toCString());
	String key = String(cmd.arguments[1].values[0].toCString());
	CLIOutput* output = dispatcher.getOutput();
	if (connectionManager.createConnection(id, key)) {
		output->println(("Connection '" + std::string(id.c_str()) + "' created.").c_str());
	}
	else {
		output->println(("Connection '" + std::string(id.c_str()) + "' already exists.").c_str());
	}
}

void sendCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	String id = String(cmd.arguments[0].values[0].toCString());
	String message = String(cmd.arguments[1].values[0].toCString());
	String outMsg = connectionManager.prepareMessage(id, message);
	output->println(("Sending on connection '" + std::string(id.c_str()) + "': " + std::string(outMsg.c_str())).c_str());
	// Here you would pass outMsg to your MeshManager to transmit.
}

void listConnectionsCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	output->println(connectionManager.listConnections().c_str());
}

void helpCommandCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	dispatcher.printGlobalHelp();
}

void processCommand(const String& cmd) {
	try {
		dispatcher.dispatch(std::string(cmd.c_str()));
	}
	catch (std::exception& ex) {
		CLIOutput* output = dispatcher.getOutput();
		output->println("Error: " + std::string(ex.what()));
		DEBUG_PRINTLN(("Error: " + std::string(ex.what())).c_str());
		rgbFeedback.setAction(ACTION_ERROR);
	}
}

void registerCommands() {
	CLIOutput* output = dispatcher.getOutput();

	Command helpCmd("help", "Displays help information for all commands.");
	helpCmd.addAlias("?");
	helpCmd.callback = helpCommandCallback;
	helpCmd.registerOutput(output);
	dispatcher.registerCommand(helpCmd);

	Command createCmd("create", "Creates a new item");
	createCmd.callback = [] (const Command& cmd) {
		CLIOutput* output = dispatcher.getOutput();
		output->println("Create command executed.");
	};
	createCmd.registerOutput(output);

	Command listCmd("list", "Lists all items");
	listCmd.callback = [] (const Command& cmd) {
		CLIOutput* output = dispatcher.getOutput();
		output->println("List command executed.");
	};
	listCmd.registerOutput(output);

	Command createConnectionCmd("connection", "Creates a new connection");
	createConnectionCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	createConnectionCmd.addArgSpec(ArgSpec("key", VAL_STRING, true, "Connection key"));
	createConnectionCmd.callback = createConnectionCallback;
	createConnectionCmd.registerOutput(output);
	createCmd.addSubcommand(createConnectionCmd);

	Command sendCmd("send", "Send a message on a connection");
	sendCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	sendCmd.addArgSpec(ArgSpec("message", VAL_STRING, true, "Message"));
	sendCmd.callback = sendCallback;
	sendCmd.registerOutput(output);
	dispatcher.registerCommand(sendCmd);

	Command listConnectionsCmd("connections", "Lists all connections");
	listConnectionsCmd.callback = listConnectionsCallback;
	listConnectionsCmd.registerOutput(output);
	listCmd.addSubcommand(listConnectionsCmd);

	dispatcher.registerCommand(createCmd);
	dispatcher.registerCommand(listCmd);
}
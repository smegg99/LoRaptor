// src/managers/commands_manager.cpp
#include "config.h"
#include "managers/commands_manager.h"
#include "managers/connection_manager.h"
#include "RaptorCLI.h"
#include "managers/mesh_manager.h"

#ifdef RGB_FEEDBACK_ENABLED
#include "rgb/rgb_feedback.h"
extern RGBFeedback rgbFeedback;
#endif

extern ConnectionManager connectionManager;
extern Dispatcher dispatcher;
extern MeshManager meshManager;

void createConnectionCallback(const Command& cmd) {
	std::string id(cmd.arguments[0].values[0].toCString());
	std::string key(cmd.arguments[1].values[0].toCString());
	CLIOutput* output = dispatcher.getOutput();
	if (connectionManager.createConnection(id, key)) {
		output->println(("Connection '" + id + "' created.").c_str());
	}
	else {
		output->println(("Connection '" + id + "' already exists.").c_str());
	}
}

void sendCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	// std::string id(cmd.arguments[0].values[0].toCString());
	std::string message(cmd.arguments[0].values[0].toCString());

	std::string outMsg = connectionManager.prepareMessage("global", message);

	output->println(("Sending on global: " + outMsg).c_str());

	meshManager.sendMessage("global", outMsg);
}

void listConnectionsCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	output->println(connectionManager.listConnections().c_str());
}

void listNodesCallback(const Command& cmd) {
	// CLIOutput* output = dispatcher.getOutput();

	meshManager.getConnectedNodes();
}

void helpCommandCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	dispatcher.printGlobalHelp();
}

void processCommand(const std::string& cmd) {
	try {
		dispatcher.dispatch(cmd);
	}
	catch (std::exception& ex) {
		CLIOutput* output = dispatcher.getOutput();
		output->println(("Error: " + std::string(ex.what())).c_str());
		DEBUG_PRINTLN(("Error: " + std::string(ex.what())).c_str());
#ifdef RGB_FEEDBACK_ENABLED
		rgbFeedback.setAction(ACTION_ERROR);
#endif
	}
}

void registerCommands() {
	DEBUG_PRINTLN("Registering commands...");
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
	// sendCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	sendCmd.addArgSpec(ArgSpec("m", VAL_STRING, true, "Message"));
	sendCmd.callback = sendCallback;
	sendCmd.registerOutput(output);
	dispatcher.registerCommand(sendCmd);

	Command listConnectionsCmd("connections", "Lists all connections");
	listConnectionsCmd.callback = listConnectionsCallback;
	listConnectionsCmd.registerOutput(output);
	listCmd.addSubcommand(listConnectionsCmd);

	Command listNodesCmd("nodes", "Lists all nodes");
	listNodesCmd.callback = listNodesCallback;
	listNodesCmd.registerOutput(output);
	listCmd.addSubcommand(listNodesCmd);

	Command pingCmd("ping", "Pings the system to check if it's responsive");
	pingCmd.callback = [] (const Command& cmd) {
		CLIOutput* output = dispatcher.getOutput();
		output->println("pong!");
		};
	pingCmd.registerOutput(output);
	dispatcher.registerCommand(pingCmd);

	dispatcher.registerCommand(createCmd);
	dispatcher.registerCommand(listCmd);

	Command broadcastCmd("broadcast", "Broadcast a message");
	broadcastCmd.addArgSpec(ArgSpec("recipients", VAL_LIST, true, "List of recipients"));
	broadcastCmd.callback = [] (const Command& cmd) {
		DEBUG_PRINTLN("Broadcast command executed");
		for (const auto& arg : cmd.arguments) {
			if (arg.name == "recipients" && !arg.values.empty() && arg.values[0].type == VAL_LIST) {
				std::string recipients;
				for (const auto& r : arg.values[0].listValue) {
					recipients += r.stringValue + " ";
				}
				DEBUG_PRINTLN(recipients.c_str());
			}
		}
		};
	broadcastCmd.registerOutput(output);
	dispatcher.registerCommand(broadcastCmd);

	ExecutableCommand execBroadcast(broadcastCmd, {
		{"recipients", Value(std::vector<Value>{ Value("John"), Value("Ambatukam") })}
		});

	ExecutableCommand sendExecCmd(sendCmd, { {"message", "Hello, World!"} });
	DEBUG_PRINTLN(sendExecCmd.toString().c_str());

	ExecutableCommand createConnectionExecCmd(createConnectionCmd, { {"id", "asdasdas"}, {"key", "true my nigga"} });
	DEBUG_PRINTLN(createConnectionExecCmd.toString().c_str());

	ExecutableCommand listConnectionsExecCmd(listConnectionsCmd, {});
	DEBUG_PRINTLN(listConnectionsExecCmd.toString().c_str());

	ExecutableCommand listNodesExecCmd(listNodesCmd, {});
	DEBUG_PRINTLN(listNodesExecCmd.toString().c_str());

	ExecutableCommand pingExecCmd(pingCmd, {});
	DEBUG_PRINTLN(pingExecCmd.toString().c_str());

	CommandSequence seq;
	seq.addCommand(execBroadcast);
	seq.addCommand(sendExecCmd);
	seq.addCommand(createConnectionExecCmd);
	seq.addCommand(listConnectionsExecCmd);
	seq.addCommand(listNodesExecCmd);
	seq.addCommand(pingExecCmd);

	DEBUG_PRINTLN(seq.toString().c_str());
	DEBUG_PRINTLN(seq.execute());

	DEBUG_PRINTLN("Commands registered");
}

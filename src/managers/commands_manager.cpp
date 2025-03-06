// src/managers/commands_manager.cpp
#include "config.h"
#include "managers/commands_manager.h"
#include "managers/connection_manager.h"
#include "managers/mesh_manager.h"
#include "RaptorCLI.h"

#ifdef RGB_FEEDBACK_ENABLED
#include "rgb/rgb_feedback.h"
extern RGBFeedback rgbFeedback;
#endif

extern ConnectionManager connectionManager;
extern MeshManager meshManager;
extern Dispatcher dispatcher;
extern LoRaMesherComm* loraMesherComm;

ExecutableCommand errExecCmd;
ExecutableCommand returnExecCmd;
ExecutableCommand readyExecCmd;
ExecutableCommand listExecCmd;

void executeReturnCommand(const std::string& value) {
	returnExecCmd.toOutputWithArgs({ {"v", {Value(value)}} });
}

void executeErrorCommand(const std::string& errorMessage) {
	errExecCmd.toOutputWithArgs({ {"m", {Value(errorMessage)}} });
}

void createConnectionCallback(const Command& cmd) {
	std::string id(cmd.arguments[0].values[0].toCString());
	std::string key(cmd.arguments[1].values[0].toCString());
	std::vector<std::uint16_t> recipientIDs;
	Value listVal = cmd.arguments[2].values[0];
	if (listVal.type != VAL_LIST) {
		executeErrorCommand(ERROR_CONN_CANNOT_CREATE);
		return;
	}
	for (const Value& val : listVal.listValue) {
		try {
			std::uint16_t recipientID = static_cast<std::uint16_t>(std::stoi(val.toString()));
			recipientIDs.push_back(recipientID);
			CLIOutput* output = dispatcher.getOutput();
		}
		catch (const std::invalid_argument& e) {
			executeErrorCommand(ERROR_CONN_CANNOT_CREATE);
			return;
		}
		catch (const std::out_of_range& e) {
			executeErrorCommand(ERROR_CONN_CANNOT_CREATE);
			return;
		}
	}
	CLIOutput* output = dispatcher.getOutput();
	if (connectionManager.createConnection(id, key, recipientIDs, loraMesherComm)) {
		executeReturnCommand(MSG_CONN_CREATED);
	}
	else {
		executeErrorCommand(ERROR_CONN_EXISTS);
	}
}

void deleteConnectionCallback(const Command& cmd) {
	std::string id(cmd.arguments[0].values[0].toCString());
	CLIOutput* output = dispatcher.getOutput();
	if (connectionManager.deleteConnection(id)) {
		executeReturnCommand(MSG_CONN_DELETED);
	}
	else {
		executeErrorCommand(ERROR_CONN_NOT_FOUND);
	}
}

void addRecipientCallback(const Command& cmd) {
	std::string connectionID(cmd.arguments[0].values[0].toString());
	uint16_t recipientID = static_cast<uint16_t>(std::stoi(cmd.arguments[1].values[0].toString()));
	Connection* c = connectionManager.getConnection(connectionID);
	if (c == nullptr) {
		executeErrorCommand(ERROR_CONN_NOT_FOUND);
		return;
	}
	c->addRecipient(recipientID);
	executeReturnCommand(MSG_RECIPIENT_ADDED);
}

void removeRecipientCallback(const Command& cmd) {
	std::string connectionID(cmd.arguments[0].values[0].toString());
	uint16_t recipientID = static_cast<uint16_t>(std::stoi(cmd.arguments[1].values[0].toString()));
	Connection* c = connectionManager.getConnection(connectionID);
	if (c == nullptr) {
		executeErrorCommand(ERROR_CONN_NOT_FOUND);
		return;
	}
	c->removeRecipient(recipientID);
	executeReturnCommand(MSG_RECIPIENT_REMOVED);
}

void sendCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	std::string connectionID(cmd.arguments[0].values[0].toString());
	std::string message(cmd.arguments[1].values[0].toString());
	Connection* c = connectionManager.getConnection(connectionID);
	if (c == nullptr) {
		executeReturnCommand(ERROR_CONN_NOT_FOUND);
		return;
	}

	Payload p = c->preparePayload(message);
	if (p.getContent().empty()) {
		executeErrorCommand(ERROR_COMM_FAILED_PREPARE);
		return;
	}

	Message outgoingMsg(message, p.getEpoch(), meshManager.getLocalAddress(), PayloadType::MESSAGE);
	outgoingMsg.encodedContent = p.getContent();
	outgoingMsg.updateLastSentTime(millis());

	c->storeOutgoingMessage(outgoingMsg);
}

void flushCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	std::string connectionID(cmd.arguments[0].values[0].toString());
	Connection* c = connectionManager.getConnection(connectionID);
	if (c == nullptr) {
		executeReturnCommand(ERROR_CONN_NOT_FOUND);
		return;
	}

	std::vector<Message> messages = c->flushIncomingMessages();
	for (const Message& msg : messages) {
		std::string content = msg.getContent();
		output->println(content.c_str());
	}

	Value messagesList;
	messagesList.type = VAL_LIST;

	for (const Message& msg : messages) {
		Value messageData;
		messageData.type = VAL_LIST;

		Value senderValue;
		senderValue.type = VAL_STRING;
		senderValue.stringValue = std::to_string(msg.getSenderNodeID());
		messageData.listValue.push_back(senderValue);

		Value epochValue;
		epochValue.type = VAL_INT;
		epochValue.intValue = msg.getEpoch();
		messageData.listValue.push_back(epochValue);

		Value contentValue;
		contentValue.type = VAL_STRING;
		contentValue.stringValue = msg.getContent();
		messageData.listValue.push_back(contentValue);

		messagesList.listValue.push_back(messageData);
	}

	returnExecCmd.toOutputWithArgs({ {"v", messagesList} });
}

void listConnectionsCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	std::vector<Connection*> connections = connectionManager.getConnections();

	Value connectionsList;
	connectionsList.type = VAL_LIST;

	for (const Connection* conn : connections) {
		Value idValue;
		idValue.type = VAL_STRING;
		idValue.stringValue = conn->getID();
		connectionsList.listValue.push_back(idValue);
	}

	listExecCmd.toOutputWithArgs({ {"v", connectionsList} });
}

void listNodesCallback(const Command& cmd) {
	CLIOutput* output = dispatcher.getOutput();
	std::vector<std::uint16_t> nodes = meshManager.getConnectedNodes();
	for (const uint16_t& node : nodes) {
		output->println(std::to_string(node).c_str());
	}
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
		executeErrorCommand(ERROR_CMD_ERROR);
		DEBUG_PRINTLN(("Error: " + std::string(ex.what())).c_str());
#ifdef RGB_FEEDBACK_ENABLED
		rgbFeedback.setAction(ACTION_ERROR);
#endif
	}
}

void registerCommands() {
	dispatcher.registerErrorCallback([] (const std::string& msg) {
		executeErrorCommand(msg);
		});
	CLIOutput* output = dispatcher.getOutput();

	// --- General Commands ---
	Command helpCmd("help", "Displays help information for all commands.", output, helpCommandCallback);
	helpCmd.addAlias("?");
	dispatcher.registerCommand(helpCmd);

	// --- CRUD Commands ---
	Command createCmd("create", "Creates a new item", output);
	Command updateCmd("update", "Updates an item", output);
	Command deleteCmd("delete", "Deletes an item", output);
	Command listCmd("list", "Lists all items", output);

	// --- Connection Subcommands ---
	Command createConnectionCmd("connection", "Creates a new connection", output, createConnectionCallback);
	createConnectionCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	createConnectionCmd.addArgSpec(ArgSpec("k", VAL_STRING, true, "Connection key"));
	createConnectionCmd.addArgSpec(ArgSpec("r", VAL_LIST, true, "Recipient IDs"));
	createCmd.addSubcommand(createConnectionCmd);

	Command deleteConnectionCmd("connection", "Deletes a connection", output, deleteConnectionCallback);
	deleteConnectionCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	deleteCmd.addSubcommand(deleteConnectionCmd);

	Command addRecipientCmd("connectionRecipient", "Adds a recipient to a connection", output, addRecipientCallback);
	addRecipientCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	addRecipientCmd.addArgSpec(ArgSpec("r", VAL_INT, true, "Recipient ID"));
	createCmd.addSubcommand(addRecipientCmd);

	Command removeRecipientCmd("connectionRecipient", "Removes a recipient from a connection", output, removeRecipientCallback);
	removeRecipientCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	removeRecipientCmd.addArgSpec(ArgSpec("r", VAL_INT, true, "Recipient ID"));
	deleteCmd.addSubcommand(removeRecipientCmd);

	// --- Messaging ---
	Command sendCmd("send", "Send a message on a connection", output, sendCallback);
	sendCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	sendCmd.addArgSpec(ArgSpec("m", VAL_STRING, true, "Message"));
	dispatcher.registerCommand(sendCmd);

	Command flushCmd("flush", "Flushes the message queue", output, flushCallback);
	flushCmd.addArgSpec(ArgSpec("id", VAL_STRING, true, "Connection ID"));
	dispatcher.registerCommand(flushCmd);

	// --- Listing ---
	Command listConnectionsCmd("connections", "Lists all connections", output, listConnectionsCallback);
	listCmd.addSubcommand(listConnectionsCmd);

	Command listNodesCmd("nodes", "Lists all nodes", output, listNodesCallback);
	listCmd.addSubcommand(listNodesCmd);

	// --- Value Commands ---
	Command getCmd("get", "Gets a value", output);
	Command getNodeIDCmd("nodeID", "Gets the node ID", output, [] (const Command& cmd) {
		returnExecCmd.toOutputWithArgs({ {"v", {Value(std::to_string(meshManager.getLocalAddress()))}} });
		});
	getCmd.addSubcommand(getNodeIDCmd);

	Command getRTCTime("rtc", "Gets the RTC time", output, [] (const Command& cmd) {
		struct timeval tv;
		gettimeofday(&tv, NULL);
		returnExecCmd.toOutputWithArgs({ {"v", {Value(std::to_string(tv.tv_sec))}} });
		});
	getCmd.addSubcommand(getRTCTime);

	Command setCmd("set", "Sets a value", output);
	Command setRTCTime("rtc", "Sets the RTC time", output, [] (const Command& cmd) {
		CLIOutput* out = dispatcher.getOutput();
		std::string timeStr = cmd.arguments[0].values[0].toCString();
		std::uint32_t time = std::stoul(timeStr);
		struct timeval tv;
		tv.tv_sec = time;
		tv.tv_usec = 0;

		if (settimeofday(&tv, NULL) < 0) {
			executeErrorCommand(ERROR_RTC_FAILED_SET);
			return;
		}

		executeReturnCommand(MSG_RTC_SET);
		});
	setRTCTime.addArgSpec(ArgSpec("t", VAL_INT, true, "Time in seconds since epoch"));
	setCmd.addSubcommand(setRTCTime);

	// --- Miscellaneous ---
	Command pingCmd("ping", "Pings the system to check if it's responsive", output, [] (const Command& cmd) {
		returnExecCmd.toOutputWithArgs({ {"v", {Value("pong")}} });
		});
	dispatcher.registerCommand(pingCmd);

	// --- Final Registration ---
	dispatcher.registerCommand(createCmd);
	dispatcher.registerCommand(updateCmd);
	dispatcher.registerCommand(deleteCmd);
	dispatcher.registerCommand(listCmd);
	dispatcher.registerCommand(getCmd);
	dispatcher.registerCommand(setCmd);

	// --- Special Executable Commands ---
	Command errCmd("error", "Generates an error", output, [] (const Command& cmd) {
		CLIOutput* out = dispatcher.getOutput();
		out->println(cmd.arguments[0].values[0].toCString());
		});
	errCmd.setVariadic(true);
	errExecCmd = ExecutableCommand(errCmd, { {"m", {Value("")}} });

	Command returnCmd("return", "Returns a value", output, [] (const Command& cmd) {
		CLIOutput* out = dispatcher.getOutput();
		out->println(cmd.arguments[0].values[0].toCString());
		});
	returnCmd.setVariadic(true);
	returnExecCmd = ExecutableCommand(returnCmd, { {"v", {Value("")}} });

	Command readyCmd("ready", "Indicates that the system is ready", output, [] (const Command& cmd) {
		executeReturnCommand("ready");
		});
	readyExecCmd = ExecutableCommand(readyCmd, {});
	listExecCmd = ExecutableCommand(listCmd, {});

	readyExecCmd.execute();
}
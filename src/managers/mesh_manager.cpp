// src/mesh_manager.cpp
#include "managers/mesh_manager.h"
#include "managers/connection_manager.h"
#include "managers/commands_manager.h"
#include "config.h"
#include <Arduino.h>

extern ConnectionManager connectionManager;
extern void executeErrorCommand(const std::string& errorMessage);

MeshManager::MeshManager() {}

void MeshManager::init() {
	DEBUG_PRINTLN("MeshManager initialized");
	// std::vector<uint16_t> recipients = {53052, 16888};
	// connectionManager.createConnection("debug", "debug", recipients, &loraComm);
	loraComm.init();
	loraComm.startReceiveTask();
}

void MeshManager::sendMessage(Connection* connection, const std::string& preparedPayloadContent) {
	DEBUG_PRINTLN("Sending message to recipients...");
	DEBUG_PRINTLN(("Payload size: " + std::to_string(preparedPayloadContent.length()) + " bytes").c_str());
	DEBUG_PRINTLN(("Payload content sample: " + (preparedPayloadContent.length() > 20 ? preparedPayloadContent.substr(0, 20) + "..." : preparedPayloadContent)).c_str());
	DEBUG_PRINTLN(("Sending to " + std::to_string(connection->getRecipients().size()) + " recipients").c_str());
	std::vector<uint16_t> recipients = connection->getRecipients();
	if (recipients.empty()) {
		executeErrorCommand(ERROR_CONN_NO_RECIPIENTS);
		return;
	}
	uint16_t localAddress = loraComm.getRadio().getLocalAddress();
	for (const auto& recipient : recipients) {
		if (recipient != localAddress) {
			loraComm.sendTo(recipient, preparedPayloadContent);
		} else {
			DEBUG_PRINTLN("Ignoring sending to self");
		}
	}
}

std::vector<std::uint16_t> MeshManager::getConnectedNodes() {
	std::vector<std::uint16_t> connectedNodes;
	LoraMesher& radio = loraComm.getRadio();
	LM_LinkedList<RouteNode>* routingTableList = radio.routingTableListCopy();

	routingTableList->setInUse();

	for (int i = 0; i < radio.routingTableSize(); i++) {
		RouteNode* rNode = (*routingTableList)[i];
		NetworkNode node = rNode->networkNode;
		connectedNodes.push_back(node.address);
	}

	routingTableList->releaseInUse();
	delete routingTableList;

	return connectedNodes;
}

uint16_t MeshManager::getLocalAddress() {
	return loraComm.getRadio().getLocalAddress();
}

LoRaMesherComm* MeshManager::getLoRaComm() {
	return &loraComm;
}
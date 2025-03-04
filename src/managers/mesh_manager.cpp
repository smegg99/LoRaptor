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
	loraComm.init();
	loraComm.startReceiveTask();
}

void MeshManager::sendMessage(Connection* connection, const std::string& preparedPayload) {
	std::vector<uint16_t> recipients = connection->getRecipients();
	if (recipients.empty()) {
		executeErrorCommand(ERROR_CONN_NO_RECIPIENTS);
		return;
	}
	for (const auto& recipient : recipients) {
		loraComm.sendTo(recipient, preparedPayload);
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
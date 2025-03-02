// src/mesh_manager.cpp
#include "managers/mesh_manager.h"
#include "config.h"
#include <Arduino.h>

MeshManager::MeshManager() {}

void MeshManager::init() {
	DEBUG_PRINTLN("MeshManager initialized");
	loraComm.init();
	loraComm.startReceiveTask();
}

void MeshManager::sendMessage(const std::string& connectionID, const std::string& payload) {
	loraComm.send(payload);
}

std::vector<std::string> MeshManager::getConnectedNodes() {
	std::vector<std::string> connectedNodes;
	LoraMesher& radio = loraComm.getRadio();
	LM_LinkedList<RouteNode>* routingTableList = radio.routingTableListCopy();

	routingTableList->setInUse();

	char text[15];
	for (int i = 0; i < radio.routingTableSize(); i++) {
		RouteNode* rNode = (*routingTableList)[i];
		NetworkNode node = rNode->networkNode;
		snprintf(text, 15, ("|%X(%d)->%X"), node.address, node.metric, rNode->via);
		DEBUG_PRINTLN(text);
	}

	routingTableList->releaseInUse();
	delete routingTableList;

	return connectedNodes;
}


LoRaMesherComm* MeshManager::getLoRaComm() {
	return &loraComm;
}
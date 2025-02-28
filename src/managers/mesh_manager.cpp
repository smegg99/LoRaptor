// src/mesh_manager.cpp
#include "managers/mesh_manager.h"
#include "config.h"
#include <Arduino.h>

MeshManager::MeshManager() {}

void MeshManager::init() {
	DEBUG_PRINTLN("MeshManager initialized (using LoRaMesher).");
	loraComm.init();
	loraComm.startReceiveTask();
}

void MeshManager::sendMessage(const std::string& connectionID, const std::string& payload) {
	loraComm.send(payload);
}

LoRaMesherComm* MeshManager::getLoRaComm() {
	return &loraComm;
}

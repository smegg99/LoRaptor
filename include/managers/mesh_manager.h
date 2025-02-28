// include/managers/mesh_manager.h
#ifndef MESH_MANAGER_H
#define MESH_MANAGER_H

#include <string>
#include "config.h"
#include "comms/loramesher_comm.h"

class MeshManager {
public:
	MeshManager();
	void init();
	// Send an encrypted message via the mesh network.
	void sendMessage(const std::string& connectionID, const std::string& payload);

	LoRaMesherComm* getLoRaComm();

private:
	LoRaMesherComm loraComm;
};

#endif

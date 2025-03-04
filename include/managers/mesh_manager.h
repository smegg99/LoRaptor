// include/managers/mesh_manager.h
#ifndef MESH_MANAGER_H
#define MESH_MANAGER_H

#include <string>
#include "config.h"
#include "comms/loramesher_comm.h"
#include "objects/connection.h"

class MeshManager {
public:
	MeshManager();
	void init();
	// Send an encrypted message via the mesh network.
	void sendMessage(Connection* connection, const std::string& preparedPayload);

	// Get a list of connected nodes.
	std::vector<std::uint16_t> getConnectedNodes();

	LoRaMesherComm* getLoRaComm();

	// Get the local address of the node.
	uint16_t getLocalAddress();

private:
	LoRaMesherComm loraComm;
};

#endif

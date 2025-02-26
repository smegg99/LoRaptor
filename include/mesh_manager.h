#ifndef MESH_MANAGER_H
#define MESH_MANAGER_H

#include <string>
#include "config.h"

// Stub for MeshManager abstraction.
class MeshManager {
public:
	void init() {
		DEBUG_PRINTLN("MeshManager initialized (stub).");
	}

	void sendMessage(const std::string& connectionID, const std::string& payload) {
		DEBUG_PRINTLN(("MeshManager sending on connection '" + connectionID + "': " + payload).c_str());
	}
};

#endif

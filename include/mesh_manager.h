// include/mesh_manager.h
#ifndef MESH_MANAGER_H
#define MESH_MANAGER_H

#include <Arduino.h>
#include "config.h"

// Stub for MeshManager abstraction.
class MeshManager {
public:
	void init() {
		DEBUG_PRINTLN("MeshManager initialized (stub).");
	}

	void sendMessage(const String& connectionID, const String& payload) {
		DEBUG_PRINTLN("MeshManager sending on connection '" + connectionID + "': " + payload);
	}
};

#endif

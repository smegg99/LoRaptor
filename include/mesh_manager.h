// include/mesh_manager.h
#ifndef MESH_MANAGER_H
#define MESH_MANAGER_H

#include <Arduino.h>

// Stub for MeshManager abstraction.
class MeshManager {
public:
	void init() {
		Serial.println("MeshManager initialized (stub).");
	}

	void sendMessage(const String& connectionID, const String& payload) {
		Serial.println("MeshManager sending on connection '" + connectionID + "': " + payload);
	}
};

#endif

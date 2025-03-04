// src/connection_manager.cpp
#include "managers/connection_manager.h"
#include "config.h"
#include <algorithm>

ConnectionManager::ConnectionManager() {}

bool ConnectionManager::createConnection(const std::string& id, const std::string& key, std::vector<uint16_t>& recipients) {
	if (getConnection(id) != nullptr) return false;
	connections.push_back(new Connection(id, key, recipients));
	return true;
}

bool ConnectionManager::deleteConnection(const std::string& id) {
	for (Connection* conn : connections) {
		if (conn->getID() == id) {
			connections.erase(std::remove(connections.begin(), connections.end(), conn), connections.end());
			delete conn;
			return true;
		}
	}
	return false;
}

std::vector<Connection*> ConnectionManager::getConnections() {
	return connections;
}

Connection* ConnectionManager::getConnection(const std::string id) {
	for (Connection* conn : connections) {
		DEBUG_PRINTLN(("Checking connection: " + conn->getID()).c_str());
		DEBUG_PRINTLN(conn->getID() == id);
		if (conn->getID() == id) return conn;
	}
	return nullptr;
}

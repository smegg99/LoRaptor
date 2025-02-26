// src/connection_manager.cpp
#include "connection_manager.h"

ConnectionManager::ConnectionManager() {}

bool ConnectionManager::createConnection(const std::string& id, const std::string& key) {
	if (getConnection(id) != nullptr) return false;
	connections.push_back(new Connection(id, key));
	return true;
}

std::string ConnectionManager::prepareMessage(const std::string& id, const std::string& message) {
	Connection* conn = getConnection(id);
	if (!conn) return message;
	return conn->encrypt(message);
}

std::string ConnectionManager::processIncoming(const std::string& id, const std::string& encryptedMessage) {
	Connection* conn = getConnection(id);
	if (!conn) return encryptedMessage;
	return conn->decrypt(encryptedMessage);
}

std::string ConnectionManager::listConnections() {
	std::string list = "Connections:\n";
	for (auto conn : connections) {
		list += conn->getID() + " (Key: " + (conn->getKey().length() > 0 ? "set" : "not set") + ")\n";
	}
	return list;
}

Connection* ConnectionManager::getConnection(const std::string& id) {
	for (auto conn : connections) {
		if (conn->getID() == id) return conn;
	}
	return nullptr;
}

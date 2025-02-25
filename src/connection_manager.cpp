// src/connection_manager.cpp
#include "connection_manager.h"

ConnectionManager::ConnectionManager() {}

bool ConnectionManager::createConnection(const String& id, const String& key) {
	if (getConnection(id) != nullptr) return false;
	connections.push_back(new Connection(id, key));
	return true;
}

String ConnectionManager::prepareMessage(const String& id, const String& message) {
	Connection* conn = getConnection(id);
	if (!conn) return message;
	return conn->encrypt(message);
}

String ConnectionManager::processIncoming(const String& id, const String& encryptedMessage) {
	Connection* conn = getConnection(id);
	if (!conn) return encryptedMessage;
	return conn->decrypt(encryptedMessage);
}

String ConnectionManager::listConnections() {
	String list = "Connections:\n";
	for (auto conn : connections) {
		list += conn->getID() + " (Key: " + (conn->getKey().length() > 0 ? "set" : "not set") + ")\n";
	}
	return list;
}

Connection* ConnectionManager::getConnection(const String& id) {
	for (auto conn : connections) {
		if (conn->getID() == id) return conn;
	}
	return nullptr;
}

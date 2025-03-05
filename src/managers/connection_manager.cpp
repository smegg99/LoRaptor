// src/connection_manager.cpp
#include "managers/connection_manager.h"
#include "objects/payload.h"
#include "objects/message.h"
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

void ConnectionManager::processIncomingMessage(const std::string& msg) {
	DEBUG_PRINTLN("Processing incoming message...");
	DEBUG_PRINTLN(("Message size: " + std::to_string(msg.length()) + " bytes").c_str());
	DEBUG_PRINTLN(("Message content sample: " + (msg.length() > 20 ? msg.substr(0, 20) + "..." : msg)).c_str());
	DEBUG_PRINTLN(("Checking against " + std::to_string(connections.size()) + " connections").c_str());
	for (Connection* conn : connections) {
		Payload p(conn->getID());
		if (Payload::decode(msg, conn->getKey(), p)) {
			DEBUG_PRINTLN(("Decrypted message with connection key for connection " + conn->getID()).c_str());
			// TODO: Improve convertion of payloads to messages, add source node ID
			Message m(p.getMessage(), p.getEpoch());

			if (p.getPublicWord() == conn->getID()) {
				conn->storeMessage(m);
			}
			else {
				DEBUG_PRINTLN(("Public word mismatch for connection " + conn->getID() + ": expected " + conn->getID() + ", got " + p.getPublicWord()).c_str());
			}
		}
		else {
			DEBUG_PRINTLN(("Decryption failed for connection " + conn->getID()).c_str());
		}
	}
}
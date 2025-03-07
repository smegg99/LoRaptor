// src/connection_manager.cpp
#include "managers/connection_manager.h"
#include "managers/mesh_manager.h"
#include "objects/payload.h"
#include "objects/message.h"
#include "config.h"
#include <algorithm>

ConnectionManager::ConnectionManager() {}

bool ConnectionManager::createConnection(const std::string& id, const std::string& key, std::vector<uint16_t>& recipients, LoRaMesherComm* comm) {
	if (getConnection(id) != nullptr) return false;
	connections.push_back(new Connection(id, key, recipients, comm));
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
		if (conn->getID() == id) return conn;
	}
	return nullptr;
}

void ConnectionManager::processIncomingMessage(const std::string& msg, const uint16_t senderNodeID) {
	DEBUG_PRINTLN("Processing incoming message...");
	DEBUG_PRINTLN(("Message size: " + std::to_string(msg.length()) + " bytes").c_str());
	DEBUG_PRINTLN(("Message content sample: " + (msg.length() > 20 ? msg.substr(0, 20) + "..." : msg)).c_str());
	DEBUG_PRINTLN(("Checking against " + std::to_string(connections.size()) + " connections").c_str());
	for (Connection* conn : connections) {
		Payload p(conn->getID(), 0, msg);
		if (Payload::decode(msg, conn->getKey(), p)) {
			DEBUG_PRINTLN(("Decrypted message with connection key for connection " + conn->getID()).c_str());
			if (p.getType() == PayloadType::ACK) {
				std::string ackHash = p.getContent();
				conn->acknowledgeMessage(ackHash);
			}
			else {
				Message m(p.getContent(), p.getEpoch(), senderNodeID);
				std::string msgHash = m.getHash();
				conn->storeIncomingMessage(m);
#ifndef DISABLE_CONNECTION_LAYER_ACK
				conn->sendACK(senderNodeID, msgHash);
#endif
			}
		}
		else {
			DEBUG_PRINTLN(("Decryption failed for connection " + conn->getID()).c_str());
		}
	}
}

void ConnectionManager::processOutgoingMessages() {
	uint32_t now = millis();
	for (Connection* conn : connections) {
		if (xSemaphoreTake(conn->getOutgoingMutex(), portMAX_DELAY) == pdTRUE) {
			auto& outgoing = conn->getOutgoingMessages();
			for (auto it = outgoing.begin(); it != outgoing.end(); ) {
				Message& msg = *it;

				if (msg.isAcknowledged()) {
					DEBUG_PRINTLN(("Removing acknowledged message with hash: " + msg.getHash()).c_str());
					it = outgoing.erase(it);
					continue;
				}

				extern MeshManager meshManager;
				bool shouldSend = false;

				if (msg.getRetries() == 0) {
					DEBUG_PRINTLN(("Sending new message with hash: " + msg.getHash()).c_str());
					shouldSend = true;
				}
				else if (now - msg.getLastSentTime() >= RETRY_INTERVAL) {
					if (msg.getRetries() >= MAX_RETRIES) {
						DEBUG_PRINTLN(("Max retries reached for message with hash: " + msg.getHash() + ". Dropping message.").c_str());
						it = outgoing.erase(it);
						continue;
					}
					DEBUG_PRINTLN(("Resending message with hash: " + msg.getHash() + ", retry count: " + std::to_string(msg.getRetries() + 1)).c_str());
					shouldSend = true;
				}

				if (shouldSend) {
					meshManager.sendMessage(conn, msg.encodedContent);
					msg.incrementRetries();
					msg.updateLastSentTime(now);
					vTaskDelay(100 / portTICK_PERIOD_MS);
				}

#ifdef DISABLE_CONNECTION_LAYER_ACK
				if (!msg.isAcknowledged() && msg.getRetries() > 0) {
					msg.markAsAcknowledged();
					DEBUG_PRINTLN(("Auto-acknowledging message (ACK ignored) with hash: " + msg.getHash()).c_str());
				}
#endif

				++it;
			}
			xSemaphoreGive(conn->getOutgoingMutex());
		}
	}
}
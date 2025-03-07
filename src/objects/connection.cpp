// src/connection.cpp
#include "objects/connection.h"
#include "objects/payload.h"
#include "objects/message.h"
#include "managers/connection_manager.h"
#include "config.h"
#include <algorithm>
#include <chrono>
#include <time.h>
#include <LoraMesher.h>

extern ConnectionManager connectionManager;

Connection::Connection(const std::string& id, const std::string& key, std::vector<uint16_t>& recipients, LoRaMesherComm* comm)
	: connectionID(id), key(key), recipients(recipients), comm(comm) {
	outgoingMutex = xSemaphoreCreateMutex();
}

std::string Connection::getID() const {
	return connectionID;
}

std::string Connection::getKey() const {
	return key;
}

Payload Connection::preparePayload(const std::string& message) const {
	DEBUG_PRINTLN(("Preparing message for connection: " + connectionID).c_str());
	time_t now = time(0);
	uint32_t epoch = static_cast<uint32_t>(now);
	Payload p(connectionID, epoch, message);
	std::string encoded;
	if (!p.encode(key, encoded)) {
		return Payload();
	}

	Payload encodedPayload(connectionID, epoch, encoded, PayloadType::MESSAGE);
	DEBUG_PRINTLN("Prepared message successfully");
	DEBUG_PRINTLN(("Payload contents - Connection ID: " + encodedPayload.getPublicWord() +
		", Epoch: " + std::to_string(encodedPayload.getEpoch()) +
		", Message size: " + std::to_string(encoded.size()) + " bytes").c_str());
	return encodedPayload;
}

void Connection::addRecipient(uint16_t recipientID) {
	recipients.push_back(recipientID);
}

void Connection::removeRecipient(uint16_t recipientID) {
	recipients.erase(std::remove(recipients.begin(), recipients.end(), recipientID), recipients.end());
}

std::vector<uint16_t> Connection::getRecipients() const {
	return recipients;
}

void Connection::storeIncomingMessage(const Message& msg) {
	DEBUG_PRINTLN(("Storing incoming message in buffer for connection " + connectionID +
		", time: " + std::to_string(msg.getEpoch()) +
		", sender ID: " + std::to_string(msg.getSenderNodeID()) +
		", message: " + msg.getContent()).c_str());
	if (incomingMessages.size() >= MESSAGE_BUFFER_SIZE) {
		incomingMessages.erase(incomingMessages.begin());
		DEBUG_PRINTLN(("Incoming message buffer full for connection " + connectionID + ". Oldest message removed.").c_str());
	}
	incomingMessages.push_back(msg);
	DEBUG_PRINTLN(("Stored payload in buffer for connection " + connectionID).c_str());
}

void Connection::storeOutgoingMessage(const Message& msg) {
	if (xSemaphoreTake(outgoingMutex, portMAX_DELAY) == pdTRUE) {
		if (outgoingMessages.size() >= MESSAGE_BUFFER_SIZE) {
			outgoingMessages.erase(outgoingMessages.begin());
			DEBUG_PRINTLN(("Outgoing message buffer full for connection " + connectionID + ". Oldest message removed.").c_str());
		}
		outgoingMessages.push_back(msg);
		DEBUG_PRINTLN(("Stored outgoing payload in buffer for connection " + connectionID + ", hash: " + msg.getHash()).c_str());
		xSemaphoreGive(outgoingMutex);
	}
}

void Connection::acknowledgeMessage(const std::string& msgHash) {
	if (xSemaphoreTake(outgoingMutex, portMAX_DELAY) == pdTRUE) {
		for (auto& msg : outgoingMessages) {
			if (!msg.isAcknowledged() && msg.getHash() == msgHash) {
				msg.markAsAcknowledged();
				DEBUG_PRINTLN(("Message acknowledged: " + msgHash).c_str());
			}
		}
		xSemaphoreGive(outgoingMutex);
	}
}

void Connection::sendACK(uint16_t senderNodeID, const std::string& msgHash) {
	time_t now = time(0);
	uint32_t epoch = static_cast<uint32_t>(now);
	Payload ackPayload(connectionID, epoch, msgHash, PayloadType::ACK);
	std::string encodedACK;
	if (!ackPayload.encode(key, encodedACK)) {
		DEBUG_PRINTLN("Failed to encode ACK payload");
		return;
	}
	if (comm) {
		comm->sendTo(senderNodeID, encodedACK);
	}
}

std::vector<Message> Connection::flushIncomingMessages() {
	DEBUG_PRINTLN(("Flushing incoming message buffer for connection " + connectionID + ", messages count: " + std::to_string(incomingMessages.size())).c_str());
	std::vector<Message> flushed = incomingMessages;
	incomingMessages.clear();
	return flushed;
}

LoRaMesherComm* Connection::getComm() const {
	return comm;
}
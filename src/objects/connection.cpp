// src/connection.cpp
#include "objects/connection.h"
#include "objects/payload.h"
#include "objects/message.h"
#include "config.h"
#include <algorithm>
#include <chrono>
#include <time.h>

Connection::Connection(const std::string& id, const std::string& key, std::vector<uint16_t>& recipients)
	: connectionID(id), key(key), recipients(recipients) {
}

std::string Connection::getID() const {
	return connectionID;
}

std::string Connection::getKey() const {
	return key;
}

std::string Connection::prepareMessage(const std::string& message) const {
	DEBUG_PRINTLN(("Preparing message for connection: " + connectionID).c_str());
	Payload p(connectionID, 0, message);
	std::string encoded;
	if (!p.encode(key, encoded)) {
		return "";
	}
	DEBUG_PRINTLN("Prepared message successfully");
	DEBUG_PRINTLN(("Payload contents - Connection ID: " + p.getPublicWord() +
		", Epoch: " + std::to_string(p.getEpoch()) +
		", Message size: " + std::to_string(message.length()) + " bytes").c_str());
	return encoded;
}

std::string Connection::processMessage(const std::string& message) const {
	Payload p;
	if (!Payload::decode(message, key, p)) {
		return "";
	}
	return p.getMessage();
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

void Connection::storeMessage(const Message& msg) {
	DEBUG_PRINTLN(("Storing payload in buffer for connection " + connectionID +
		", time: " + std::to_string(msg.getEpoch()) +
		", message: " + msg.getContent()).c_str());
	if (messageBuffer.size() >= MESSAGE_BUFFER_SIZE) {
		messageBuffer.erase(messageBuffer.begin());
		DEBUG_PRINTLN(("Message buffer full for connection " + connectionID + ". Oldest message removed.").c_str());
	}
	messageBuffer.push_back(msg);
	DEBUG_PRINTLN(("Stored payload in buffer for connection " + connectionID).c_str());
}

std::vector<Message> Connection::flushMessages() {
	DEBUG_PRINTLN(("Flushing message buffer for connection " + connectionID + ", messages count: " + std::to_string(messageBuffer.size())).c_str());
	std::vector<Message> flushed = messageBuffer;
	messageBuffer.clear();
	return flushed;
}
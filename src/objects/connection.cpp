// src/connection.cpp
#include "objects/connection.h"
#include "objects/payload.h"
#include "config.h"
#include <algorithm>
#include <chrono>

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
	Payload p;
	p.publicWord = connectionID;
	p.epoch = std::chrono::duration_cast<std::chrono::seconds>(std::chrono::system_clock::now().time_since_epoch()).count();
	p.message = message;
	std::string encoded;
	if (!p.encode(key, encoded)) {
		return "";
	}
	return encoded;
}

std::string Connection::processMessage(const std::string& message) const {
	Payload p;
	if (!Payload::decode(message, key, p)) {
		return "";
	}
	return p.message;
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
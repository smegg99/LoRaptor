// src/objects/message.cpp
#include "objects/message.h"
#include <cstdio>

Message::Message(const std::string& content, uint32_t epoch, const uint16_t senderNodeID)
	: content(content), epoch(epoch), senderNodeID(senderNodeID) {
}

Message::Message(const std::string& content, uint32_t epoch, const uint16_t senderNodeID, PayloadType type)
	: content(content), epoch(epoch), senderNodeID(senderNodeID), type(type) {
}

Message::Message() : epoch(0), retries(0), acknowledged(false), lastSentTime(0), senderNodeID(0) {}

std::string Message::getHash() const {
	unsigned long hash = 5381;
	// Compute hash on plaintext content plus epoch and sender node ID.
	std::string combined = content + std::to_string(epoch) + std::to_string(senderNodeID);
	for (char c : combined) {
		hash = ((hash << 5) + hash) + c;
	}
	char buf[17];
	snprintf(buf, sizeof(buf), "%016lx", hash);
	return std::string(buf);
}
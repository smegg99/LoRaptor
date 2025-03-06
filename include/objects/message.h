// include/objects/message.h
#ifndef MESSAGE_H
#define MESSAGE_H

#include <string>
#include <cstdint>
#include "config.h"
#include "payload_type.h"

class Message {
public:
	Message(const std::string& content, uint32_t epoch, const uint16_t senderNodeID);
	Message(const std::string& content, uint32_t epoch, const uint16_t senderNodeID, PayloadType type);
	Message();

	std::string getContent() const { return content; } // plaintext message used for hashing
	uint32_t getEpoch() const { return epoch; }
	uint16_t getSenderNodeID() const { return senderNodeID; }
	void markAsAcknowledged() { acknowledged = true; }
	bool isAcknowledged() const { return acknowledged; }
	void incrementRetries() { retries++; }
	uint8_t getRetries() const { return retries; }
	std::string getHash() const;  // returns hash computed on the plaintext (content)
	uint32_t getLastSentTime() const { return lastSentTime; }
	void updateLastSentTime(uint32_t t) { lastSentTime = t; }
	PayloadType getType() const { return type; }

	// The encoded (encrypted/compressed) payload for sending.
	std::string encodedContent;

private:
	std::string content; // plaintext (for hash computation)
	uint32_t epoch;
	uint16_t senderNodeID;
	bool acknowledged = false;
	uint8_t retries = 0;
	uint32_t lastSentTime = 0;
	PayloadType type = PayloadType::MESSAGE;
};

#endif

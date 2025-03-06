// include/objects/connection.h
#ifndef CONNECTION_H
#define CONNECTION_H

#include <string>
#include <vector>
#include "objects/message.h"
#include "objects/payload.h"
#include "comms/loramesher_comm.h"
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

class Connection {
public:
	Connection(const std::string& id, const std::string& key, std::vector<uint16_t>& recipients, LoRaMesherComm* comm);

	std::string getID() const;
	std::string getKey() const;

	// Prepares the payload (now returns an encoded payload for sending)
	Payload preparePayload(const std::string& message) const;

	void addRecipient(uint16_t recipientID);
	void removeRecipient(uint16_t recipientID);
	std::vector<uint16_t> getRecipients() const;

	void storeIncomingMessage(const Message& msg);
	void storeOutgoingMessage(const Message& msg);

	// Mark an outgoing message as acknowledged based on its hash.
	void acknowledgeMessage(const std::string& msgHash);

	// Send an ACK payload back to sender for the given message hash.
	void sendACK(uint16_t senderNodeID, const std::string& msgHash);

	// Flushes (returns and clears) the buffered incoming messages.
	std::vector<Message> flushIncomingMessages();

	LoRaMesherComm* getComm() const;

	std::vector<Message>& getOutgoingMessages() { return outgoingMessages; }
	SemaphoreHandle_t getOutgoingMutex() { return outgoingMutex; }

private:
	std::string connectionID;
	std::string key;
	std::vector<uint16_t> recipients;
	std::vector<Message> incomingMessages;
	std::vector<Message> outgoingMessages;
	LoRaMesherComm* comm;
	SemaphoreHandle_t outgoingMutex; // Protects outgoingMessages
};

#endif

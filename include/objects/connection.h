// include/objects/connection.h
#ifndef CONNECTION_H
#define CONNECTION_H

#include <string>
#include <vector>
#include "objects/message.h"

class Connection {
public:
	Connection(const std::string& id, const std::string& key, std::vector<uint16_t>& recipients);

	std::string getID() const;
	std::string getKey() const;

	std::string prepareMessage(const std::string& message) const;
	std::string processMessage(const std::string& message) const;

	void addRecipient(uint16_t recipientID);
	void removeRecipient(uint16_t recipientID);
	std::vector<uint16_t> getRecipients() const;

	// Stores a message in the buffer (fixed max size 64; oldest removed if full)
	void storeMessage(const Message& msg);
	// Flushes (returns and clears) the buffered messages
	std::vector<Message> flushMessages();
private:
	std::string connectionID;
	std::string key;
	std::vector<uint16_t> recipients;
	std::vector<Message> messageBuffer;
};

#endif

// include/objects/connection.h
#ifndef CONNECTION_H
#define CONNECTION_H

#include <string>
#include <vector>

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

private:
	std::string connectionID;
	std::string key;
	std::vector<uint16_t> recipients;
};

#endif

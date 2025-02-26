// include/connection.h
#ifndef CONNECTION_H
#define CONNECTION_H

#include <string>

class Connection {
public:
	Connection(const std::string& id, const std::string& key);
	std::string getID() const;
	std::string getKey() const;

	std::string encrypt(const std::string& plaintext) const;
	std::string decrypt(const std::string& ciphertext) const;

private:
	std::string connectionID;
	std::string key;
};

#endif

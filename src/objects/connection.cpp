// src/connection.cpp
#include "objects/connection.h"
#include "utils/encryption.h"

Connection::Connection(const std::string& id, const std::string& key)
	: connectionID(id), key(key) {
}

std::string Connection::getID() const {
	return connectionID;
}

std::string Connection::getKey() const {
	return key;
}

std::string Connection::encrypt(const std::string& plaintext) const {
	if (key.empty())
		return plaintext;
	return encryptMessage(key, plaintext);
}

std::string Connection::decrypt(const std::string& ciphertext) const {
	if (key.empty())
		return ciphertext;
	return decryptMessage(key, ciphertext);
}

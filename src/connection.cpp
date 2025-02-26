#include "connection.h"

Connection::Connection(const std::string& id, const std::string& key) : connectionID(id), key(key) {}

std::string Connection::getID() const {
	return connectionID;
}

std::string Connection::getKey() const {
	return key;
}

std::string Connection::encrypt(const std::string& plaintext) const {
	if (key.length() == 0) return plaintext;
	std::string cipher;
	for (int i = plaintext.length() - 1; i >= 0; i--) {
		cipher.push_back(plaintext[i]);
	}
	return cipher;
}

std::string Connection::decrypt(const std::string& ciphertext) const {
	if (key.length() == 0) return ciphertext;
	std::string plain;
	for (int i = ciphertext.length() - 1; i >= 0; i--) {
		plain.push_back(ciphertext[i]);
	}
	return plain;
}

// src/connection.cpp
#include "connection.h"

Connection::Connection(const String& id, const String& key) : connectionID(id), key(key) {}

String Connection::getID() const {
	return connectionID;
}

String Connection::getKey() const {
	return key;
}

String Connection::encrypt(const String& plaintext) const {
	// If no key is set, return plaintext.
	if (key.length() == 0) return plaintext;
	String cipher = "";
	for (int i = plaintext.length() - 1; i >= 0; i--) {
		cipher += plaintext.charAt(i);
	}
	return cipher;
}

String Connection::decrypt(const String& ciphertext) const {
	if (key.length() == 0) return ciphertext;
	String plain = "";
	for (int i = ciphertext.length() - 1; i >= 0; i--) {
		plain += ciphertext.charAt(i);
	}
	return plain;
}

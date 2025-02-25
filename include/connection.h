// include/connection.h
#ifndef CONNECTION_H
#define CONNECTION_H

#include <Arduino.h>

class Connection {
public:
	Connection(const String& id, const String& key);
	String getID() const;
	String getKey() const;

	String encrypt(const String& plaintext) const;
	String decrypt(const String& ciphertext) const;

private:
	String connectionID;
	String key;
};

#endif

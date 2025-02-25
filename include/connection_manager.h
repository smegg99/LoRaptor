// include/connection_manager.h
#ifndef CONNECTION_MANAGER_H
#define CONNECTION_MANAGER_H

#include <Arduino.h>
#include <vector>
#include "connection.h"

class ConnectionManager {
public:
	ConnectionManager();
	bool createConnection(const String& id, const String& key);
	String prepareMessage(const String& id, const String& message);
	String processIncoming(const String& id, const String& encryptedMessage);
	String listConnections();

private:
	std::vector<Connection*> connections;
	Connection* getConnection(const String& id);
};

#endif

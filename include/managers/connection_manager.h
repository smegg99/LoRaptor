// include/managers/connection_manager.h
#ifndef CONNECTION_MANAGER_H
#define CONNECTION_MANAGER_H

#include <string>
#include <vector>
#include "objects/connection.h"

class ConnectionManager {
public:
	ConnectionManager();
	bool createConnection(const std::string& id, const std::string& key);
	std::string prepareMessage(const std::string& id, const std::string& message);
	std::string processIncoming(const std::string& id, const std::string& encryptedMessage);
	std::string listConnections();

private:
	std::vector<Connection*> connections;
	Connection* getConnection(const std::string& id);
};

#endif

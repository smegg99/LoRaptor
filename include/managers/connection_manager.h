// include/managers/connection_manager.h
#ifndef CONNECTION_MANAGER_H
#define CONNECTION_MANAGER_H

#include <string>
#include <vector>
#include "objects/connection.h"

class ConnectionManager {
public:
	ConnectionManager();
	bool createConnection(const std::string& id, const std::string& key, std::vector<uint16_t>& recipients);
	bool deleteConnection(const std::string& id);
	Connection* getConnection(const std::string id);
	std::vector<Connection*> getConnections();
private:
	std::vector<Connection*> connections;
};;

#endif

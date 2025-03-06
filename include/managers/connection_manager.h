// include/managers/connection_manager.h
#ifndef CONNECTION_MANAGER_H
#define CONNECTION_MANAGER_H

#include <string>
#include <vector>
#include "objects/connection.h"
#include "comms/loramesher_comm.h"

class ConnectionManager {
public:
	ConnectionManager();
	bool createConnection(const std::string& id, const std::string& key, std::vector<uint16_t>& recipients, LoRaMesherComm* comm);
	bool deleteConnection(const std::string& id);
	Connection* getConnection(const std::string id);
	std::vector<Connection*> getConnections();

	// Processes an incoming message and forwards it to the correct connection.
	// Processing outgoing messages is done by the connection itself.
	void processIncomingMessage(const std::string& message, const uint16_t senderNodeID);

	// Processes outgoing messages in the buffer for all connections, optionally waiting for acknowledgment.
	void processOutgoingMessages();
private:
	std::vector<Connection*> connections;
};;

#endif

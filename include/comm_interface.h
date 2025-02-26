#ifndef COMM_INTERFACE_H
#define COMM_INTERFACE_H

#include <string>
#include <functional>

class CommunicationInterface {
public:
	typedef std::function<void(const std::string&)> ReceiveCallback;
	typedef std::function<void()> ConnectedCallback;
	typedef std::function<void()> DisconnectedCallback;
	typedef std::function<void()> WaitingForConnectionCallback;

	virtual ~CommunicationInterface() {}

	// Initialize the communication channel.
	virtual void init() = 0;

	// Send data over the channel.
	virtual void send(const std::string& data) = 0;

	// Set the callback that is invoked when data is received.
	virtual void setReceiveCallback(ReceiveCallback callback) = 0;

	// Set the callback that is invoked when a connection is established.
	virtual void setConnectedCallback(ConnectedCallback callback) = 0;

	// Set the callback that is invoked when a connection is lost.
	virtual void setDisconnectedCallback(DisconnectedCallback callback) = 0;

	// Set the callback that is invoked when waiting for a connection.
	virtual void setWaitingForConnectionCallback(WaitingForConnectionCallback callback) = 0;

	virtual void process() {}
};

#endif

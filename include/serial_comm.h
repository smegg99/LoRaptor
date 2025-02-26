#ifndef SERIAL_COMM_H
#define SERIAL_COMM_H

#include "comm_interface.h"
#include <string>

class SerialComm : public CommunicationInterface {
public:
	SerialComm();
	virtual ~SerialComm();

	void init() override;
	void send(const std::string& data) override;
	void setReceiveCallback(ReceiveCallback callback) override;
	void setConnectedCallback(ConnectedCallback callback) override;
	void setDisconnectedCallback(DisconnectedCallback callback) override;
	void setWaitingForConnectionCallback(WaitingForConnectionCallback callback) override;

	void process() override;

private:
	ReceiveCallback _receiveCallback;
	ConnectedCallback _connectedCallback;
	DisconnectedCallback _disconnectedCallback;
	WaitingForConnectionCallback _waitingForConnectionCallback;
};

#endif

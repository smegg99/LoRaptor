// include/comms/serial_comm.h
#ifndef SERIAL_COMM_H
#define SERIAL_COMM_H

#include "interfaces/comm_interface.h"
#include <string>

class SerialComm : public CommunicationInterface {
public:
	SerialComm();
	virtual ~SerialComm();

	virtual void init() override;
	virtual void send(const std::string& data) override;
	virtual void setReceiveCallback(ReceiveCallback callback) override;
	virtual void setConnectedCallback(ConnectedCallback callback) override;
	virtual void setDisconnectedCallback(DisconnectedCallback callback) override;
	virtual void setWaitingForConnectionCallback(WaitingForConnectionCallback callback) override;
	virtual void setTransmittedCallback(TransmittedCallback callback) override;

	void process() override;

private:
	ReceiveCallback _receiveCallback;
	ConnectedCallback _connectedCallback;
	DisconnectedCallback _disconnectedCallback;
	WaitingForConnectionCallback _waitingForConnectionCallback;
	TransmittedCallback _transmittedCallback;
};

#endif

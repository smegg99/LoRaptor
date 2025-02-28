// include/comms/loramesher_comm.h
#ifndef LORAMESHER_COMM_H
#define LORAMESHER_COMM_H

#include "interfaces/comm_interface.h"
#include "config.h"
#include <string>
#include <vector>
#include <algorithm>
#include <LoraMesher.h>

class LoRaMesherComm : public CommunicationInterface {
public:
	LoRaMesherComm();
	virtual ~LoRaMesherComm();

	virtual void init() override;
	virtual void send(const std::string& data) override;
	virtual void setReceiveCallback(ReceiveCallback callback) override;
	virtual void setConnectedCallback(ConnectedCallback callback) override;
	virtual void setDisconnectedCallback(DisconnectedCallback callback) override;
	virtual void setWaitingForConnectionCallback(WaitingForConnectionCallback callback) override;
	virtual void setTransmittedCallback(TransmittedCallback callback) override;
	virtual void process() override;

	LoraMesher& getRadio() { return radio; }
	ReceiveCallback getReceiveCallback() const { return _receiveCallback; }

	void startReceiveTask();

	std::string encryptPayload(const std::string& plaintext);
	std::string decryptPayload(const std::string& ciphertext);
private:
	LoraMesher& radio;
	ReceiveCallback _receiveCallback;
	ConnectedCallback _connectedCallback;
	DisconnectedCallback _disconnectedCallback;
	WaitingForConnectionCallback _waitingForConnectionCallback;
	TransmittedCallback _transmittedCallback;

	uint32_t getTransmitDelay();
};

#endif

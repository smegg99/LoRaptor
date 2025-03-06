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
	typedef std::function<void(const std::string&, const uint16_t)> ReceiveFromCallback;

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
	ReceiveFromCallback getReceiveFromCallback() const { return _receiveFromCallback; }

	void setReceiveFromCallback(ReceiveFromCallback callback) { _receiveFromCallback = callback; }

	void sendTo(uint16_t address, const std::string& data);
	void sendACK(uint16_t address, const std::string& ackPayload);
	void startReceiveTask();
private:
	LoraMesher& radio;
	ReceiveCallback _receiveCallback;
	ReceiveFromCallback _receiveFromCallback;
	ConnectedCallback _connectedCallback;
	DisconnectedCallback _disconnectedCallback;
	WaitingForConnectionCallback _waitingForConnectionCallback;
	TransmittedCallback _transmittedCallback;

	uint32_t getTransmitDelay();
};

#endif

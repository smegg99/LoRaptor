// include/ble_comm.h
#ifndef BLE_COMM_H
#define BLE_COMM_H

#include "comm_interface.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <string>

class BLEComm : public CommunicationInterface {
public:
	BLEComm();
	virtual ~BLEComm();

	virtual void init() override;
	virtual void send(const std::string& data) override;
	virtual void setReceiveCallback(ReceiveCallback callback) override;
	virtual void setConnectedCallback(ConnectedCallback callback) override;
	virtual void setDisconnectedCallback(DisconnectedCallback callback) override;
	virtual void setWaitingForConnectionCallback(WaitingForConnectionCallback callback) override;
	virtual void process() override;

	BLECharacteristic* getCharacteristic();

private:
	BLECharacteristic* pTxCharacteristic;
	ReceiveCallback _receiveCallback;
	ConnectedCallback _connectedCallback;
	DisconnectedCallback _disconnectedCallback;
	WaitingForConnectionCallback _waitingForConnectionCallback;

	class MyBLEServerCallbacks : public BLEServerCallbacks {
	public:
		MyBLEServerCallbacks(BLEComm* parent) : _parent(parent) {}
		void onConnect(BLEServer* pServer) override;
		void onDisconnect(BLEServer* pServer) override;
	private:
		BLEComm* _parent;
	};

	class NUSCallbacks : public BLECharacteristicCallbacks {
	public:
		NUSCallbacks(BLEComm* parent) : _parent(parent) {}
		void onWrite(BLECharacteristic* pCharacteristic) override;
	private:
		BLEComm* _parent;
	};
};

#endif

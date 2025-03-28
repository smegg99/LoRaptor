// src/comms/ble_comm.h
#include "comms/ble_comm.h"
#include "config.h"
#include "managers/mesh_manager.h"
#include <esp_gap_ble_api.h>
#include <functional>

extern MeshManager meshManager;

BLEComm::BLEComm() : pTxCharacteristic(nullptr),
_receiveCallback(nullptr),
_connectedCallback(nullptr),
_disconnectedCallback(nullptr),
_waitingForConnectionCallback(nullptr) {
}

BLEComm::~BLEComm() {}

void BLEComm::init() {
	BLEDevice::init("LoRaptor (" + std::to_string(meshManager.getLocalAddress()) + ")");
	BLEDevice::setMTU(512);

	BLEServer* pServer = BLEDevice::createServer();
	pServer->setCallbacks(new MyBLEServerCallbacks(this));

	// Clear bonded devices for a fresh start.
	int dev_num = esp_ble_get_bond_device_num();
	if (dev_num > 0) {
		esp_ble_bond_dev_t* dev_list = (esp_ble_bond_dev_t*)malloc(sizeof(esp_ble_bond_dev_t) * dev_num);
		if (dev_list) {
			esp_ble_get_bond_device_list(&dev_num, dev_list);
			for (int i = 0; i < dev_num; i++) {
				esp_ble_remove_bond_device(dev_list[i].bd_addr);
			}
			free(dev_list);
		}
	}

	BLEService* pService = pServer->createService(NUS_SERVICE_UUID);
	BLECharacteristic* pRxCharacteristic = pService->createCharacteristic(
		NUS_RX_CHARACTERISTIC_UUID,
		//BLECharacteristic::PROPERTY_WRITE
		BLECharacteristic::PROPERTY_WRITE_NR
	);
	pRxCharacteristic->setCallbacks(new NUSCallbacks(this));

	pTxCharacteristic = pService->createCharacteristic(
		NUS_TX_CHARACTERISTIC_UUID,
		BLECharacteristic::PROPERTY_NOTIFY
	);
	pTxCharacteristic->addDescriptor(new BLE2902());

	pService->start();

	BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
	pAdvertising->addServiceUUID(NUS_SERVICE_UUID);
	pAdvertising->setScanResponse(false);
	pAdvertising->setMinPreferred(0x06);
	pAdvertising->setMinPreferred(0x12);
	BLEDevice::startAdvertising();

	DEBUG_PRINTLN("BLE NUS Service Started!");

	if (_waitingForConnectionCallback) {
		_waitingForConnectionCallback();
	}
}

void BLEComm::send(const std::string& data) {
	if (pTxCharacteristic) {
		DEBUG_PRINTLN(("Sending: " + data).c_str());
		pTxCharacteristic->setValue(data.c_str());
		pTxCharacteristic->notify();

		if (_transmittedCallback) {
			_transmittedCallback(data);
		}
	}
}

void BLEComm::setReceiveCallback(ReceiveCallback callback) {
	_receiveCallback = callback;
}

void BLEComm::setConnectedCallback(ConnectedCallback callback) {
	_connectedCallback = callback;
}

void BLEComm::setDisconnectedCallback(DisconnectedCallback callback) {
	_disconnectedCallback = callback;
}

void BLEComm::setWaitingForConnectionCallback(WaitingForConnectionCallback callback) {
	_waitingForConnectionCallback = callback;
}

void BLEComm::setTransmittedCallback(TransmittedCallback callback) {
	_transmittedCallback = callback;
}

void BLEComm::process() {}

BLECharacteristic* BLEComm::getCharacteristic() {
	return pTxCharacteristic;
}

void BLEComm::MyBLEServerCallbacks::onConnect(BLEServer* pServer) {
	DEBUG_PRINTLN("BLE client connected");
	if (_parent->_connectedCallback) {
		_parent->_connectedCallback();
	}
}

void BLEComm::MyBLEServerCallbacks::onDisconnect(BLEServer* pServer) {
	DEBUG_PRINTLN("BLE client disconnected, restarting advertising");
	pServer->getAdvertising()->start();
	if (_parent->_disconnectedCallback) {
		_parent->_disconnectedCallback();
	}
}

void BLEComm::NUSCallbacks::onWrite(BLECharacteristic* pCharacteristic) {
	std::string rxValue = pCharacteristic->getValue();
	if (!rxValue.empty()) {
		DEBUG_PRINTLN(("Received: " + rxValue).c_str());
		if (_parent->_receiveCallback) {
			_parent->_receiveCallback(rxValue);
		}
	}
}

// src/serial_comm.cpp
#include "serial_comm.h"
#include "config.h"

SerialComm::SerialComm() : _receiveCallback(nullptr) {}
SerialComm::~SerialComm() {}

void SerialComm::init() {
	Serial.begin(115200);
	while (!Serial) {
		vTaskDelay(10 / portTICK_PERIOD_MS);
	}
	DEBUG_PRINTLN("Serial communication initialized");

	if (_connectedCallback) {
		_connectedCallback();
	}
}

void SerialComm::send(const String& data) {
	DEBUG_PRINTLN(data);
}

void SerialComm::setReceiveCallback(ReceiveCallback callback) {
	_receiveCallback = callback;
}

void SerialComm::setConnectedCallback(ConnectedCallback callback) {
	_connectedCallback = callback;
}

void SerialComm::setDisconnectedCallback(DisconnectedCallback callback) {
	_disconnectedCallback = callback;
}

void SerialComm::setWaitingForConnectionCallback(WaitingForConnectionCallback callback) {
	_waitingForConnectionCallback = callback;
}

void SerialComm::process() {
	if (Serial.available() > 0) {
		String received = Serial.readStringUntil('\n');
		if (_receiveCallback) {
			_receiveCallback(received);
		}
		return;
	}
}

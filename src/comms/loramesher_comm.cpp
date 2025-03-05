// src/comms/loramesher_comm.cpp
#include "comms/loramesher_comm.h"
#include "Arduino.h"
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <esp_system.h>

extern SPIClass hspi;

LoRaMesherComm::LoRaMesherComm()
	: radio(LoraMesher::getInstance()),
	_receiveCallback(nullptr),
	_connectedCallback(nullptr),
	_disconnectedCallback(nullptr),
	_waitingForConnectionCallback(nullptr) {
}

LoRaMesherComm::~LoRaMesherComm() {
	radio.standby();
}

void LoRaMesherComm::init() {
	DEBUG_PRINTLN("LoRaMesher: Beginning initialization...");
	LoraMesher::LoraMesherConfig cfg;
	cfg.loraCs = LORA_CS;
	cfg.loraRst = LORA_RST;
	cfg.loraIrq = LORA_DIO0;
	cfg.loraIo1 = LORA_DIO1;
	cfg.freq = 433.0;
	cfg.bw = 125.0;
	cfg.sf = 10;
	cfg.cr = 5;
	cfg.syncWord = 0x12;
	cfg.power = 20;
	cfg.module = LoraMesher::LoraModules::SX1278_MOD;
	cfg.spi = &hspi;

	radio.begin(cfg);
	radio.start();
	DEBUG_PRINTLN("LoRaMesher Service started!");

	if (_connectedCallback) {
		_connectedCallback();
	}
}

void LoRaMesherComm::send(const std::string& data) {
	std::string payload = data;
	std::vector<uint8_t> buffer(payload.begin(), payload.end());
	radio.createPacketAndSend(BROADCAST_ADDR, buffer.data(), static_cast<uint8_t>(buffer.size()));
	DEBUG_PRINTLN(("sent: " + payload + " to: " + std::to_string(BROADCAST_ADDR)).c_str());

	if (_transmittedCallback) {
		_transmittedCallback(payload);
	}
}

void LoRaMesherComm::sendTo(uint16_t address, const std::string& preparedPayload) {
	std::string payload = preparedPayload;
	std::vector<uint8_t> buffer(payload.begin(), payload.end());

	radio.sendReliablePacket(address, buffer.data(), static_cast<uint32_t>(buffer.size()));
	DEBUG_PRINTLN(("sent: " + payload + " to: " + std::to_string(address)).c_str());

	if (_transmittedCallback) {
		_transmittedCallback(payload);
	}
}

void LoRaMesherComm::setReceiveCallback(ReceiveCallback callback) {
	_receiveCallback = callback;
}

void LoRaMesherComm::setConnectedCallback(ConnectedCallback callback) {
	_connectedCallback = callback;
}

void LoRaMesherComm::setDisconnectedCallback(DisconnectedCallback callback) {
	_disconnectedCallback = callback;
}

void LoRaMesherComm::setWaitingForConnectionCallback(WaitingForConnectionCallback callback) {
	_waitingForConnectionCallback = callback;
}

void LoRaMesherComm::setTransmittedCallback(TransmittedCallback callback) {
	_transmittedCallback = callback;
}

static void processReceivedPacketsTask(void* parameter) {
	LoRaMesherComm* comm = reinterpret_cast<LoRaMesherComm*>(parameter);
	for (;;) {
		ulTaskNotifyTake(pdPASS, portMAX_DELAY);

		while (comm->getRadio().getReceivedQueueSize() > 0) {
			AppPacket<uint8_t>* packet = comm->getRadio().getNextAppPacket<uint8_t>();
			if (packet != nullptr) {
				std::string received(reinterpret_cast<const char*>(packet->payload), packet->getPayloadLength());
				std::string plaintext = received;
				DEBUG_PRINTLN(("LoRaMesher received: " + plaintext).c_str());
				if (comm->getReceiveCallback()) {
					comm->getReceiveCallback()(plaintext);
				}
				comm->getRadio().deletePacket(packet);
			}
		}
	}
}

void LoRaMesherComm::startReceiveTask() {
	TaskHandle_t handle = NULL;
	int res = xTaskCreate(processReceivedPacketsTask, "LoRaRxTask", 8192, this, 1, &handle);
	if (res != pdPASS) {
		DEBUG_PRINTLN("Failed to create LoRa receive task");
	}
	else {
		radio.setReceiveAppDataTaskHandle(handle);
	}
}

uint32_t LoRaMesherComm::getTransmitDelay() {
	uint64_t chipId = ESP.getEfuseMac();
	return static_cast<uint32_t>(chipId % 100);
}

void LoRaMesherComm::process() {}
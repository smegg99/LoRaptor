// src/main.cpp
#include <Arduino.h>
#include "driver/gpio.h"
#include "config.h"

#ifdef USE_SERIAL_COMM
#include "comms/serial_comm.h"
#else
#include "comms/ble_comm.h"
#include "interfaces/ble_output.h"
#endif

#include "interfaces/comm_interface.h"
#include "managers/commands_manager.h"
#include "RaptorCLI.h"
#include "managers/connection_manager.h"
#include "managers/mesh_manager.h"

#ifdef RGB_FEEDBACK_ENABLED
#include "rgb/rgb_feedback.h"
RGBFeedback rgbFeedback;
#endif

SPIClass hspi(HSPI);

ConnectionManager connectionManager;
Dispatcher dispatcher;
MeshManager meshManager;
CommunicationInterface* commChannel = nullptr;
LoRaMesherComm* loraMesherComm = nullptr;
QueueHandle_t commandQueue = NULL;

void enqueueGlobalCommand(const std::string& cmd) {
	if (commandQueue != NULL) {
		if (xQueueSend(commandQueue, &cmd, 0) == pdPASS) {
			// DEBUG_PRINTLN(cmd.c_str());
		}
		else {
			DEBUG_PRINTLN("Global queue: Failed to enqueue command");
		}
	}
	else {
		DEBUG_PRINTLN("Global queue not created!");
	}
}

#ifdef RGB_FEEDBACK_ENABLED
void rgbTask(void* parameter) {
	for (;;) {
		rgbFeedback.update();
		vTaskDelay(50 / portTICK_PERIOD_MS);
	}
}
#endif

void commandProcessingTask(void* param) {
	std::string cmd;
	for (;;) {
		if (xQueueReceive(commandQueue, &cmd, portMAX_DELAY) == pdPASS) {
			processCommand(cmd);
		}
	}
}

void commProcessTask(void* parameter) {
	for (;;) {
		commChannel->process();
		vTaskDelay(100 / portTICK_PERIOD_MS);
	}
}

void outgoingMessageTask(void* parameter) {
	for (;;) {
		connectionManager.processOutgoingMessages();
		vTaskDelay(100 / portTICK_PERIOD_MS);
	}
}

void onReceiveCallback(const std::string& cmd) {
	DEBUG_PRINTLN("Received command: " + String(cmd.c_str()));
	enqueueGlobalCommand(cmd);
}

void onConnectedCallback() {
	DEBUG_PRINTLN("Connected to communication channel");
#ifdef RGB_FEEDBACK_ENABLED
	rgbFeedback.setAction(ACTION_COMM_CONNECTED);
#endif
}

void onDisconnectedCallback() {
	DEBUG_PRINTLN("Disconnected from communication channel");
#ifdef RGB_FEEDBACK_ENABLED
	rgbFeedback.setAction(ACTION_COMM_DISCONNECTED);
#endif
}

void onWaitingForConnectionCallback() {
	DEBUG_PRINTLN("Waiting for connection to communication channel...");
#ifdef RGB_FEEDBACK_ENABLED
	rgbFeedback.setAction(ACTION_COMM_WAITING);
#endif
}

void onLoRaConnectedCallback() {
	rgbFeedback.setAction(ACTION_MESH_ACTIVE);
}

void onLoRaReceiveFromCallback(const std::string& msg, const uint16_t senderNodeID) {
	DEBUG_PRINTLN("Received LoRa message: " + String(msg.c_str()) + " from node " + String(senderNodeID));
	connectionManager.processIncomingMessage(msg, senderNodeID);
	rgbFeedback.enqueueAction(ACTION_COMM_RECEIVED);
}

void onLoRaTransmittedCallback(const std::string& msg) {
	rgbFeedback.enqueueAction(ACTION_COMM_TRANSMITTED);
}

void setup() {
#ifndef USE_SERIAL_COMM
	Serial.begin(SERIAL_BAUD_RATE);
	while (!Serial) {
		vTaskDelay(10 / portTICK_PERIOD_MS);
	}
	static BLEComm bleComm;
	commChannel = &bleComm;
#else
	static SerialComm serialComm;
	commChannel = &serialComm;
#endif

	esp_err_t err = gpio_install_isr_service(ESP_INTR_FLAG_DEFAULT);
	if (err == ESP_ERR_INVALID_STATE) {
		DEBUG_PRINTLN("Failed to install GPIO ISR service: " + String(err));
		rgbFeedback.setAction(ACTION_ERROR);
		esp_restart();
	}

	hspi.begin(LORA_SCK, LORA_MISO, LORA_MOSI, LORA_CS);

#ifdef RGB_FEEDBACK_ENABLED
	rgbFeedback.begin();
	xTaskCreate(rgbTask, "RGBTask", 2048, NULL, 1, NULL);
#endif

	commandQueue = xQueueCreate(COMMANDS_QUEUE_LENGTH, sizeof(std::string));
	if (commandQueue == NULL) {
		DEBUG_PRINTLN("Failed to create global command queue!");
	}
	else {
		DEBUG_PRINTLN("Global command queue created");
	}

	commChannel->setReceiveCallback(onReceiveCallback);
	commChannel->setConnectedCallback(onConnectedCallback);
	commChannel->setDisconnectedCallback(onDisconnectedCallback);
	commChannel->setWaitingForConnectionCallback(onWaitingForConnectionCallback);
	commChannel->init();

#ifdef USE_SERIAL_COMM
	ArduinoCLIOutput serialOutput;
	dispatcher.registerOutput(&serialOutput);
#else
	BLECLIOutput bleOutput((BLEComm*)commChannel);
	dispatcher.registerOutput(&bleOutput);
#endif

	loraMesherComm = meshManager.getLoRaComm();
	loraMesherComm->setConnectedCallback(onLoRaConnectedCallback);
	loraMesherComm->setReceiveFromCallback(onLoRaReceiveFromCallback);
	loraMesherComm->setTransmittedCallback(onLoRaTransmittedCallback);
	meshManager.init();

	registerCommands();

	xTaskCreate(commandProcessingTask, "CommandProcessingTask", 32768, NULL, 1, NULL);
	xTaskCreate(commProcessTask, "CommProcessTask", 32768, NULL, 1, NULL);
	xTaskCreate(outgoingMessageTask, "OutgoingMessageTask", 32768, NULL, 1, NULL);
}

void loop() {
	vTaskDelay(100 / portTICK_PERIOD_MS);
}

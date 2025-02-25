#include <Arduino.h>
#include "config.h"

#ifdef USE_SERIAL_COMM
#include "serial_comm.h"
#else
#include "ble_comm.h"
#include "ble_output.h"
#endif

#include "comm_interface.h"
#include "commands.h"
#include "RaptorCLI.h"
#include "connection_manager.h"
#include "mesh_manager.h"

#ifdef RGB_FEEDBACK_ENABLED
#include "rgb_feedback.h"
RGBFeedback rgbFeedback;
#endif

ConnectionManager connectionManager;
Dispatcher dispatcher;
MeshManager meshManager;
CommunicationInterface* commChannel = nullptr;

#ifdef RGB_FEEDBACK_ENABLED
void rgbTask(void* parameter) {
	for (;;) {
		rgbFeedback.update();
		vTaskDelay(10 / portTICK_PERIOD_MS);
	}
}
#endif

#ifndef USE_SERIAL_COMM
void commandProcessingTask(void* param) {
	BLEComm* bleComm = (BLEComm*)param;
	String cmd;
	for (;;) {
		if (bleComm->dequeueCommand(cmd)) {
			processCommand(cmd);
		}
		vTaskDelay(10 / portTICK_PERIOD_MS);
	}
}
#endif

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

	registerCommands();

#ifdef RGB_FEEDBACK_ENABLED
	rgbFeedback.begin();
	xTaskCreate(rgbTask, "RGBTask", 2048, NULL, 1, NULL);
#endif

	commChannel->init();

#ifdef USE_SERIAL_COMM
	ArduinoCLIOutput serialOutput;
	dispatcher.registerOutput(&serialOutput);
#else
	BLECLIOutput bleOutput((BLEComm*)commChannel);
	dispatcher.registerOutput(&bleOutput);
#endif

	commChannel->setConnectedCallback([] () {
		Serial.println("Connected to communication channel.");
#ifdef RGB_FEEDBACK_ENABLED
		rgbFeedback.setAction(ACTION_COMM_CONNECTED);
#endif
		});
	commChannel->setDisconnectedCallback([] () {
		Serial.println("Disconnected from communication channel.");
#ifdef RGB_FEEDBACK_ENABLED
		rgbFeedback.setAction(ACTION_COMM_DISCONNECTED);
#endif
		});
	commChannel->setWaitingForConnectionCallback([] () {
		Serial.println("Waiting for connection to communication channel...");
#ifdef RGB_FEEDBACK_ENABLED
		rgbFeedback.setAction(ACTION_COMM_WAITING);
#endif
		});

	meshManager.init();

#ifndef USE_SERIAL_COMM
	xTaskCreate(commandProcessingTask, "CommandProcessingTask", 8192, commChannel, 1, NULL);
#endif
}

void loop() {
	vTaskDelay(100 / portTICK_PERIOD_MS);
}
// include/config.h
#ifndef CONFIG_H
#define CONFIG_H

#define DEBUG_MODE
#ifdef DEBUG_MODE
#include <Arduino.h>
#define DEBUG_PRINT(x) Serial.print(x)
#define DEBUG_PRINTF(x, ...) Serial.printf(x, __VA_ARGS__)
#define DEBUG_PRINTLN(x) Serial.println(x)
#else
#define DEBUG_PRINT(x)
#define DEBUG_PRINTF(x, ...)
#define DEBUG_PRINTLN(x)
#endif

#ifndef ESP_INTR_FLAG_DEFAULT
#define ESP_INTR_FLAG_DEFAULT 0
#endif

#define COMMANDS_QUEUE_LENGTH 10

#define DEVICE_NAME "LoRaptor"

#define NUS_SERVICE_UUID           "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define NUS_RX_CHARACTERISTIC_UUID "6E400002-B5A3-F393-E0A9-E50E24DCCA9E" // Client -> Device
#define NUS_TX_CHARACTERISTIC_UUID "6E400003-B5A3-F393-E0A9-E50E24DCCA9E" // Device -> Client

#define RESERVED_COMMAND_PREFIX "/"

#define RGB_FEEDBACK_ENABLED
#ifdef RGB_FEEDBACK_ENABLED
#define COMMON_ANODE
#define RGB_R_PIN 34
#define RGB_G_PIN 33
#define RGB_B_PIN 21
#endif

#define USE_SERIAL_COMM
#define SERIAL_BAUD_RATE 115200

#define LORA_MISO 12
#define LORA_MOSI 13
#define LORA_SCK  14
#define LORA_CS   15
#define LORA_RST  16
#define LORA_DIO0 10
#define LORA_DIO1 11
#define LORA_DIO2 17
#define LORA_DIO3 18
#define LORA_DIO4 35
#define LORA_DIO5 36

#endif

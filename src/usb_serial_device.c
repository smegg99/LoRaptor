#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "tinyusb.h"
#include "class/cdc/cdc_device.h"

#define TAG "USB_SERIAL"

#define USB_VID 0x303A  // Espressif Vendor ID
#define USB_PID 0x1001  // Custom Product ID
#define USB_MANUFACTURER "ESP32-S3"
#define USB_PRODUCT "USB Serial Device"
#define USB_SERIAL "12345678"

// USB Task
static void usb_task(void *arg);

// Callback for incoming USB data
void tud_cdc_rx_cb(uint8_t itf) {
    uint8_t buf[64];
    uint32_t count = tud_cdc_n_read(itf, buf, sizeof(buf));

    if (count > 0) {
        tud_cdc_n_write(itf, buf, count);  // Echo back
        tud_cdc_n_write_flush(itf);
    }
}

void app_main(void) {
    ESP_LOGI(TAG, "Initializing TinyUSB CDC");

    const tinyusb_config_t tusb_cfg = {
        .descriptor = NULL, // Use default descriptor
        .string_descriptor = NULL,
        .external_phy = false
    };

    ESP_ERROR_CHECK(tinyusb_driver_install(&tusb_cfg));

    xTaskCreate(usb_task, "usb_task", 4096, NULL, 5, NULL);
}

// USB Task Loop
static void usb_task(void *arg) {
    while (1) {
        tud_task();  // TinyUSB task
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

// Custom USB Device Descriptors
const char *tud_descriptor_string_cb(uint8_t index, uint16_t langid) {
    static char desc_str[32];

    switch (index) {
        case 0: return "\x09\x04";  // English (US)
        case 1: return USB_MANUFACTURER;
        case 2: return USB_PRODUCT;
        case 3: return USB_SERIAL;
        default:
            snprintf(desc_str, sizeof(desc_str), "Unknown %d", index);
            return desc_str;
    }
}

uint16_t tud_descriptor_device_cb(void) {
    return USB_VID;
}

uint16_t tud_descriptor_product_cb(void) {
    return USB_PID;
}

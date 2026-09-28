---
name: esp32-embedded-patterns
description: Production-grade ESP32 embedded systems and IoT engineering patterns using PlatformIO, Arduino C++, FreeRTOS multi-core tasks, AsyncWebServer config dashboard, Web OTA (ElegantOTA), LittleFS, and hardware safety guardrails. Use when developing, reviewing, or debugging ESP32 firmware, IoT devices, sensors, or embedded C++ code.
---

# ESP32 Embedded Systems & IoT Engineering Patterns (`esp32-embedded-patterns`)

This skill outlines production-grade architecture, hardware guardrails, and coding patterns for ESP32 family microcontrollers (ESP32 classic, S3, C3, C6) using **PlatformIO**, the **Arduino Framework (C++)**, **FreeRTOS**, and an **onboard Web Config & Web OTA interface**.

---

## 1. Golden Rules of ESP32 Development

1. **Strict NO `delay()` Policy**:
   - Never use `delay()` in production code. It blocks the CPU core and starves the FreeRTOS scheduler / Watchdog.
   - Always use `vTaskDelay(pdMS_TO_TICKS(ms))` inside FreeRTOS tasks, or non-blocking timer checks (`millis()`).
2. **Web Config Dashboard over Hardcoding**:
   - Never force a reflash to change settings. Provide an onboard web dashboard with REST API endpoints (`/api/config`) that persist runtime parameters to **NVS (`Preferences.h`)** or **`LittleFS`**.
3. **Web Browser OTA First**:
   - Include web-based OTA (`ElegantOTA` or `/update` handler) so firmware and filesystem binaries can be updated over Wi-Fi without needing a USB cable.
4. **FreeRTOS Core Pinning**:
   - **Core 0**: Protocol & Networking tasks (Wi-Fi reconnection, MQTT loop, AsyncWebServer, ElegantOTA).
   - **Core 1**: Real-time sensor sampling, hardware peripherals, and fast control loops.
5. **Thread-Safe Inter-Task Communication**:
   - Pass telemetry data across tasks using **FreeRTOS Queues (`QueueHandle_t`)**.
   - Protect shared hardware buses (I2C, SPI) or shared global state using **Mutexes (`SemaphoreHandle_t`)**.
6. **Network Resilience & Offline Ring Buffer**:
   - Never hang if Wi-Fi or MQTT goes down. Implement non-blocking reconnection with exponential backoff and buffer telemetry in a RAM ring buffer so readings are not lost while offline.
7. **Tagged Logging**:
   - Use ESP-IDF logging macros (`ESP_LOGI`, `ESP_LOGW`, `ESP_LOGE`, `ESP_LOGD`) with module tags instead of plain `Serial.print`.

---

## 2. Hardware Safety & Anti-Bricking Guardrails

Before assigning or wiring GPIOs, enforce these hardware checks to avoid hardware damage, boot failures, or brownouts:

| Issue / Trap | Affected Pins | Cause & Rule |
| :--- | :--- | :--- |
| **Flash Voltage Trap (MTDI)** | **GPIO 12** (ESP32) | MTDI is a strapping pin. If driven **HIGH** during boot, flash voltage switches to 1.8V instead of 3.3V, causing a boot loop or bricking. **Enforce "Do Not Use" or strictly pull down.** |
| **ADC2 / Wi-Fi Conflict** | **GPIO 0, 2, 4, 12-15, 25-27** (ADC2 channels) | ADC2 is shared with the Wi-Fi subsystem. Reading ADC2 while Wi-Fi is active will fail or return invalid values. **Always use ADC1 (GPIOs 32-39 on ESP32) for analog sensors when Wi-Fi is enabled.** |
| **Input-Only Pins (GPI)** | **GPIO 34, 35, 36, 39** (ESP32) | These pins lack internal pull-up/pull-down resistors and output driver circuitry. They can **only** be inputs and require external pull resistors if used with switches. |
| **Strapping Pins (Boot Modes)** | **GPIO 0, 2, 5, 12, 15** | Driving these pins HIGH/LOW during power-on changes boot modes (e.g. UART download mode, ROM log output). Avoid connecting peripherals that pull them unexpectedly at boot. |
| **Flash / SPI Bus Pins** | **GPIO 6 to 11** | Connected internally to SPI Flash memory. **Never use or remap GPIO 6–11.** |

---

## 3. Standard PlatformIO Configuration (`platformio.ini`)

Always configure `platformio.ini` with LittleFS, modern dependency pins, and required build flags:

```ini
[env:esp32dev]
platform = espressif32
board = esp32dev
framework = arduino
monitor_speed = 115200
board_build.filesystem = littlefs

; Build flags for AsyncWebServer, ElegantOTA, and ESP logging
build_flags = 
    -D ELEGANTOTA_USE_ASYNC_WEBSERVER=1
    -D CORE_DEBUG_LEVEL=3               ; 0: None, 1: Error, 2: Warn, 3: Info, 4: Debug
    -D ARDUINOJSON_USE_DOUBLE=0          ; Optimize memory on embedded
    -D CONFIG_LITTLEFS_FOR_IDF_3_2

lib_deps = 
    https://github.com/me-no-dev/ESPAsyncWebServer.git
    me-no-dev/AsyncTCP
    ayushsharma82/ElegantOTA @ ^4.0.0
    bblanchon/ArduinoJson @ ^7.0.0
    knolleary/PubSubClient @ ^2.8
```

---

## 4. FreeRTOS Dual-Core Architecture Template

Structure multi-core tasks cleanly to prevent watchdogs, jitter, and memory fragmentation:

```cpp
#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <freertos/queue.h>
#include <freertos/semphr.h>
#include "esp_log.h"

static const char* TAG = "MAIN_APP";

// Telemetry payload struct
struct SensorData {
    float temperature;
    float humidity;
    uint32_t timestamp;
};

// Inter-task queue and bus mutex
QueueHandle_t telemetryQueue;
SemaphoreHandle_t i2cMutex;

// Core 1 Task: High-priority Sensor Reading & Actuators
void sensorTask(void* parameter) {
    ESP_LOGI(TAG, "Sensor task started on Core %d", xPortGetCoreID());
    TickType_t xLastWakeTime = xTaskGetTickCount();
    const TickType_t xFrequency = pdMS_TO_TICKS(1000); // 1 Hz sample rate

    for (;;) {
        vTaskDelayUntil(&xLastWakeTime, xFrequency);

        SensorData data;
        data.timestamp = millis();

        // Lock I2C bus before reading
        if (xSemaphoreTake(i2cMutex, pdMS_TO_TICKS(100)) == pdTRUE) {
            // Read hardware sensor (e.g., BME280 / SHT31)
            data.temperature = 25.4f; // example reading
            data.humidity = 60.2f;
            xSemaphoreGive(i2cMutex);

            // Send to network queue without blocking if full
            if (xQueueSend(telemetryQueue, &data, 0) != pdPASS) {
                ESP_LOGW(TAG, "Telemetry queue full! Dropping sample or queuing to ring buffer");
            }
        } else {
            ESP_LOGE(TAG, "Failed to obtain I2C mutex within timeout");
        }
    }
}

// Core 0 Task: Network, MQTT, and Web Services
void networkTask(void* parameter) {
    ESP_LOGI(TAG, "Network task started on Core %d", xPortGetCoreID());
    SensorData receivedData;

    for (;;) {
        // Wait for telemetry data from Core 1
        if (xQueueReceive(telemetryQueue, &receivedData, pdMS_TO_TICKS(100)) == pdPASS) {
            ESP_LOGI(TAG, "Publishing: Temp=%.2fC, Hum=%.2f%%", 
                     receivedData.temperature, receivedData.humidity);
            // Publish to MQTT if connected, else push to offline ring buffer
        }

        // Process network keep-alives
        // ElegantOTA and AsyncWebServer are handled automatically by async callbacks
        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

void setup() {
    Serial.begin(115200);
    telemetryQueue = xQueueCreate(20, sizeof(SensorData));
    i2cMutex = xSemaphoreCreateMutex();

    // Spawn Core 1 Task (Real-Time Control)
    xTaskCreatePinnedToCore(
        sensorTask, "SensorTask", 4096, NULL, 2, NULL, 1
    );

    // Spawn Core 0 Task (Networking & Web)
    xTaskCreatePinnedToCore(
        networkTask, "NetworkTask", 8192, NULL, 1, NULL, 0
    );
}

void loop() {
    // Arduino loop remains idle or handles minimal housekeeping
    vTaskDelay(pdMS_TO_TICKS(1000));
}
```

---

## 5. Web Config Dashboard & Web OTA Architecture

Provide an onboard web interface that allows users to adjust device configurations and upload firmware updates directly from a web browser.

### A. SvelteKit Static WebUI (`@sveltejs/adapter-static`)
Build the WebUI using **SvelteKit + Svelte 5 runes** inside a `webui/` folder, compiled into static, pre-compressed `.gz` files that export directly to PlatformIO's `data/www/` for LittleFS:

#### 1. SvelteKit Setup (`webui/svelte.config.js`)
```javascript
import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
    preprocess: vitePreprocess(),
    kit: {
        adapter: adapter({
            pages: '../data/www',
            assets: '../data/www',
            fallback: 'index.html',
            precompress: true // Generates .gz files (<20KB total bundle!)
        })
    }
};

export default config;
```

#### 2. SPA & Prerender Mode (`webui/src/routes/+layout.ts`)
```typescript
export const prerender = true;
export const ssr = false; // Pure Single-Page App for microcontroller serving
```

#### 3. Local Development Proxy (`webui/vite.config.ts`)
Develop with Hot Module Reloading (`pnpm dev`) by proxying API calls to the ESP32:
```typescript
import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
    plugins: [sveltekit()],
    server: {
        proxy: {
            '/api': 'http://192.168.4.1' // Or your device's LAN IP
        }
    }
});
```

### B. Non-Volatile Configuration Manager (`Preferences.h`)
```cpp
#include <Preferences.h>

Preferences prefs;

struct AppConfig {
    char deviceName[32];
    char mqttBroker[64];
    int  mqttPort;
    char mqttTopic[64];
    int  sampleIntervalMs;
};

AppConfig config;

void loadConfig() {
    prefs.begin("app-cfg", true); // read-only
    prefs.getString("dev_name", config.deviceName, sizeof(config.deviceName));
    prefs.getString("mqtt_host", config.mqttBroker, sizeof(config.mqttBroker));
    config.mqttPort = prefs.getInt("mqtt_port", 1883);
    prefs.getString("mqtt_topic", config.mqttTopic, sizeof(config.mqttTopic));
    config.sampleIntervalMs = prefs.getInt("sample_ms", 5000);
    prefs.end();
}

void saveConfig(const AppConfig& newCfg) {
    prefs.begin("app-cfg", false); // read-write
    prefs.putString("dev_name", newCfg.deviceName);
    prefs.putString("mqtt_host", newCfg.mqttBroker);
    prefs.putInt("mqtt_port", newCfg.mqttPort);
    prefs.putString("mqtt_topic", newCfg.mqttTopic);
    prefs.putInt("sample_ms", newCfg.sampleIntervalMs);
    prefs.end();
}
```

### C. AsyncWebServer & ElegantOTA Setup (`server.cpp`)
```cpp
#include <ESPAsyncWebServer.h>
#include <ElegantOTA.h>
#include <LittleFS.h>
#include <ArduinoJson.h>

AsyncWebServer server(80);

void initWebServer() {
    if (!LittleFS.begin(true)) {
        ESP_LOGE("FS", "Failed to mount LittleFS");
    }

    // Serve SvelteKit static assets from LittleFS (automatically handles .gz compressed assets)
    server.serveStatic("/", LittleFS, "/www/")
          .setDefaultFile("index.html")
          .setCacheControl("max-age=600");

    // REST API: GET Device Status
    server.on("/api/status", HTTP_GET, [](AsyncWebServerRequest* request) {
        JsonDocument doc;
        doc["uptime_sec"] = millis() / 1000;
        doc["free_heap"] = ESP.getFreeHeap();
        doc["rssi"] = WiFi.RSSI();
        doc["wifi_connected"] = WiFi.isConnected();

        String response;
        serializeJson(doc, response);
        request->send(200, "application/json", response);
    });

    // REST API: GET Configuration
    server.on("/api/config", HTTP_GET, [](AsyncWebServerRequest* request) {
        JsonDocument doc;
        doc["device_name"] = config.deviceName;
        doc["mqtt_broker"] = config.mqttBroker;
        doc["mqtt_port"] = config.mqttPort;
        doc["mqtt_topic"] = config.mqttTopic;
        doc["sample_ms"] = config.sampleIntervalMs;

        String response;
        serializeJson(doc, response);
        request->send(200, "application/json", response);
    });

    // REST API: POST Update Configuration (No reflash needed!)
    server.on("/api/config", HTTP_POST, [](AsyncWebServerRequest* request) {}, NULL,
        [](AsyncWebServerRequest* request, uint8_t* data, size_t len, size_t index, size_t total) {
            JsonDocument doc;
            DeserializationError err = deserializeJson(doc, data, len);
            if (err) {
                request->send(400, "application/json", "{\"error\":\"Invalid JSON\"}");
                return;
            }

            if (doc["device_name"].is<const char*>()) strncpy(config.deviceName, doc["device_name"], sizeof(config.deviceName));
            if (doc["mqtt_broker"].is<const char*>()) strncpy(config.mqttBroker, doc["mqtt_broker"], sizeof(config.mqttBroker));
            if (doc["mqtt_port"].is<int>()) config.mqttPort = doc["mqtt_port"];
            if (doc["mqtt_topic"].is<const char*>()) strncpy(config.mqttTopic, doc["mqtt_topic"], sizeof(config.mqttTopic));
            if (doc["sample_ms"].is<int>()) config.sampleIntervalMs = doc["sample_ms"];

            saveConfig(config);
            request->send(200, "application/json", "{\"status\":\"saved\"}");
        }
    );

    // REST API: Safe Reboot
    server.on("/api/restart", HTTP_POST, [](AsyncWebServerRequest* request) {
        request->send(200, "application/json", "{\"status\":\"restarting\"}");
        vTaskDelay(pdMS_TO_TICKS(500));
        ESP.restart();
    });

    // Initialize Web Browser OTA at /update
    ElegantOTA.begin(&server);

    server.begin();
    ESP_LOGI("HTTP", "Web server and ElegantOTA initialized on port 80");
}
```

---

## 6. Offline RAM Ring Buffer Pattern

Prevent telemetry loss during Wi-Fi or MQTT outages using a thread-safe circular buffer:

```cpp
template <typename T, size_t Capacity>
class RingBuffer {
private:
    T buffer[Capacity];
    size_t head = 0;
    size_t tail = 0;
    size_t count = 0;
    SemaphoreHandle_t mutex;

public:
    RingBuffer() {
        mutex = xSemaphoreCreateMutex();
    }

    bool push(const T& item) {
        if (xSemaphoreTake(mutex, pdMS_TO_TICKS(50)) == pdTRUE) {
            buffer[head] = item;
            head = (head + 1) % Capacity;
            if (count < Capacity) {
                count++;
            } else {
                tail = (tail + 1) % Capacity; // overwrite oldest
            }
            xSemaphoreGive(mutex);
            return true;
        }
        return false;
    }

    bool pop(T& item) {
        if (xSemaphoreTake(mutex, pdMS_TO_TICKS(50)) == pdTRUE) {
            if (count == 0) {
                xSemaphoreGive(mutex);
                return false;
            }
            item = buffer[tail];
            tail = (tail + 1) % Capacity;
            count--;
            xSemaphoreGive(mutex);
            return true;
        }
        return false;
    }

    size_t size() const { return count; }
    bool isEmpty() const { return count == 0; }
};
```

---

## 7. Recommended Directory Structure for ESP32 Projects

```text
my-esp32-project/
├── include/
│   ├── config.h            # Pin definitions and default constants
│   ├── ring_buffer.h       # Circular buffer template
│   └── web_server.h        # WebServer and REST API declarations
├── src/
│   ├── tasks/
│   │   ├── sensor_task.cpp # Core 1 Sensor & control loop
│   │   └── network_task.cpp# Core 0 Wi-Fi, MQTT, and buffer flusher
│   ├── web_server.cpp      # AsyncWebServer & ElegantOTA setup
│   └── main.cpp            # Setup(), FreeRTOS task spawning
├── webui/                  # SvelteKit + Svelte 5 frontend app
│   ├── src/
│   │   └── routes/         # Dashboard pages & API types
│   ├── svelte.config.js    # Configured with adapter-static -> exports to ../data/www
│   ├── vite.config.ts      # With proxy to ESP32 IP
│   └── package.json
├── data/
│   └── www/                # LittleFS static web assets (generated by pnpm build in webui/)
│       ├── index.html
│       ├── index.html.gz   # Pre-compressed gzip assets
│       └── _app/
└── platformio.ini          # Environments, dependencies & build flags
```

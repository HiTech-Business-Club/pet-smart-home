#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoOTA.h>
#include <esp_system.h>
#include <esp_wifi.h>

#include "config.h"
#include "feeder.h"
#include "door.h"
#include "security.h"
#include "communication.h"
#include "utils.h"

// Instances globales
WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);
Preferences preferences;
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP, NTP_SERVER, GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC);
AsyncWebServer webServer(80);

// Variables globales
DeviceConfig config;
SystemState currentState = STATE_INITIALIZING;
TelemetryData telemetry;
unsigned long lastHeartbeat = 0;
unsigned long lastStatusUpdate = 0;
unsigned long lastTelemetry = 0;
bool otaInProgress = false;

// Prototypes de fonctions
void initializeSystem();
void loadConfiguration();
void saveConfiguration();
void connectWiFi();
void connectMQTT();
void handleMQTTMessage(char* topic, byte* payload, unsigned int length);
void publishStatus();
void publishTelemetry();
void updateTelemetry();
void handleSystemTasks();
void setupOTA();
void setupWebServer();
void handleError(const char* error);

void setup() {
  Serial.begin(DEBUG_SERIAL_SPEED);
  Serial.println("\n=== Pet Smart Home Device Starting ===");
  Serial.printf("Firmware Version: %s\n", FIRMWARE_VERSION);
  Serial.printf("ESP32 Chip ID: %llX\n", ESP.getEfuseMac());
  
  // Initialisation du système
  initializeSystem();
  
  // Chargement de la configuration
  loadConfiguration();
  
  // Initialisation des composants
  initializeFeeder();
  initializeDoor();
  initializeSecurity();
  
  // Configuration OTA et serveur web
  setupOTA();
  setupWebServer();
  
  // Connexion WiFi
  connectWiFi();
  
  // Initialisation NTP
  timeClient.begin();
  timeClient.update();
  
  // Connexion MQTT
  connectMQTT();
  
  currentState = STATE_READY;
  Serial.println("=== System Ready ===");
  
  // Publication du statut initial
  publishStatus();
}

void loop() {
  // Gestion des tâches système
  handleSystemTasks();
  
  // Gestion MQTT
  if (!mqttClient.connected() && currentState == STATE_READY) {
    connectMQTT();
  }
  mqttClient.loop();
  
  // Gestion OTA
  if (otaInProgress) {
    ArduinoOTA.handle();
    return; // Skip other tasks during OTA
  }
  
  // Mise à jour de la télémétrie
  updateTelemetry();
  
  // Gestion des composants
  handleFeeder();
  handleDoor();
  handleSecurity();
  
  // Publications périodiques
  unsigned long now = millis();
  
  if (now - lastHeartbeat >= HEARTBEAT_INTERVAL_MS) {
    publishStatus();
    lastHeartbeat = now;
  }
  
  if (now - lastStatusUpdate >= STATUS_UPDATE_INTERVAL_MS) {
    publishStatus();
    lastStatusUpdate = now;
  }
  
  if (now - lastTelemetry >= TELEMETRY_INTERVAL_MS) {
    publishTelemetry();
    lastTelemetry = now;
  }
  
  // Mise à jour du temps
  timeClient.update();
  
  delay(100); // Petit délai pour éviter la surcharge du CPU
}

void initializeSystem() {
  // Configuration des pins
  pinMode(LED_STATUS_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(BATTERY_PIN, INPUT);
  
  // LED de démarrage
  digitalWrite(LED_STATUS_PIN, HIGH);
  
  // Initialisation des préférences
  preferences.begin(PREFS_NAMESPACE, false);
  
  // Génération de l'ID de l'appareil si nécessaire
  if (!preferences.isKey("deviceId")) {
    String deviceId = generateDeviceId();
    preferences.putString("deviceId", deviceId);
    Serial.printf("Generated Device ID: %s\n", deviceId.c_str());
  }
  
  Serial.println("System initialized");
}

void loadConfiguration() {
  // Chargement de la configuration depuis les préférences
  String deviceId = preferences.getString("deviceId", "");
  strncpy(config.deviceId, deviceId.c_str(), DEVICE_ID_LENGTH);
  
  String wifiSSID = preferences.getString("wifiSSID", WIFI_SSID_DEFAULT);
  strncpy(config.wifiSSID, wifiSSID.c_str(), sizeof(config.wifiSSID) - 1);
  
  String wifiPassword = preferences.getString("wifiPassword", WIFI_PASSWORD_DEFAULT);
  strncpy(config.wifiPassword, wifiPassword.c_str(), sizeof(config.wifiPassword) - 1);
  
  String mqttServer = preferences.getString("mqttServer", MQTT_SERVER_DEFAULT);
  strncpy(config.mqttServer, mqttServer.c_str(), sizeof(config.mqttServer) - 1);
  
  config.mqttPort = preferences.getInt("mqttPort", MQTT_PORT_DEFAULT);
  config.deviceType = (DeviceType)preferences.getInt("deviceType", DEVICE_COMBO);
  config.feederEnabled = preferences.getBool("feederEnabled", true);
  config.doorEnabled = preferences.getBool("doorEnabled", true);
  config.defaultFeedingAmount = preferences.getInt("defaultFeedingAmount", 50);
  config.doorOpenDuration = preferences.getInt("doorOpenDuration", DOOR_OPEN_DURATION_MS);
  config.notificationsEnabled = preferences.getBool("notificationsEnabled", true);
  config.debugEnabled = preferences.getBool("debugEnabled", DEBUG_ENABLED);
  
  Serial.printf("Configuration loaded for device: %s\n", config.deviceId);
}

void saveConfiguration() {
  preferences.putString("wifiSSID", config.wifiSSID);
  preferences.putString("wifiPassword", config.wifiPassword);
  preferences.putString("mqttServer", config.mqttServer);
  preferences.putInt("mqttPort", config.mqttPort);
  preferences.putInt("deviceType", config.deviceType);
  preferences.putBool("feederEnabled", config.feederEnabled);
  preferences.putBool("doorEnabled", config.doorEnabled);
  preferences.putInt("defaultFeedingAmount", config.defaultFeedingAmount);
  preferences.putInt("doorOpenDuration", config.doorOpenDuration);
  preferences.putBool("notificationsEnabled", config.notificationsEnabled);
  preferences.putBool("debugEnabled", config.debugEnabled);
  
  Serial.println("Configuration saved");
}

void connectWiFi() {
  currentState = STATE_CONNECTING_WIFI;
  Serial.printf("Connecting to WiFi: %s\n", config.wifiSSID);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(config.wifiSSID, config.wifiPassword);
  
  unsigned long startTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startTime < WIFI_TIMEOUT_MS) {
    delay(500);
    Serial.print(".");
    digitalWrite(LED_STATUS_PIN, !digitalRead(LED_STATUS_PIN)); // Blink LED
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.printf("WiFi connected! IP: %s\n", WiFi.localIP().toString().c_str());
    Serial.printf("RSSI: %d dBm\n", WiFi.RSSI());
    digitalWrite(LED_STATUS_PIN, HIGH);
  } else {
    Serial.println("\nWiFi connection failed!");
    handleError("WiFi connection timeout");
  }
}

void connectMQTT() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }
  
  currentState = STATE_CONNECTING_MQTT;
  Serial.printf("Connecting to MQTT: %s:%d\n", config.mqttServer, config.mqttPort);
  
  mqttClient.setServer(config.mqttServer, config.mqttPort);
  mqttClient.setCallback(handleMQTTMessage);
  
  String clientId = String(MQTT_CLIENT_ID_PREFIX) + config.deviceId;
  
  if (mqttClient.connect(clientId.c_str(), config.mqttUsername, config.mqttPassword)) {
    Serial.println("MQTT connected!");
    
    // Souscription aux topics de commande
    char commandTopic[128];
    snprintf(commandTopic, sizeof(commandTopic), MQTT_TOPIC_COMMAND, config.deviceId);
    mqttClient.subscribe(commandTopic);
    
    char configTopic[128];
    snprintf(configTopic, sizeof(configTopic), MQTT_TOPIC_CONFIG, config.deviceId);
    mqttClient.subscribe(configTopic);
    
    Serial.printf("Subscribed to: %s\n", commandTopic);
    Serial.printf("Subscribed to: %s\n", configTopic);
    
  } else {
    Serial.printf("MQTT connection failed, rc=%d\n", mqttClient.state());
    handleError("MQTT connection failed");
  }
}

void handleMQTTMessage(char* topic, byte* payload, unsigned int length) {
  // Conversion du payload en string
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';
  
  Serial.printf("MQTT message received on %s: %s\n", topic, message);
  
  // Parse JSON
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, message);
  
  if (error) {
    Serial.printf("JSON parsing failed: %s\n", error.c_str());
    return;
  }
  
  // Traitement des commandes
  char commandTopic[128];
  snprintf(commandTopic, sizeof(commandTopic), MQTT_TOPIC_COMMAND, config.deviceId);
  
  if (strcmp(topic, commandTopic) == 0) {
    handleCommand(doc);
  }
  
  // Traitement de la configuration
  char configTopic[128];
  snprintf(configTopic, sizeof(configTopic), MQTT_TOPIC_CONFIG, config.deviceId);
  
  if (strcmp(topic, configTopic) == 0) {
    handleConfigUpdate(doc);
  }
}

void publishStatus() {
  DynamicJsonDocument doc(512);
  
  doc["deviceId"] = config.deviceId;
  doc["timestamp"] = timeClient.getEpochTime();
  doc["state"] = currentState;
  doc["uptime"] = millis();
  doc["freeHeap"] = ESP.getFreeHeap();
  doc["wifiRSSI"] = WiFi.RSSI();
  doc["batteryLevel"] = telemetry.batteryLevel;
  doc["firmwareVersion"] = FIRMWARE_VERSION;
  
  if (config.feederEnabled) {
    doc["feeder"]["state"] = getFeederState();
    doc["feeder"]["foodLevel"] = telemetry.foodLevel;
    doc["feeder"]["lastFeeding"] = telemetry.lastFeeding;
  }
  
  if (config.doorEnabled) {
    doc["door"]["state"] = getDoorState();
    doc["door"]["isOpen"] = telemetry.doorOpen;
    doc["door"]["lastAccess"] = telemetry.lastAccess;
  }
  
  char topic[128];
  snprintf(topic, sizeof(topic), MQTT_TOPIC_STATUS, config.deviceId);
  
  String output;
  serializeJson(doc, output);
  
  if (mqttClient.publish(topic, output.c_str())) {
    if (config.debugEnabled) {
      Serial.printf("Status published: %s\n", output.c_str());
    }
  } else {
    Serial.println("Failed to publish status");
  }
}

void publishTelemetry() {
  DynamicJsonDocument doc(1024);
  
  doc["deviceId"] = config.deviceId;
  doc["timestamp"] = timeClient.getEpochTime();
  doc["batteryVoltage"] = telemetry.batteryVoltage;
  doc["batteryLevel"] = telemetry.batteryLevel;
  doc["wifiRSSI"] = telemetry.wifiRSSI;
  doc["uptime"] = telemetry.uptime;
  doc["freeHeap"] = telemetry.freeHeap;
  doc["temperature"] = telemetry.temperature;
  doc["foodLevel"] = telemetry.foodLevel;
  doc["doorOpen"] = telemetry.doorOpen;
  doc["failedAttempts"] = telemetry.failedAttempts;
  
  char topic[128];
  snprintf(topic, sizeof(topic), MQTT_TOPIC_TELEMETRY, config.deviceId);
  
  String output;
  serializeJson(doc, output);
  
  if (mqttClient.publish(topic, output.c_str())) {
    if (config.debugEnabled) {
      Serial.printf("Telemetry published: %s\n", output.c_str());
    }
  } else {
    Serial.println("Failed to publish telemetry");
  }
}

void updateTelemetry() {
  // Lecture de la tension de la batterie
  int batteryRaw = analogRead(BATTERY_PIN);
  telemetry.batteryVoltage = (batteryRaw / 4095.0) * 3.3 * 2; // Diviseur de tension
  telemetry.batteryLevel = map(constrain(telemetry.batteryVoltage * 100, 320, 420), 320, 420, 0, 100);
  
  // Autres mesures
  telemetry.wifiRSSI = WiFi.RSSI();
  telemetry.uptime = millis();
  telemetry.freeHeap = ESP.getFreeHeap();
  telemetry.temperature = temperatureRead(); // Capteur interne ESP32
  
  // Mise à jour des données des composants
  if (config.feederEnabled) {
    telemetry.foodLevel = getFoodLevel();
  }
  
  if (config.doorEnabled) {
    telemetry.doorOpen = isDoorOpen();
  }
  
  telemetry.failedAttempts = getFailedAttempts();
}

void handleSystemTasks() {
  // Gestion du bouton de reset
  static unsigned long buttonPressTime = 0;
  static bool buttonPressed = false;
  
  if (digitalRead(BUTTON_PIN) == LOW) {
    if (!buttonPressed) {
      buttonPressed = true;
      buttonPressTime = millis();
    } else if (millis() - buttonPressTime > 5000) {
      // Reset de la configuration après 5 secondes
      Serial.println("Factory reset triggered!");
      preferences.clear();
      ESP.restart();
    }
  } else {
    buttonPressed = false;
  }
  
  // Gestion de l'état de la LED
  static unsigned long lastLedUpdate = 0;
  if (millis() - lastLedUpdate > 1000) {
    switch (currentState) {
      case STATE_READY:
        digitalWrite(LED_STATUS_PIN, HIGH);
        break;
      case STATE_ERROR:
        digitalWrite(LED_STATUS_PIN, !digitalRead(LED_STATUS_PIN)); // Blink fast
        break;
      default:
        digitalWrite(LED_STATUS_PIN, !digitalRead(LED_STATUS_PIN)); // Blink slow
        break;
    }
    lastLedUpdate = millis();
  }
}

void setupOTA() {
  ArduinoOTA.setPassword(OTA_PASSWORD);
  ArduinoOTA.setPort(OTA_PORT);
  
  ArduinoOTA.onStart([]() {
    otaInProgress = true;
    currentState = STATE_OTA_UPDATE;
    String type = (ArduinoOTA.getCommand() == U_FLASH) ? "sketch" : "filesystem";
    Serial.println("Start updating " + type);
  });
  
  ArduinoOTA.onEnd([]() {
    otaInProgress = false;
    Serial.println("\nEnd");
  });
  
  ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
    Serial.printf("Progress: %u%%\r", (progress / (total / 100)));
  });
  
  ArduinoOTA.onError([](ota_error_t error) {
    otaInProgress = false;
    currentState = STATE_ERROR;
    Serial.printf("Error[%u]: ", error);
    if (error == OTA_AUTH_ERROR) Serial.println("Auth Failed");
    else if (error == OTA_BEGIN_ERROR) Serial.println("Begin Failed");
    else if (error == OTA_CONNECT_ERROR) Serial.println("Connect Failed");
    else if (error == OTA_RECEIVE_ERROR) Serial.println("Receive Failed");
    else if (error == OTA_END_ERROR) Serial.println("End Failed");
  });
  
  ArduinoOTA.begin();
  Serial.println("OTA Ready");
}

void setupWebServer() {
  // Page de configuration
  webServer.on("/", HTTP_GET, [](AsyncWebServerRequest *request){
    String html = generateConfigPage();
    request->send(200, "text/html", html);
  });
  
  // API de statut
  webServer.on("/api/status", HTTP_GET, [](AsyncWebServerRequest *request){
    DynamicJsonDocument doc(512);
    doc["deviceId"] = config.deviceId;
    doc["state"] = currentState;
    doc["uptime"] = millis();
    doc["wifiRSSI"] = WiFi.RSSI();
    doc["batteryLevel"] = telemetry.batteryLevel;
    
    String output;
    serializeJson(doc, output);
    request->send(200, "application/json", output);
  });
  
  // API de configuration
  webServer.on("/api/config", HTTP_POST, [](AsyncWebServerRequest *request){
    // Traitement de la mise à jour de configuration
    if (request->hasParam("wifiSSID", true)) {
      String ssid = request->getParam("wifiSSID", true)->value();
      strncpy(config.wifiSSID, ssid.c_str(), sizeof(config.wifiSSID) - 1);
    }
    
    if (request->hasParam("wifiPassword", true)) {
      String password = request->getParam("wifiPassword", true)->value();
      strncpy(config.wifiPassword, password.c_str(), sizeof(config.wifiPassword) - 1);
    }
    
    saveConfiguration();
    request->send(200, "application/json", "{\"status\":\"success\"}");
    
    // Redémarrage pour appliquer la nouvelle configuration
    delay(1000);
    ESP.restart();
  });
  
  webServer.begin();
  Serial.println("Web server started");
}

void handleError(const char* error) {
  currentState = STATE_ERROR;
  Serial.printf("ERROR: %s\n", error);
  
  // Bip d'erreur
  for (int i = 0; i < 3; i++) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(200);
    digitalWrite(BUZZER_PIN, LOW);
    delay(200);
  }
  
  // Log de l'erreur via MQTT si possible
  if (mqttClient.connected()) {
    DynamicJsonDocument doc(256);
    doc["deviceId"] = config.deviceId;
    doc["timestamp"] = timeClient.getEpochTime();
    doc["level"] = "ERROR";
    doc["message"] = error;
    
    char topic[128];
    snprintf(topic, sizeof(topic), MQTT_TOPIC_LOG, config.deviceId);
    
    String output;
    serializeJson(doc, output);
    mqttClient.publish(topic, output.c_str());
  }
}
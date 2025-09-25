#include <Arduino.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <Preferences.h>
#include <NTPClient.h>
#include <WiFiUdp.h>
#include <ArduinoOTA.h>

// Configuration WiFi et MQTT
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";
const char* mqtt_server = "YOUR_MQTT_SERVER";
const int mqtt_port = 1883;
const char* mqtt_user = "pet_smart_device";
const char* mqtt_password = "secure_mqtt_password_2024";

// Clients
WiFiClient espClient;
PubSubClient client(espClient);
WiFiUDP ntpUDP;
NTPClient timeClient(ntpUDP);
Preferences preferences;

// Variables globales
unsigned long lastMsg = 0;
unsigned long lastHeartbeat = 0;
bool systemInitialized = false;

// Topics MQTT
const char* TOPIC_STATUS = "pet-smart-home/device/status";
const char* TOPIC_COMMAND = "pet-smart-home/device/command";
const char* TOPIC_HEARTBEAT = "pet-smart-home/device/heartbeat";

// Déclarations des fonctions
void setupWiFi();
void setupOTA();
void callback(char* topic, byte* payload, unsigned int length);
void reconnectMQTT();
void publishStatus();
void publishHeartbeat();

void setup() {
    Serial.begin(115200);
    Serial.println("=== Pet Smart Home ESP32 - Version Simple ===");
    
    // Initialisation des préférences
    preferences.begin("pet-smart", false);
    
    // Configuration WiFi
    setupWiFi();
    
    // Configuration MQTT
    client.setServer(mqtt_server, mqtt_port);
    client.setCallback(callback);
    
    // Configuration NTP
    timeClient.begin();
    timeClient.setTimeOffset(3600); // UTC+1
    
    // Configuration OTA
    setupOTA();
    
    Serial.println("Système initialisé avec succès");
    systemInitialized = true;
}

void loop() {
    // Gestion WiFi
    if (WiFi.status() != WL_CONNECTED) {
        setupWiFi();
    }
    
    // Gestion MQTT
    if (!client.connected()) {
        reconnectMQTT();
    }
    client.loop();
    
    // Gestion OTA
    ArduinoOTA.handle();
    
    // Mise à jour du temps
    timeClient.update();
    
    // Envoi du statut périodique
    unsigned long now = millis();
    if (now - lastMsg > 30000) { // Toutes les 30 secondes
        lastMsg = now;
        publishStatus();
    }
    
    // Heartbeat toutes les 60 secondes
    if (now - lastHeartbeat > 60000) {
        lastHeartbeat = now;
        publishHeartbeat();
    }
    
    delay(100);
}

void setupWiFi() {
    delay(10);
    Serial.println();
    Serial.print("Connexion à ");
    Serial.println(ssid);
    
    WiFi.begin(ssid, password);
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() == WL_CONNECTED) {
        Serial.println("");
        Serial.println("WiFi connecté");
        Serial.println("Adresse IP: ");
        Serial.println(WiFi.localIP());
    } else {
        Serial.println("Échec de connexion WiFi");
    }
}

void setupOTA() {
    ArduinoOTA.setHostname("pet-smart-home-esp32");
    ArduinoOTA.setPassword("pet-smart-home-ota");
    
    ArduinoOTA.onStart([]() {
        String type;
        if (ArduinoOTA.getCommand() == U_FLASH) {
            type = "sketch";
        } else {
            type = "filesystem";
        }
        Serial.println("Début mise à jour OTA " + type);
    });
    
    ArduinoOTA.onEnd([]() {
        Serial.println("\nMise à jour OTA terminée");
    });
    
    ArduinoOTA.onProgress([](unsigned int progress, unsigned int total) {
        Serial.printf("Progression: %u%%\r", (progress / (total / 100)));
    });
    
    ArduinoOTA.onError([](ota_error_t error) {
        Serial.printf("Erreur OTA[%u]: ", error);
        if (error == OTA_AUTH_ERROR) {
            Serial.println("Erreur d'authentification");
        } else if (error == OTA_BEGIN_ERROR) {
            Serial.println("Erreur de début");
        } else if (error == OTA_CONNECT_ERROR) {
            Serial.println("Erreur de connexion");
        } else if (error == OTA_RECEIVE_ERROR) {
            Serial.println("Erreur de réception");
        } else if (error == OTA_END_ERROR) {
            Serial.println("Erreur de fin");
        }
    });
    
    ArduinoOTA.begin();
    Serial.println("OTA configuré");
}

void callback(char* topic, byte* payload, unsigned int length) {
    Serial.print("Message reçu [");
    Serial.print(topic);
    Serial.print("] ");
    
    String message;
    for (int i = 0; i < length; i++) {
        message += (char)payload[i];
    }
    Serial.println(message);
    
    // Parse du JSON
    JsonDocument doc;
    DeserializationError error = deserializeJson(doc, message);
    
    if (error) {
        Serial.print("Erreur parsing JSON: ");
        Serial.println(error.c_str());
        return;
    }
    
    // Traitement des commandes
    if (doc["command"] == "restart") {
        Serial.println("Redémarrage demandé");
        ESP.restart();
    } else if (doc["command"] == "status") {
        publishStatus();
    } else if (doc["command"] == "ping") {
        publishHeartbeat();
    }
}

void reconnectMQTT() {
    while (!client.connected()) {
        Serial.print("Tentative de connexion MQTT...");
        
        String clientId = "PetSmartHome-";
        clientId += String(random(0xffff), HEX);
        
        if (client.connect(clientId.c_str(), mqtt_user, mqtt_password)) {
            Serial.println("connecté");
            client.subscribe(TOPIC_COMMAND);
            publishStatus();
        } else {
            Serial.print("échec, rc=");
            Serial.print(client.state());
            Serial.println(" nouvelle tentative dans 5 secondes");
            delay(5000);
        }
    }
}

void publishStatus() {
    JsonDocument doc;
    
    doc["device_id"] = WiFi.macAddress();
    doc["timestamp"] = timeClient.getEpochTime();
    doc["uptime"] = millis();
    doc["wifi_rssi"] = WiFi.RSSI();
    doc["free_heap"] = ESP.getFreeHeap();
    doc["chip_revision"] = ESP.getChipRevision();
    doc["sdk_version"] = ESP.getSdkVersion();
    doc["status"] = "online";
    doc["initialized"] = systemInitialized;
    
    String jsonString;
    serializeJson(doc, jsonString);
    
    client.publish(TOPIC_STATUS, jsonString.c_str());
    Serial.println("Statut publié");
}

void publishHeartbeat() {
    JsonDocument doc;
    
    doc["device_id"] = WiFi.macAddress();
    doc["timestamp"] = timeClient.getEpochTime();
    doc["type"] = "heartbeat";
    doc["uptime"] = millis();
    
    String jsonString;
    serializeJson(doc, jsonString);
    
    client.publish(TOPIC_HEARTBEAT, jsonString.c_str());
    Serial.println("Heartbeat envoyé");
}
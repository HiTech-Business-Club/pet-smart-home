#ifndef CONFIG_H
#define CONFIG_H

// Configuration WiFi
#define WIFI_SSID_DEFAULT "PetSmartHome"
#define WIFI_PASSWORD_DEFAULT "password123"
#define WIFI_TIMEOUT_MS 20000
#define WIFI_RETRY_DELAY_MS 5000

// Configuration MQTT
#define MQTT_SERVER_DEFAULT "mqtt.pet-smart-home.com"
#define MQTT_PORT_DEFAULT 8883
#define MQTT_CLIENT_ID_PREFIX "pet-smart-home-"
#define MQTT_USERNAME_DEFAULT ""
#define MQTT_PASSWORD_DEFAULT ""
#define MQTT_KEEPALIVE 60
#define MQTT_TIMEOUT_MS 10000

// Topics MQTT
#define MQTT_TOPIC_STATUS "devices/%s/status"
#define MQTT_TOPIC_COMMAND "devices/%s/command"
#define MQTT_TOPIC_TELEMETRY "devices/%s/telemetry"
#define MQTT_TOPIC_LOG "devices/%s/log"
#define MQTT_TOPIC_CONFIG "devices/%s/config"

// Configuration matérielle - Distributeur de nourriture
#define FEEDER_SERVO_PIN 18
#define FEEDER_LOAD_CELL_DOUT_PIN 19
#define FEEDER_LOAD_CELL_SCK_PIN 21
#define FEEDER_CALIBRATION_FACTOR -7050.0
#define FEEDER_TARE_OFFSET 50000
#define FEEDER_MIN_WEIGHT 10.0
#define FEEDER_MAX_WEIGHT 5000.0

// Configuration matérielle - Porte intelligente
#define DOOR_SERVO_PIN 16
#define DOOR_RFID_SS_PIN 5
#define DOOR_RFID_RST_PIN 17
#define DOOR_OPEN_ANGLE 90
#define DOOR_CLOSE_ANGLE 0
#define DOOR_OPEN_DURATION_MS 10000

// Configuration matérielle - Capteurs
#define BATTERY_PIN 35
#define LED_STATUS_PIN 2
#define BUZZER_PIN 4
#define BUTTON_PIN 0

// Configuration BLE
#define BLE_DEVICE_NAME "PetSmartHome"
#define BLE_SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define BLE_CHARACTERISTIC_UUID "87654321-4321-4321-4321-cba987654321"
#define BLE_SCAN_TIME 5

// Configuration système
#define DEVICE_ID_LENGTH 12
#define FIRMWARE_VERSION "1.0.0"
#define HEARTBEAT_INTERVAL_MS 60000
#define STATUS_UPDATE_INTERVAL_MS 30000
#define TELEMETRY_INTERVAL_MS 300000

// Configuration sécurité
#define MAX_FAILED_ATTEMPTS 5
#define LOCKOUT_DURATION_MS 300000
#define ENCRYPTION_KEY_LENGTH 32

// Configuration stockage
#define PREFS_NAMESPACE "pet-smart-home"
#define MAX_AUTHORIZED_PETS 20
#define MAX_FEEDING_SCHEDULES 10

// Configuration NTP
#define NTP_SERVER "pool.ntp.org"
#define GMT_OFFSET_SEC 3600
#define DAYLIGHT_OFFSET_SEC 3600

// Configuration OTA
#define OTA_PASSWORD "pet-smart-home-ota"
#define OTA_PORT 3232

// Configuration debug
#define DEBUG_SERIAL_SPEED 115200
#define DEBUG_ENABLED true

// Macros utilitaires
#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

// États du système
enum SystemState {
  STATE_INITIALIZING,
  STATE_CONNECTING_WIFI,
  STATE_CONNECTING_MQTT,
  STATE_READY,
  STATE_ERROR,
  STATE_MAINTENANCE,
  STATE_OTA_UPDATE
};

// Types d'appareils
enum DeviceType {
  DEVICE_FEEDER,
  DEVICE_DOOR,
  DEVICE_COMBO
};

// États du distributeur
enum FeederState {
  FEEDER_IDLE,
  FEEDER_DISPENSING,
  FEEDER_ERROR,
  FEEDER_EMPTY,
  FEEDER_JAMMED
};

// États de la porte
enum DoorState {
  DOOR_CLOSED,
  DOOR_OPENING,
  DOOR_OPEN,
  DOOR_CLOSING,
  DOOR_ERROR
};

// Structure de configuration
struct DeviceConfig {
  char deviceId[DEVICE_ID_LENGTH + 1];
  char wifiSSID[32];
  char wifiPassword[64];
  char mqttServer[64];
  int mqttPort;
  char mqttUsername[32];
  char mqttPassword[64];
  DeviceType deviceType;
  bool feederEnabled;
  bool doorEnabled;
  int defaultFeedingAmount;
  int doorOpenDuration;
  bool notificationsEnabled;
  bool debugEnabled;
};

// Structure de télémétrie
struct TelemetryData {
  float batteryVoltage;
  int batteryLevel;
  float foodLevel;
  int wifiRSSI;
  unsigned long uptime;
  unsigned long freeHeap;
  float temperature;
  bool doorOpen;
  int failedAttempts;
  unsigned long lastFeeding;
  unsigned long lastAccess;
};

#endif // CONFIG_H
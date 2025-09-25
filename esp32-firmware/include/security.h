#ifndef SECURITY_H
#define SECURITY_H

// Configuration de sécurité pour Pet Smart Home
// Ce fichier contient les paramètres de sécurité et de chiffrement

// Clés de chiffrement (à modifier en production)
#define ENCRYPTION_KEY "PetSmartHome2024SecureKey123456"
#define MQTT_USERNAME "pet_smart_device"
#define MQTT_PASSWORD "secure_mqtt_password_2024"

// Configuration TLS/SSL
#define USE_TLS true
#define TLS_VERIFY_CERTIFICATE false  // Pour développement uniquement

// Configuration OTA sécurisée
#define OTA_PASSWORD "pet-smart-home-ota"
#define OTA_HASH_MD5 "d41d8cd98f00b204e9800998ecf8427e"

// Tokens d'authentification
#define DEVICE_TOKEN_LENGTH 32
#define API_KEY_LENGTH 64

// Configuration de sécurité WiFi
#define WIFI_SECURITY_WPA2 true
#define WIFI_TIMEOUT_MS 30000

// Paramètres de validation
#define MAX_RETRY_ATTEMPTS 3
#define SECURITY_CHECK_INTERVAL 60000  // 1 minute

// Fonctions de sécurité
bool validateDeviceToken(const char* token);
bool encryptData(const char* data, char* encrypted, size_t maxLen);
bool decryptData(const char* encrypted, char* data, size_t maxLen);
void generateDeviceId(char* deviceId, size_t maxLen);

// Fonctions d'initialisation et de gestion
void initializeSecurity();
void handleSecurity();
int getFailedAttempts();

#endif // SECURITY_H
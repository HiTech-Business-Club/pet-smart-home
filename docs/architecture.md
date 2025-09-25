# Architecture Système

## Vue d'Ensemble

Le système est composé de 4 couches principales :

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION MOBILE                       │
│                   (Flutter - iOS/Android)                   │
└─────────────────────────┬───────────────────────────────────┘
                          │ HTTPS/WebSocket
┌─────────────────────────▼───────────────────────────────────┐
│                     BACKEND CLOUD                           │
│              (Firebase/AWS - Authentication,                │
│               Database, Notifications, MQTT)                │
└─────────────────────────┬───────────────────────────────────┘
                          │ MQTT/Wi-Fi
┌─────────────────────────▼───────────────────────────────────┐
│                  MICROCONTRÔLEUR ESP32                      │
│              (Logique métier, Communication,                │
│                Gestion capteurs/actionneurs)                │
└─────────────────────────┬───────────────────────────────────┘
                          │ GPIO/I2C/SPI
┌─────────────────────────▼───────────────────────────────────┐
│                   COUCHE HARDWARE                           │
│            (Capteurs, Actionneurs, Alimentation)            │
└─────────────────────────────────────────────────────────────┘
```

## Composants Détaillés

### 1. Application Mobile (Flutter)

#### Structure des Écrans
```
lib/
├── main.dart                 # Point d'entrée
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── dashboard_screen.dart
│   ├── feeder/
│   │   ├── feeder_control_screen.dart
│   │   └── feeding_schedule_screen.dart
│   ├── door/
│   │   ├── door_control_screen.dart
│   │   └── access_history_screen.dart
│   └── settings/
│       ├── pet_management_screen.dart
│       └── device_settings_screen.dart
├── services/
│   ├── firebase_service.dart
│   ├── mqtt_service.dart
│   └── notification_service.dart
├── models/
│   ├── pet.dart
│   ├── feeding_schedule.dart
│   └── access_log.dart
└── widgets/
    ├── custom_button.dart
    └── status_card.dart
```

#### Fonctionnalités Clés
- **Authentification** : Firebase Auth
- **Interface temps réel** : WebSocket/MQTT
- **Notifications push** : Firebase Cloud Messaging
- **Stockage local** : SQLite/Hive
- **Gestion d'état** : Provider/Riverpod

### 2. Backend Cloud (Firebase)

#### Services Utilisés
```
Firebase Project/
├── Authentication          # Gestion utilisateurs
├── Firestore Database      # Base de données NoSQL
├── Cloud Functions         # Logique serveur
├── Cloud Messaging         # Notifications push
├── Storage                 # Stockage fichiers
└── Hosting                 # Interface web admin
```

#### Structure Base de Données
```
users/
├── {userId}/
│   ├── profile: {name, email, created_at}
│   ├── devices: {device_id, name, type, status}
│   └── pets: {pet_id, name, rfid_tag, ble_mac}

devices/
├── {deviceId}/
│   ├── status: {online, battery, last_seen}
│   ├── config: {feeding_schedule, door_settings}
│   └── logs: {timestamp, event_type, data}

feeding_logs/
├── {logId}/
│   └── {device_id, pet_id, timestamp, amount, status}

access_logs/
├── {logId}/
│   └── {device_id, pet_id, timestamp, direction, method}
```

### 3. Microcontrôleur ESP32

#### Architecture Firmware
```
src/
├── main.cpp                 # Boucle principale
├── config/
│   ├── wifi_config.h
│   ├── mqtt_config.h
│   └── pins_config.h
├── modules/
│   ├── wifi_manager.cpp
│   ├── mqtt_client.cpp
│   ├── feeder_controller.cpp
│   ├── door_controller.cpp
│   ├── rfid_reader.cpp
│   └── ble_scanner.cpp
├── sensors/
│   ├── ultrasonic_sensor.cpp
│   └── level_detector.cpp
└── utils/
    ├── json_parser.cpp
    └── crypto_utils.cpp
```

#### Protocoles de Communication
- **Wi-Fi** : Connexion réseau principal
- **MQTT** : Communication bidirectionnelle avec backend
- **BLE** : Détection colliers Bluetooth
- **RFID** : Lecture tags passifs
- **I2C/SPI** : Communication capteurs

### 4. Couche Hardware

#### Distributeur de Nourriture
```
ESP32 GPIO Mapping:
├── GPIO 2  → Servomoteur distribution
├── GPIO 4  → Trigger capteur ultrasonique
├── GPIO 5  → Echo capteur ultrasonique
├── GPIO 18 → LED statut
└── GPIO 19 → Buzzer alertes
```

#### Porte Intelligente
```
ESP32 GPIO Mapping:
├── GPIO 12 → Servomoteur porte
├── GPIO 14 → RFID SDA
├── GPIO 27 → RFID SCK
├── GPIO 26 → RFID MOSI
├── GPIO 25 → RFID MISO
├── GPIO 33 → RFID RST
├── GPIO 16 → BLE RX
└── GPIO 17 → BLE TX
```

## Flux de Données

### Scénario 1 : Distribution Programmée
```
1. Timer ESP32 → Vérification horaire
2. ESP32 → Activation servomoteur
3. ESP32 → Mesure quantité distribuée
4. ESP32 → MQTT → Backend → Log événement
5. Backend → FCM → App mobile → Notification
```

### Scénario 2 : Accès Animal
```
1. Capteur RFID/BLE → Détection collier
2. ESP32 → Vérification autorisation
3. ESP32 → Ouverture porte (si autorisé)
4. ESP32 → MQTT → Backend → Log accès
5. Backend → FCM → App mobile → Notification
```

### Scénario 3 : Contrôle Manuel
```
1. App mobile → Backend → Commande
2. Backend → MQTT → ESP32
3. ESP32 → Exécution action
4. ESP32 → MQTT → Backend → Confirmation
5. Backend → App mobile → Mise à jour statut
```

## Sécurité

### Chiffrement
- **TLS 1.3** : Communication HTTPS/MQTT
- **AES-256** : Chiffrement données sensibles
- **RSA-2048** : Échange clés

### Authentification
- **JWT Tokens** : Sessions utilisateur
- **Device Certificates** : Authentification ESP32
- **RFID/BLE Pairing** : Association colliers

### Protection
- **Rate Limiting** : Prévention attaques
- **Input Validation** : Sanitisation données
- **Secure Boot** : ESP32 firmware vérifié

## Monitoring et Maintenance

### Métriques Surveillées
- **Connectivité** : Wi-Fi, MQTT, Backend
- **Hardware** : Batterie, capteurs, actionneurs
- **Performance** : Latence, débit, erreurs
- **Sécurité** : Tentatives intrusion, anomalies

### Mise à Jour OTA
- **Firmware ESP32** : Mise à jour sans fil
- **App Mobile** : Store automatique
- **Backend** : Déploiement continu

Cette architecture garantit un système robuste, sécurisé et évolutif pour la gestion domotique des animaux de compagnie.
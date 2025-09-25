# Guide d'Installation - Pet Smart Home

## Vue d'ensemble

Ce guide vous accompagne dans l'installation complète du système Pet Smart Home, de l'assemblage du matériel au déploiement de l'application mobile.

## Prérequis

### Matériel requis

#### Distributeur de nourriture
- ESP32 DevKit v1
- Servo moteur SG90 ou équivalent
- Capteur de poids HX711 + cellule de charge 5kg
- Batterie 18650 3000mAh + support
- Module de charge TP4056
- Boîtier étanche IP65
- Réservoir alimentaire (1-2L)
- Mécanisme de distribution (imprimé 3D)
- Connecteurs et câbles

#### Porte intelligente
- ESP32 DevKit v1
- Servo moteur MG996R (plus puissant)
- Module RFID RC522
- Module Bluetooth ESP32 (intégré)
- Batterie 18650 3000mAh + support
- Module de charge TP4056
- Boîtier étanche IP65
- Mécanisme de porte (imprimé 3D)
- Tags RFID (5-10 pièces)

#### Outils nécessaires
- Fer à souder + étain
- Tournevis cruciforme
- Perceuse + forets
- Multimètre
- Imprimante 3D (ou service d'impression)

### Logiciels requis

#### Développement ESP32
- Arduino IDE 2.0+
- Bibliothèques ESP32
- PlatformIO (optionnel)

#### Application mobile
- Flutter SDK 3.0+
- Android Studio / Xcode
- Firebase CLI

#### Backend
- Node.js 18+
- Firebase Tools
- Git

## Installation du matériel

### Étape 1 : Préparation des composants

#### Impression 3D des pièces

Téléchargez les fichiers STL depuis `/hardware/3d-models/` :

1. **Distributeur** :
   - `feeder_housing.stl` - Boîtier principal
   - `feeder_mechanism.stl` - Mécanisme de distribution
   - `food_reservoir.stl` - Réservoir de nourriture

2. **Porte** :
   - `door_housing.stl` - Boîtier électronique
   - `door_mechanism.stl` - Mécanisme d'ouverture
   - `rfid_mount.stl` - Support lecteur RFID

**Paramètres d'impression** :
- Matériau : PETG ou ABS (résistant aux intempéries)
- Épaisseur de couche : 0.2mm
- Remplissage : 20%
- Support : Oui pour les surplombs

#### Préparation des circuits

1. **Soudure des connexions** :
   ```
   Distributeur :
   ESP32 Pin 18 → Servo Signal (Orange)
   ESP32 Pin 19 → HX711 DOUT
   ESP32 Pin 21 → HX711 SCK
   ESP32 Pin 35 → Diviseur tension batterie
   ESP32 Pin 2  → LED statut
   ESP32 Pin 4  → Buzzer
   ESP32 3.3V  → Alimentation capteurs
   ESP32 GND   → Masse commune
   
   Porte :
   ESP32 Pin 16 → Servo Signal (Orange)
   ESP32 Pin 5  → RFID SS
   ESP32 Pin 17 → RFID RST
   ESP32 Pin 18 → RFID SCK
   ESP32 Pin 19 → RFID MOSI
   ESP32 Pin 23 → RFID MISO
   ESP32 Pin 4  → Buzzer
   ESP32 Pin 2  → LED statut
   ```

2. **Test des connexions** :
   - Vérifiez la continuité avec un multimètre
   - Testez l'alimentation (3.3V et 5V)
   - Vérifiez l'absence de courts-circuits

### Étape 2 : Assemblage mécanique

#### Distributeur de nourriture

1. **Installation du servo** :
   - Fixez le servo dans le mécanisme imprimé
   - Connectez la vis sans fin au servo
   - Testez la rotation libre

2. **Installation de la balance** :
   - Montez la cellule de charge sous le réservoir
   - Connectez le module HX711
   - Calibrez avec des poids connus

3. **Assemblage final** :
   - Placez l'ESP32 dans le boîtier
   - Connectez la batterie et le module de charge
   - Fermez le boîtier avec les joints d'étanchéité

#### Porte intelligente

1. **Installation du servo** :
   - Fixez le servo sur le mécanisme de porte
   - Ajustez les angles d'ouverture/fermeture
   - Testez le couple nécessaire

2. **Installation du lecteur RFID** :
   - Montez le RC522 dans son support
   - Positionnez-le à 2-5cm de la zone de passage
   - Protégez avec un cache transparent

3. **Assemblage final** :
   - Installez l'ESP32 dans le boîtier étanche
   - Connectez tous les composants
   - Testez l'étanchéité

### Étape 3 : Installation physique

#### Distributeur

1. **Choix de l'emplacement** :
   - Zone couverte mais accessible
   - Près d'une source d'alimentation (optionnel)
   - Facile d'accès pour le rechargement

2. **Fixation** :
   - Utilisez des vis inox pour l'extérieur
   - Assurez-vous de la stabilité
   - Vérifiez l'horizontalité pour la balance

#### Porte

1. **Choix de l'emplacement** :
   - Passage habituel de l'animal
   - Protection contre les intempéries
   - Signal WiFi suffisant

2. **Installation mécanique** :
   - Découpez l'ouverture dans la porte/mur
   - Installez le cadre de la porte
   - Fixez le mécanisme d'ouverture

## Configuration logicielle

### Étape 1 : Firmware ESP32

#### Installation de l'environnement

1. **Arduino IDE** :
   ```bash
   # Téléchargez Arduino IDE 2.0+
   # Ajoutez l'URL des cartes ESP32 :
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```

2. **Installation des bibliothèques** :
   - WiFi (intégrée)
   - PubSubClient
   - ArduinoJson
   - ESP32Servo
   - HX711
   - MFRC522
   - ESP32-BLE-Arduino

#### Compilation et téléversement

1. **Configuration** :
   - Sélectionnez la carte "ESP32 Dev Module"
   - Port série approprié
   - Vitesse : 115200 baud

2. **Personnalisation** :
   - Modifiez `/esp32-firmware/include/config.h`
   - Adaptez les pins selon votre câblage
   - Configurez les paramètres par défaut

3. **Téléversement** :
   ```bash
   cd /workspace/project/esp32-firmware
   pio run --target upload
   # ou via Arduino IDE
   ```

### Étape 2 : Backend Firebase

#### Configuration Firebase

1. **Création du projet** :
   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init
   ```

2. **Configuration Firestore** :
   - Copiez les règles depuis `/backend/firestore.rules`
   - Configurez les index depuis `/backend/firestore.indexes.json`

3. **Déploiement des Cloud Functions** :
   ```bash
   cd backend/functions
   npm install
   firebase deploy --only functions
   ```

#### Configuration MQTT (optionnel)

Si vous utilisez votre propre broker MQTT :

1. **Installation Mosquitto** :
   ```bash
   # Ubuntu/Debian
   sudo apt install mosquitto mosquitto-clients
   
   # Configuration SSL
   sudo nano /etc/mosquitto/mosquitto.conf
   ```

2. **Certificats SSL** :
   ```bash
   # Génération des certificats
   openssl req -new -x509 -days 365 -extensions v3_ca -keyout ca.key -out ca.crt
   ```

### Étape 3 : Application mobile

#### Prérequis Flutter

1. **Installation Flutter** :
   ```bash
   # Téléchargez Flutter SDK
   git clone https://github.com/flutter/flutter.git
   export PATH="$PATH:`pwd`/flutter/bin"
   flutter doctor
   ```

2. **Configuration Firebase** :
   ```bash
   cd mobile-app
   firebase init
   # Suivez les instructions pour configurer Firebase
   ```

#### Compilation

1. **Installation des dépendances** :
   ```bash
   cd mobile-app
   flutter pub get
   ```

2. **Configuration** :
   - Modifiez `/mobile-app/lib/config/app_config.dart`
   - Ajoutez vos clés API Firebase
   - Configurez les URLs de votre backend

3. **Compilation Android** :
   ```bash
   flutter build apk --release
   # ou pour un bundle
   flutter build appbundle --release
   ```

4. **Compilation iOS** :
   ```bash
   flutter build ios --release
   # Nécessite Xcode et certificats Apple
   ```

## Configuration réseau

### Étape 1 : Configuration WiFi

#### Première connexion

1. **Mode AP** :
   - L'ESP32 crée un réseau "PetSmartHome-XXXX"
   - Connectez-vous avec le mot de passe par défaut
   - Ouvrez `192.168.4.1` dans votre navigateur

2. **Configuration** :
   - Saisissez vos paramètres WiFi
   - Configurez l'adresse du serveur MQTT
   - Sauvegardez et redémarrez

#### Configuration avancée

1. **IP statique** (optionnel) :
   ```cpp
   // Dans le code ESP32
   WiFi.config(IPAddress(192,168,1,100), 
               IPAddress(192,168,1,1), 
               IPAddress(255,255,255,0));
   ```

2. **Sécurité WPA2-Enterprise** :
   ```cpp
   // Configuration pour réseaux d'entreprise
   WiFi.begin(ssid, WPA2_AUTH_PEAP, identity, username, password);
   ```

### Étape 2 : Configuration MQTT

#### Paramètres de base

1. **Serveur** : `mqtt.pet-smart-home.com` (ou votre serveur)
2. **Port** : 8883 (SSL) ou 1883 (non sécurisé)
3. **Authentification** : Nom d'utilisateur/mot de passe
4. **Certificats SSL** : Pour la sécurité

#### Topics MQTT

```
devices/{deviceId}/status     - Statut de l'appareil
devices/{deviceId}/command    - Commandes vers l'appareil
devices/{deviceId}/telemetry  - Données de télémétrie
devices/{deviceId}/log        - Logs de l'appareil
```

## Tests et validation

### Étape 1 : Tests unitaires

#### Test du distributeur

1. **Test de la balance** :
   ```bash
   # Placez des poids connus
   # Vérifiez la précision ±2g
   ```

2. **Test du servo** :
   ```bash
   # Commande manuelle de distribution
   # Vérifiez la quantité distribuée
   ```

#### Test de la porte

1. **Test RFID** :
   ```bash
   # Approchez un tag RFID
   # Vérifiez la lecture et l'ouverture
   ```

2. **Test Bluetooth** :
   ```bash
   # Activez un appareil BLE
   # Vérifiez la détection et l'accès
   ```

### Étape 2 : Tests d'intégration

#### Test de communication

1. **MQTT** :
   ```bash
   mosquitto_pub -h mqtt.pet-smart-home.com -t "devices/TEST/command" -m '{"action":"test"}'
   ```

2. **Application mobile** :
   - Testez toutes les fonctionnalités
   - Vérifiez les notifications
   - Testez hors ligne/en ligne

#### Test de robustesse

1. **Coupure réseau** :
   - Débranchez le WiFi
   - Vérifiez le fonctionnement autonome
   - Testez la reconnexion automatique

2. **Batterie faible** :
   - Simulez une batterie faible
   - Vérifiez les notifications
   - Testez le mode économie d'énergie

## Maintenance et mises à jour

### Maintenance préventive

#### Hebdomadaire
- Vérification des niveaux de batterie
- Nettoyage des capteurs
- Test des fonctions de base

#### Mensuelle
- Nettoyage complet des mécanismes
- Vérification de l'étanchéité
- Calibrage de la balance

#### Trimestrielle
- Mise à jour du firmware
- Vérification des connexions
- Test de tous les capteurs

### Mises à jour OTA

#### Configuration

1. **Serveur de mise à jour** :
   ```cpp
   // Dans le code ESP32
   ArduinoOTA.setHostname("pet-smart-home-feeder");
   ArduinoOTA.setPassword("your-ota-password");
   ```

2. **Déploiement** :
   ```bash
   # Via PlatformIO
   pio run --target upload --upload-port 192.168.1.100
   ```

## Dépannage

### Problèmes courants

#### Connexion WiFi impossible

**Symptômes** :
- LED clignote rapidement
- Pas de réseau AP créé

**Solutions** :
1. Vérifiez la configuration réseau
2. Réinitialisez les paramètres (bouton reset 10s)
3. Vérifiez la compatibilité 2.4GHz

#### Distributeur ne fonctionne pas

**Symptômes** :
- Pas de distribution malgré la commande
- Quantités incorrectes

**Solutions** :
1. Calibrez la balance
2. Vérifiez le mécanisme (bourrage)
3. Contrôlez l'alimentation du servo

#### Porte ne s'ouvre pas

**Symptômes** :
- RFID détecté mais pas d'ouverture
- Servo ne bouge pas

**Solutions** :
1. Vérifiez l'alimentation
2. Contrôlez les autorisations
3. Testez le servo manuellement

### Codes d'erreur

| Code | Description | Action |
|------|-------------|---------|
| E001 | WiFi timeout | Vérifier réseau |
| E002 | MQTT déconnecté | Vérifier serveur |
| E003 | Capteur défaillant | Reconnecter/remplacer |
| E004 | Batterie critique | Recharger |
| E005 | Servo bloqué | Nettoyer mécanisme |

### Support technique

Pour obtenir de l'aide :

1. **Logs de débogage** :
   ```bash
   # Connectez-vous au port série
   screen /dev/ttyUSB0 115200
   ```

2. **Interface web** :
   - Accédez à l'IP de l'appareil
   - Consultez les informations système
   - Téléchargez les logs

3. **Contact support** :
   - Email : support@pet-smart-home.com
   - Forum : https://community.pet-smart-home.com
   - GitHub : https://github.com/pet-smart-home/issues

## Annexes

### Annexe A : Schémas électriques

Consultez le dossier `/hardware/schematics/` pour :
- Schéma distributeur complet
- Schéma porte intelligente
- PCB layouts (optionnel)

### Annexe B : Liste des composants

Consultez `/hardware/components_list.md` pour :
- Références exactes des composants
- Fournisseurs recommandés
- Coûts estimés

### Annexe C : Fichiers 3D

Consultez `/hardware/3d-models/` pour :
- Fichiers STL prêts à imprimer
- Fichiers sources (Fusion 360)
- Instructions d'assemblage

### Annexe D : Configuration avancée

#### Serveur MQTT personnalisé

```bash
# Installation Mosquitto avec SSL
sudo apt update
sudo apt install mosquitto mosquitto-clients

# Configuration SSL
sudo nano /etc/mosquitto/mosquitto.conf
```

#### Base de données locale

```bash
# Installation InfluxDB pour les métriques
sudo apt install influxdb
sudo systemctl enable influxdb
```

#### Monitoring avancé

```bash
# Installation Grafana pour les tableaux de bord
sudo apt install grafana
sudo systemctl enable grafana-server
```
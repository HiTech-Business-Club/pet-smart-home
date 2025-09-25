# Guide de Déploiement - Pet Smart Home

## Vue d'ensemble

Ce guide détaille les étapes nécessaires pour déployer le système Pet Smart Home complet en production.

## Prérequis

### Comptes et Services
- [ ] Compte Firebase avec projet configuré
- [ ] Compte GitHub avec repository configuré
- [ ] Compte Google Play Console (Android)
- [ ] Compte Apple Developer (iOS)
- [ ] Serveur pour héberger le serveur OTA
- [ ] Broker MQTT (ou service cloud)

### Outils Locaux
- [ ] Flutter SDK 3.16+
- [ ] Android Studio / Xcode
- [ ] Firebase CLI
- [ ] Git
- [ ] Node.js 18+
- [ ] PlatformIO

## 1. Configuration Firebase Production

### 1.1 Créer le Projet Firebase
```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter à Firebase
firebase login

# Créer un nouveau projet
firebase projects:create pet-smart-home-prod
```

### 1.2 Configurer les Services
```bash
# Initialiser le projet
firebase init

# Sélectionner :
# - Firestore
# - Functions
# - Hosting
# - Storage
# - Authentication
```

### 1.3 Déployer les Règles et Functions
```bash
cd backend
firebase use pet-smart-home-prod
firebase deploy
```

## 2. Configuration des Environnements

### 2.1 Variables d'Environnement
Créer un fichier `.env.production` :
```env
FIREBASE_PROJECT_ID=pet-smart-home-prod
FIREBASE_API_KEY=your_api_key
MQTT_BROKER_URL=mqtt://your-broker.com:8883
MQTT_USERNAME=your_username
MQTT_PASSWORD=your_password
OTA_SERVER_URL=https://ota.pet-smart-home.com
OTA_AUTH_TOKEN=your_secure_token
```

### 2.2 Secrets GitHub
Configurer dans GitHub Settings > Secrets :
- `FIREBASE_TOKEN`
- `FIREBASE_PROJECT_ID`
- `ANDROID_KEYSTORE`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_STORE_PASSWORD`

## 3. Déploiement du Firmware ESP32

### 3.1 Configuration Production
```bash
cd esp32-firmware

# Utiliser la configuration production
cp platformio_production.ini platformio.ini

# Modifier les variables dans src/config.h
# - WiFi credentials
# - MQTT broker
# - OTA server URL
```

### 3.2 Compilation et Upload
```bash
# Compiler le firmware
pio run -e esp32dev_production

# Upload via OTA (pour les mises à jour)
pio run -e esp32dev_production -t upload --upload-port 192.168.1.100
```

## 4. Déploiement de l'Application Mobile

### 4.1 Configuration Android
```bash
cd mobile-app

# Générer le keystore de production
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# Créer key.properties
echo "storePassword=your_store_password" > android/key.properties
echo "keyPassword=your_key_password" >> android/key.properties
echo "keyAlias=upload" >> android/key.properties
echo "storeFile=upload-keystore.jks" >> android/key.properties
```

### 4.2 Build Production
```bash
# Build APK de production
flutter build apk --release --flavor production

# Build App Bundle pour Google Play
flutter build appbundle --release --flavor production
```

### 4.3 Configuration iOS
```bash
# Ouvrir le projet iOS
open ios/Runner.xcworkspace

# Dans Xcode :
# 1. Configurer le Team ID
# 2. Configurer les certificats
# 3. Configurer les provisioning profiles
```

### 4.4 Build iOS
```bash
# Build pour iOS
flutter build ios --release --flavor production
```

## 5. Déploiement du Serveur OTA

### 5.1 Configuration Serveur
```bash
cd ota-server

# Installer les dépendances
npm install

# Configurer les variables d'environnement
export PORT=8080
export OTA_AUTH_TOKEN=your_secure_token
export NODE_ENV=production
```

### 5.2 Déploiement avec Docker
```bash
# Créer l'image Docker
docker build -t pet-smart-ota .

# Lancer le conteneur
docker run -d \
  --name pet-smart-ota \
  -p 8080:8080 \
  -e OTA_AUTH_TOKEN=your_token \
  -v /path/to/firmwares:/app/firmwares \
  pet-smart-ota
```

## 6. Configuration du Monitoring

### 6.1 Déploiement du Service de Monitoring
```bash
cd monitoring

# Installer les dépendances
npm install

# Configurer Firebase Service Account
# Télécharger le fichier JSON depuis Firebase Console
cp path/to/service-account.json firebase-service-account.json

# Lancer le service
npm start
```

### 6.2 Configuration des Alertes
```bash
# Variables d'environnement pour le monitoring
export FIREBASE_DATABASE_URL=https://pet-smart-home-prod-default-rtdb.firebaseio.com
export MQTT_BROKER_URL=mqtt://your-broker.com:8883
export MQTT_USERNAME=monitor_user
export MQTT_PASSWORD=monitor_password
```

## 7. Configuration CI/CD

### 7.1 GitHub Actions
Le pipeline CI/CD est déjà configuré dans `.github/workflows/ci-cd.yml`.

### 7.2 Environnements GitHub
Configurer dans GitHub Settings > Environments :
- `staging`
- `production`

Avec les secrets appropriés pour chaque environnement.

## 8. Tests de Déploiement

### 8.1 Tests Firmware
```bash
# Tester la connexion MQTT
mosquitto_pub -h your-broker.com -p 8883 \
  -t "pet-smart-home/test/heartbeat" \
  -m '{"deviceId":"test","status":"online"}'
```

### 8.2 Tests Application Mobile
```bash
# Tester l'application en mode release
flutter run --release --flavor production
```

### 8.3 Tests OTA
```bash
# Tester l'endpoint de vérification
curl "http://your-ota-server.com/api/check-update?deviceId=test&currentVersion=1.0.0"
```

## 9. Monitoring Post-Déploiement

### 9.1 Métriques à Surveiller
- Nombre d'appareils connectés
- Taux de succès des distributions
- Niveau de batterie des appareils
- Erreurs de communication
- Performance de l'application

### 9.2 Alertes Configurées
- Appareil hors ligne > 10 minutes
- Batterie < 20%
- Erreur critique sur un appareil
- Niveau de nourriture < 10%

## 10. Maintenance

### 10.1 Mises à Jour Firmware
```bash
# Upload nouveau firmware via OTA server
curl -X POST http://your-ota-server.com/api/upload-firmware \
  -H "Authorization: Bearer your_token" \
  -F "firmware=@firmware_v1.1.0.bin" \
  -F "version=1.1.0" \
  -F "changelog=Bug fixes and improvements"
```

### 10.2 Mises à Jour Application
```bash
# Nouvelle version de l'app
flutter build appbundle --release --flavor production
# Upload sur Google Play Console
```

## 11. Sécurité

### 11.1 Certificats SSL/TLS
- Configurer HTTPS pour tous les endpoints
- Utiliser des certificats valides
- Renouveler avant expiration

### 11.2 Authentification
- Rotation régulière des tokens
- Audit des accès
- Monitoring des tentatives d'intrusion

## 12. Sauvegarde et Récupération

### 12.1 Sauvegarde Firebase
```bash
# Export des données Firestore
gcloud firestore export gs://your-backup-bucket/firestore-backup
```

### 12.2 Sauvegarde des Firmwares
```bash
# Sauvegarde automatique des firmwares OTA
rsync -av /path/to/firmwares/ backup-server:/backups/firmwares/
```

## Checklist de Déploiement

### Pré-déploiement
- [ ] Tests unitaires passent
- [ ] Tests d'intégration passent
- [ ] Configuration de production validée
- [ ] Certificats et clés configurés
- [ ] Sauvegarde des données actuelles

### Déploiement
- [ ] Firebase déployé
- [ ] Firmware compilé et testé
- [ ] Application mobile buildée
- [ ] Serveur OTA déployé
- [ ] Monitoring configuré

### Post-déploiement
- [ ] Tests de fumée réussis
- [ ] Monitoring actif
- [ ] Alertes configurées
- [ ] Documentation mise à jour
- [ ] Équipe notifiée

## Support et Dépannage

### Logs Importants
- Firebase Functions: Firebase Console > Functions > Logs
- Application Mobile: Firebase Console > Crashlytics
- Serveur OTA: Logs Docker ou PM2
- Monitoring: Logs du service de monitoring

### Contacts d'Urgence
- Équipe de développement
- Administrateur Firebase
- Support infrastructure

---

**Version**: 1.0.0  
**Dernière mise à jour**: 25 septembre 2025  
**Responsable**: Équipe Pet Smart Home
# 🐾 Pet Smart Home - Système Intelligent pour Animaux de Compagnie

[![Build Status](https://github.com/HiTech-Business-Club/pet-smart-home/workflows/Pet%20Smart%20Home%20CI/CD%20Pipeline/badge.svg)](https://github.com/HiTech-Business-Club/pet-smart-home/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.16+-blue.svg)](https://flutter.dev/)
[![ESP32](https://img.shields.io/badge/ESP32-Arduino-green.svg)](https://www.espressif.com/en/products/socs/esp32)
[![Firebase](https://img.shields.io/badge/Firebase-9.0+-orange.svg)](https://firebase.google.com/)

## 🌟 Vue d'ensemble

Pet Smart Home est un système IoT complet qui révolutionne la façon dont vous prenez soin de vos animaux de compagnie. Combinant des appareils ESP32 intelligents, une application mobile intuitive et un backend cloud robuste, notre solution offre une surveillance et un contrôle automatisés pour le bien-être de vos compagnons.

### ✨ Fonctionnalités Principales

#### 🍽️ Distributeur Intelligent de Nourriture
- **Distribution automatique** programmable selon des horaires personnalisés
- **Contrôle des portions** avec capteur de poids intégré
- **Surveillance du niveau** de nourriture avec alertes
- **Historique complet** des repas et statistiques

#### 🚪 Porte d'Accès Intelligente
- **Contrôle d'accès RFID** pour animaux autorisés
- **Connexion Bluetooth** pour contrôle à distance
- **Logs d'accès** détaillés avec horodatage
- **Notifications** en temps réel des entrées/sorties

#### 📱 Application Mobile
- **Interface moderne** et intuitive
- **Contrôle à distance** de tous les appareils
- **Notifications push** pour tous les événements
- **Statistiques détaillées** et rapports
- **Gestion multi-animaux** et multi-appareils

#### ☁️ Backend Cloud
- **Synchronisation temps réel** avec Firebase
- **Stockage sécurisé** des données
- **API REST** complète
- **Authentification** utilisateur robuste

## 🏗️ Architecture Technique

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ESP32 Devices │    │  Mobile App     │    │  Cloud Backend  │
│                 │    │                 │    │                 │
│ • Feeder        │◄──►│ • Flutter       │◄──►│ • Firebase      │
│ • Smart Door    │    │ • iOS/Android   │    │ • Cloud Funcs   │
│ • Sensors       │    │ • Real-time UI  │    │ • Firestore     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │  MQTT Broker    │
                    │  • Real-time    │
                    │  • Secure       │
                    │  • Scalable     │
                    └─────────────────┘
```

## 🚀 Démarrage Rapide

### Prérequis
- Flutter SDK 3.16+
- PlatformIO ou Arduino IDE
- Compte Firebase
- Appareils ESP32

### Installation

1. **Cloner le repository**
```bash
git clone https://github.com/HiTech-Business-Club/pet-smart-home.git
cd pet-smart-home
```

2. **Configuration Firebase**
```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter et configurer
firebase login
firebase use --add your-project-id
```

3. **Application Mobile**
```bash
cd mobile-app
flutter pub get
flutter run
```

4. **Firmware ESP32**
```bash
cd esp32-firmware
pio run -t upload
```

Pour des instructions détaillées, consultez le [Guide d'Installation](docs/installation_guide.md).

## 📁 Structure du Projet

```
pet-smart-home/
├── 📱 mobile-app/          # Application Flutter
│   ├── lib/
│   │   ├── screens/        # Écrans de l'application
│   │   ├── services/       # Services Firebase & API
│   │   ├── models/         # Modèles de données
│   │   └── widgets/        # Composants réutilisables
│   └── pubspec.yaml
├── 🔧 esp32-firmware/      # Firmware pour ESP32
│   ├── src/
│   │   ├── main.cpp        # Code principal
│   │   ├── wifi_manager.h  # Gestion WiFi
│   │   ├── mqtt_client.h   # Client MQTT
│   │   └── sensors/        # Drivers capteurs
│   └── platformio.ini
├── ☁️ backend/             # Backend Firebase
│   ├── functions/          # Cloud Functions
│   ├── firestore.rules     # Règles Firestore
│   └── storage.rules       # Règles Storage
├── 📊 monitoring/          # Système de monitoring
│   └── device-monitor.js   # Service de surveillance
├── 🔄 ota-server/          # Serveur de mise à jour
│   └── server.js           # API OTA
├── 🛠️ config/             # Configurations
│   └── environments/       # Configs par environnement
├── 📚 docs/               # Documentation
└── 🚀 .github/workflows/  # CI/CD Pipeline
```

## 🔧 Technologies Utilisées

### Frontend
- **Flutter** - Framework mobile cross-platform
- **Dart** - Langage de programmation
- **Firebase SDK** - Intégration cloud

### Backend
- **Firebase** - Platform-as-a-Service
- **Cloud Functions** - Serverless computing
- **Firestore** - Base de données NoSQL
- **Cloud Storage** - Stockage de fichiers

### IoT/Hardware
- **ESP32** - Microcontrôleur WiFi/Bluetooth
- **Arduino Framework** - Développement embarqué
- **PlatformIO** - Environnement de développement
- **MQTT** - Protocole de communication IoT

### DevOps
- **GitHub Actions** - CI/CD Pipeline
- **Docker** - Containerisation
- **Node.js** - Runtime JavaScript

## 📊 Métriques du Projet

- **50+ fichiers** de code source
- **10,000+ lignes** de code
- **25+ dépendances** Flutter
- **15+ bibliothèques** ESP32
- **100% couverture** des fonctionnalités principales

## 🔒 Sécurité

- **Chiffrement TLS/SSL** pour toutes les communications
- **Authentification Firebase** avec tokens JWT
- **Règles de sécurité Firestore** granulaires
- **Validation côté serveur** de toutes les données
- **Certificats OTA** pour les mises à jour sécurisées

## 🚀 Déploiement

Le système supporte trois environnements :

- **Development** - Tests locaux
- **Staging** - Tests d'intégration
- **Production** - Environnement live

Consultez le [Guide de Déploiement](DEPLOYMENT_GUIDE.md) pour les instructions complètes.

## 📈 Monitoring et Analytics

- **Surveillance temps réel** des appareils
- **Alertes automatiques** (batterie faible, déconnexion, etc.)
- **Statistiques d'utilisation** détaillées
- **Logs centralisés** avec Firebase
- **Métriques de performance** de l'application

## 🤝 Contribution

Nous accueillons les contributions ! Voici comment participer :

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit vos changements (`git commit -m 'Add some AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

## 📝 Documentation

- [Guide d'Installation](docs/installation_guide.md)
- [Documentation d'Architecture](docs/architecture.md)
- [Manuel Utilisateur](docs/user_manual.md)
- [Guide de Déploiement](DEPLOYMENT_GUIDE.md)
- [Rapport de Validation](VALIDATION_REPORT.md)

## 🐛 Signaler un Bug

Si vous trouvez un bug, veuillez [ouvrir une issue](https://github.com/HiTech-Business-Club/pet-smart-home/issues) avec :
- Description détaillée du problème
- Étapes pour reproduire
- Environnement (OS, version de l'app, etc.)
- Logs si disponibles

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 👥 Équipe

Développé avec ❤️ par l'équipe **HiTech Business Club**

- **Architecture & Backend** - Équipe Cloud
- **Application Mobile** - Équipe Flutter
- **Firmware IoT** - Équipe Embedded
- **DevOps & Infrastructure** - Équipe Platform

## 🙏 Remerciements

- [Flutter Team](https://flutter.dev/) pour le framework mobile
- [Espressif](https://www.espressif.com/) pour les microcontrôleurs ESP32
- [Firebase](https://firebase.google.com/) pour la plateforme cloud
- [PlatformIO](https://platformio.org/) pour l'environnement de développement IoT

## 📞 Support

- **Email** : support@pet-smart-home.com
- **Discord** : [Rejoindre notre serveur](https://discord.gg/pet-smart-home)
- **Documentation** : [docs.pet-smart-home.com](https://docs.pet-smart-home.com)

---

<div align="center">
  <strong>🐾 Prenez soin de vos animaux avec intelligence ! 🐾</strong>
</div>
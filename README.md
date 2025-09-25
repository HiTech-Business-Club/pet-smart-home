# Pet Smart Home - Assistant Domotique Intelligent pour Animaux de Compagnie

## 🐾 Vue d'ensemble

Pet Smart Home est un système domotique complet conçu pour prendre soin de vos animaux de compagnie à distance. Le projet combine un distributeur automatique de nourriture, une porte intelligente avec accès RFID/Bluetooth, et une application mobile Flutter pour un contrôle total.

### ✨ Fonctionnalités principales

- **Distributeur automatique de nourriture** avec programmation d'horaires
- **Porte intelligente** avec accès RFID/Bluetooth sécurisé
- **Application mobile Flutter** intuitive et complète
- **Backend Firebase** avec notifications push en temps réel
- **Interface web** pour configuration avancée
- **Monitoring** et historique complet des activités

## 🏗️ Architecture du Projet

```
pet-smart-home/
├── mobile-app/          # Application Flutter
├── esp32-firmware/      # Code pour microcontrôleur ESP32
├── backend/            # Configuration Firebase/Cloud
├── hardware/           # Schémas et spécifications matériel
├── docs/              # Documentation technique
└── tests/             # Tests d'intégration
```

## 🔧 Technologies Utilisées

### Hardware
- **ESP32** - Microcontrôleur principal (Wi-Fi + Bluetooth)
- **MFRC522** - Lecteur RFID
- **Capteur ultrasonique** - Détection niveau nourriture
- **Servomoteur SG90** - Mécanisme de distribution
- **Module BLE HM-10** - Communication Bluetooth

### Software
- **Flutter** - Application mobile cross-platform
- **Firebase** - Backend as a Service
- **Arduino IDE/PlatformIO** - Développement ESP32
- **MQTT** - Protocole de communication IoT

## 🚀 Fonctionnalités Principales

### Distributeur de Nourriture
- ⏰ Programmation des horaires de repas
- ⚖️ Contrôle précis des portions
- 📊 Détection automatique du niveau de croquettes
- 📱 Mode manuel via application
- 🔒 Système anti-bourrage

### Porte Intelligente
- 🏷️ Reconnaissance collier RFID/BLE
- 🚪 Ouverture automatique sécurisée
- 📝 Historique des passages
- 🚨 Notifications d'intrusion
- 📱 Contrôle manuel à distance

### Application Mobile
- 🎨 Interface intuitive et moderne
- 👥 Gestion multi-animaux
- 📊 Historique complet des événements
- 🔔 Notifications temps réel
- 🔐 Authentification sécurisée

## 🔒 Sécurité

- Chiffrement AES/SSL des données
- Authentification obligatoire
- Protection anti-intrusion
- Batterie de secours
- Mise à jour OTA sécurisée

## 📦 Installation et Configuration

*Instructions détaillées à venir dans la documentation*

## 🤝 Contribution

Ce projet est développé selon les spécifications du cahier des charges v1.0 du 23/09/2025.

## 📄 Licence

*À définir*

---

**Version:** 1.0  
**Date:** 25/09/2025  
**Statut:** En développement
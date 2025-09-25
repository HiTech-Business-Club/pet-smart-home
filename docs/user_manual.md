# Manuel Utilisateur - Pet Smart Home

## Table des matières

1. [Introduction](#introduction)
2. [Installation et Configuration](#installation-et-configuration)
3. [Première utilisation](#première-utilisation)
4. [Gestion des animaux](#gestion-des-animaux)
5. [Distributeur de nourriture](#distributeur-de-nourriture)
6. [Porte intelligente](#porte-intelligente)
7. [Notifications](#notifications)
8. [Dépannage](#dépannage)
9. [FAQ](#faq)

## Introduction

Pet Smart Home est un système domotique intelligent conçu pour prendre soin de vos animaux de compagnie à distance. Le système comprend :

- **Distributeur automatique de nourriture** avec programmation d'horaires
- **Porte intelligente** avec accès RFID/Bluetooth
- **Application mobile** pour contrôle et surveillance
- **Notifications en temps réel** pour rester informé

### Fonctionnalités principales

- ✅ Distribution automatique de nourriture selon des horaires programmés
- ✅ Contrôle d'accès intelligent pour vos animaux
- ✅ Surveillance en temps réel via l'application mobile
- ✅ Historique des activités et statistiques
- ✅ Notifications push pour tous les événements importants
- ✅ Interface web pour configuration avancée

## Installation et Configuration

### Prérequis

- Réseau WiFi 2.4GHz
- Smartphone Android 6.0+ ou iOS 12.0+
- Compte Google ou Apple pour l'authentification

### Installation de l'application mobile

1. **Android** : Téléchargez l'application depuis le Google Play Store
2. **iOS** : Téléchargez l'application depuis l'App Store
3. Ouvrez l'application et créez votre compte

### Configuration du matériel

#### Distributeur de nourriture

1. **Assemblage** :
   - Montez le servo-moteur sur le mécanisme de distribution
   - Connectez la balance (capteur HX711) sous le réservoir
   - Fixez l'ESP32 dans le boîtier étanche

2. **Connexions électriques** :
   ```
   ESP32 Pin 18 → Servo moteur (Signal)
   ESP32 Pin 19 → HX711 DOUT
   ESP32 Pin 21 → HX711 SCK
   ESP32 Pin 35 → Capteur batterie
   ESP32 Pin 2  → LED de statut
   ```

3. **Première configuration** :
   - Alimentez l'appareil
   - Connectez-vous au réseau WiFi "PetSmartHome-XXXX"
   - Ouvrez votre navigateur sur `192.168.4.1`
   - Configurez votre réseau WiFi

#### Porte intelligente

1. **Installation mécanique** :
   - Montez le servo-moteur sur le mécanisme de la porte
   - Installez le lecteur RFID près de l'entrée
   - Fixez l'ESP32 dans un boîtier étanche

2. **Connexions électriques** :
   ```
   ESP32 Pin 16 → Servo porte (Signal)
   ESP32 Pin 5  → RFID SS
   ESP32 Pin 17 → RFID RST
   ESP32 Pin 4  → Buzzer
   ```

3. **Configuration** :
   - Suivez la même procédure que pour le distributeur
   - Testez l'ouverture/fermeture manuelle

## Première utilisation

### 1. Création de compte

1. Ouvrez l'application Pet Smart Home
2. Appuyez sur "Créer un compte"
3. Saisissez vos informations :
   - Nom complet
   - Adresse email
   - Mot de passe sécurisé
4. Acceptez les conditions d'utilisation
5. Vérifiez votre email

### 2. Ajout d'appareils

1. Dans l'application, appuyez sur "Ajouter un appareil"
2. Sélectionnez le type d'appareil
3. Suivez les instructions de connexion
4. Nommez votre appareil
5. Testez la connexion

### 3. Configuration initiale

1. **Calibrage du distributeur** :
   - Videz complètement le réservoir
   - Appuyez sur "Calibrer la balance"
   - Suivez les instructions à l'écran

2. **Test de la porte** :
   - Vérifiez l'ouverture/fermeture
   - Ajustez la durée d'ouverture si nécessaire

## Gestion des animaux

### Ajouter un animal

1. Allez dans l'onglet "Animaux"
2. Appuyez sur le bouton "+"
3. Remplissez les informations :
   - **Nom** : Nom de votre animal
   - **Espèce** : Chat, Chien, Lapin, etc.
   - **Race** : (optionnel)
   - **Âge** : En mois
   - **Poids** : En kilogrammes

### Configuration de l'identification

Pour permettre l'accès automatique à la porte :

1. **Tag RFID** :
   - Collez le tag RFID sur le collier
   - Scannez le tag avec l'application
   - Associez-le à votre animal

2. **Bluetooth** :
   - Activez le Bluetooth sur le collier
   - Recherchez l'appareil dans l'application
   - Associez l'adresse MAC à votre animal

### Modifier un animal

1. Appuyez sur l'animal dans la liste
2. Sélectionnez "Modifier"
3. Modifiez les informations nécessaires
4. Sauvegardez les changements

## Distributeur de nourriture

### Distribution manuelle

1. Allez dans l'onglet "Distributeur"
2. Sélectionnez la quantité (10-200g)
3. Choisissez l'animal (optionnel)
4. Appuyez sur "Distribuer maintenant"

### Programmation d'horaires

1. Appuyez sur "Programmer" dans l'onglet Distributeur
2. Créez un nouvel horaire :
   - **Nom** : Ex. "Repas de Minou"
   - **Animal** : Sélectionnez votre animal
   - **Horaires** : Ajoutez les heures de repas
   - **Quantités** : Définissez les portions
   - **Jours** : Choisissez les jours de la semaine

### Exemple d'horaire type

```
Nom: Repas quotidiens de Minou
Animal: Minou (Chat)
Horaires:
- 08:00 - 50g (Tous les jours)
- 18:00 - 50g (Tous les jours)
Total journalier: 100g
```

### Surveillance du niveau

- Le niveau de nourriture est affiché en temps réel
- Vous recevrez une notification quand le niveau est bas
- Rechargez le réservoir quand nécessaire

## Porte intelligente

### Contrôle manuel

1. Allez dans l'onglet "Porte"
2. Utilisez les boutons :
   - **Ouvrir** : Ouvre la porte immédiatement
   - **Fermer** : Ferme la porte
   - **Verrouiller** : Bloque tous les accès
   - **Déverrouiller** : Autorise les accès

### Gestion des accès

1. **Autoriser un animal** :
   - Appuyez sur "Ajouter" dans la section "Animaux autorisés"
   - Sélectionnez l'animal
   - Configurez son identification (RFID/BLE)

2. **Retirer un accès** :
   - Appuyez sur l'animal dans la liste
   - Sélectionnez "Retirer l'accès"
   - Confirmez la suppression

### Historique des accès

- Consultez tous les passages dans l'historique
- Filtrez par animal, date, ou statut
- Exportez les données si nécessaire

### Paramètres de la porte

- **Durée d'ouverture** : 5-60 secondes
- **Fermeture automatique** : Activée par défaut
- **Détection d'intrusion** : Notifications d'accès non autorisés

## Notifications

### Types de notifications

1. **Distributeur** :
   - Distribution réussie
   - Niveau de nourriture bas
   - Bourrage détecté
   - Maintenance requise

2. **Porte** :
   - Accès autorisé/refusé
   - Porte laissée ouverte
   - Tentative d'intrusion
   - Batterie faible

3. **Système** :
   - Appareil hors ligne
   - Mise à jour disponible
   - Erreur de connexion

### Configuration des notifications

1. Allez dans "Paramètres" > "Notifications"
2. Activez/désactivez chaque type
3. Choisissez les heures de silence
4. Configurez les notifications d'urgence

## Dépannage

### Problèmes courants

#### L'appareil ne se connecte pas au WiFi

**Solutions** :
1. Vérifiez que le réseau est en 2.4GHz
2. Rapprochez l'appareil du routeur
3. Redémarrez l'appareil (bouton reset 5 secondes)
4. Reconfigurez le WiFi via l'interface web

#### Le distributeur ne fonctionne pas

**Vérifications** :
1. Niveau de batterie > 20%
2. Réservoir de nourriture non vide
3. Mécanisme non bloqué
4. Connexion réseau active

**Solutions** :
1. Rechargez la batterie
2. Nettoyez le mécanisme
3. Calibrez la balance
4. Redémarrez l'appareil

#### La porte ne reconnaît pas l'animal

**Vérifications** :
1. Tag RFID bien fixé au collier
2. Distance < 5cm du lecteur
3. Animal autorisé dans l'application
4. Batterie du lecteur > 20%

**Solutions** :
1. Repositionnez le tag RFID
2. Nettoyez le lecteur
3. Re-scannez le tag dans l'application
4. Vérifiez les autorisations

#### Notifications non reçues

**Solutions** :
1. Vérifiez les paramètres de notification
2. Autorisez les notifications dans les paramètres du téléphone
3. Vérifiez la connexion internet
4. Redémarrez l'application

### Codes d'erreur

| Code | Description | Solution |
|------|-------------|----------|
| E001 | Erreur de connexion WiFi | Vérifier les paramètres réseau |
| E002 | Capteur de poids défaillant | Recalibrer la balance |
| E003 | Servo moteur bloqué | Nettoyer le mécanisme |
| E004 | Batterie critique | Recharger immédiatement |
| E005 | Lecteur RFID défaillant | Redémarrer l'appareil |

### Maintenance préventive

#### Hebdomadaire
- Vérifiez le niveau de nourriture
- Nettoyez les capteurs
- Testez l'ouverture/fermeture de la porte

#### Mensuelle
- Nettoyage complet des mécanismes
- Vérification des connexions
- Mise à jour du firmware si disponible

#### Trimestrielle
- Calibrage de la balance
- Vérification de l'étanchéité
- Test de tous les capteurs

## FAQ

### Questions générales

**Q: Combien d'animaux puis-je enregistrer ?**
R: Jusqu'à 20 animaux par compte utilisateur.

**Q: Le système fonctionne-t-il sans internet ?**
R: Les fonctions de base (distribution programmée, accès RFID) fonctionnent hors ligne. La surveillance à distance nécessite une connexion internet.

**Q: Quelle est l'autonomie de la batterie ?**
R: 2-4 semaines selon l'utilisation, avec batterie 18650 de 3000mAh.

**Q: Le système est-il étanche ?**
R: Oui, indice de protection IP65 pour une utilisation extérieure.

### Questions techniques

**Q: Puis-je utiliser mon propre serveur MQTT ?**
R: Oui, configurez l'adresse dans l'interface web de l'appareil.

**Q: Comment sauvegarder mes données ?**
R: Les données sont automatiquement sauvegardées dans le cloud Firebase.

**Q: Puis-je contrôler plusieurs maisons ?**
R: Oui, créez des groupes d'appareils par localisation.

### Support technique

Pour toute question non couverte par ce manuel :

- **Email** : support@pet-smart-home.com
- **Téléphone** : +33 1 23 45 67 89
- **Chat en ligne** : Disponible dans l'application
- **Forum communautaire** : https://community.pet-smart-home.com

**Heures d'ouverture du support** :
- Lundi à Vendredi : 9h-18h
- Week-end : 10h-16h
- Support d'urgence 24h/7j pour les problèmes critiques
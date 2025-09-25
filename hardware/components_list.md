# Liste des Composants Hardware

## Microcontrôleur Principal
- **ESP32 DevKit V1** - Microcontrôleur avec Wi-Fi et Bluetooth intégrés
  - Tension: 3.3V/5V
  - GPIO: 30 pins
  - Mémoire: 520KB SRAM, 4MB Flash

## Capteurs et Détecteurs

### Pour le Distributeur de Nourriture
- **Capteur Ultrasonique HC-SR04** - Détection niveau de croquettes
  - Portée: 2cm à 400cm
  - Précision: 3mm
  - Tension: 5V

### Pour la Porte Intelligente
- **Module RFID MFRC522** - Lecture des tags RFID
  - Fréquence: 13.56MHz
  - Interface: SPI
  - Tension: 3.3V

- **Module Bluetooth BLE HM-10** - Communication Bluetooth Low Energy
  - Version: Bluetooth 4.0
  - Portée: 100m (en champ libre)
  - Tension: 3.3V-6V

## Actionneurs

### Distributeur de Nourriture
- **Servomoteur SG90** - Mécanisme de distribution
  - Couple: 1.8kg/cm
  - Vitesse: 0.1s/60°
  - Tension: 4.8V-6V

### Porte Intelligente
- **Servomoteur MG996R** - Ouverture/fermeture porte
  - Couple: 9.4kg/cm
  - Vitesse: 0.2s/60°
  - Tension: 4.8V-7.2V

## Alimentation
- **Adaptateur secteur 12V 3A** - Alimentation principale
- **Module régulateur LM2596** - Conversion 12V vers 5V/3.3V
- **Batterie Li-Po 7.4V 2200mAh** - Alimentation de secours
- **Module de charge TP4056** - Gestion charge batterie

## Connectivité
- **Antenne Wi-Fi 2.4GHz** - Amélioration signal Wi-Fi
- **Antenne Bluetooth** - Amélioration signal BLE

## Affichage et Interface
- **Écran OLED 0.96" I2C** - Affichage statut local
- **LED RGB WS2812** - Indicateurs visuels
- **Buzzer passif** - Alertes sonores

## Boîtier et Mécanique
- **Boîtier étanche IP65** - Protection électronique
- **Vis et fixations** - Assemblage mécanique
- **Joints d'étanchéité** - Protection contre l'humidité

## Colliers pour Animaux
- **Tags RFID 125kHz** - Identification passive
- **Modules BLE nRF52832** - Identification active Bluetooth

## Outils de Développement
- **Breadboard** - Prototypage
- **Câbles Dupont** - Connexions
- **Résistances diverses** - Pull-up, limitation courant
- **Condensateurs** - Filtrage alimentation

## Coût Estimé
- **Total approximatif: 150-200€** pour un prototype complet
- **Version production: 80-120€** par unité (en série)

## Fournisseurs Recommandés
- **AliExpress** - Composants électroniques
- **Amazon** - Composants rapides
- **Mouser/Digikey** - Composants professionnels
- **Local** - Boîtiers et mécanique
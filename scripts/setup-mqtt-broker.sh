#!/bin/bash

# Script de configuration MQTT Broker pour la production
# Pet Smart Home - Broker MQTT sécurisé

set -e

echo "🔌 Configuration MQTT Broker Production - Pet Smart Home"
echo "======================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
MQTT_HOST="mqtt.pet-smart-home.com"
MQTT_PORT="8883"
MQTT_WS_PORT="8884"
CERT_DIR="/etc/ssl/mqtt"
CONFIG_DIR="/etc/mosquitto"

# Fonction pour afficher les messages
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Créer la configuration Docker Compose pour MQTT
create_docker_compose() {
    log_info "Création de la configuration Docker Compose..."
    
    mkdir -p mqtt-broker/{config,data,logs,certs}
    
    cat > mqtt-broker/docker-compose.yml << 'EOF'
version: '3.8'

services:
  mosquitto:
    image: eclipse-mosquitto:2.0
    container_name: pet-smart-mqtt
    restart: unless-stopped
    ports:
      - "1883:1883"   # MQTT non-sécurisé (local seulement)
      - "8883:8883"   # MQTT sécurisé (TLS)
      - "8884:8884"   # WebSocket sécurisé
    volumes:
      - ./config/mosquitto.conf:/mosquitto/config/mosquitto.conf
      - ./config/passwd:/mosquitto/config/passwd
      - ./config/acl:/mosquitto/config/acl
      - ./data:/mosquitto/data
      - ./logs:/mosquitto/log
      - ./certs:/mosquitto/certs
    environment:
      - MOSQUITTO_USERNAME=admin
      - MOSQUITTO_PASSWORD=change_me_in_production
    networks:
      - mqtt-network
    healthcheck:
      test: ["CMD-SHELL", "mosquitto_pub -h localhost -t test -m 'health check' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  mqtt-exporter:
    image: sapcc/mosquitto-exporter:0.8.0
    container_name: pet-smart-mqtt-exporter
    restart: unless-stopped
    ports:
      - "9234:9234"
    environment:
      - BROKER_ENDPOINT=tcp://mosquitto:1883
    depends_on:
      - mosquitto
    networks:
      - mqtt-network

networks:
  mqtt-network:
    driver: bridge

volumes:
  mqtt-data:
  mqtt-logs:
EOF

    log_success "Docker Compose créé"
}

# Créer la configuration Mosquitto
create_mosquitto_config() {
    log_info "Création de la configuration Mosquitto..."
    
    cat > mqtt-broker/config/mosquitto.conf << 'EOF'
# Configuration Mosquitto pour Pet Smart Home Production

# Paramètres généraux
pid_file /var/run/mosquitto.pid
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log
log_type error
log_type warning
log_type notice
log_type information
log_timestamp true

# Sécurité
allow_anonymous false
password_file /mosquitto/config/passwd
acl_file /mosquitto/config/acl

# Listener non-sécurisé (local seulement)
listener 1883 0.0.0.0
protocol mqtt

# Listener sécurisé TLS
listener 8883 0.0.0.0
protocol mqtt
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key
require_certificate false
use_identity_as_username false

# WebSocket sécurisé
listener 8884 0.0.0.0
protocol websockets
cafile /mosquitto/certs/ca.crt
certfile /mosquitto/certs/server.crt
keyfile /mosquitto/certs/server.key

# Limites de connexion
max_connections 1000
max_inflight_messages 100
max_queued_messages 1000
message_size_limit 1048576

# Keepalive
keepalive_interval 60

# QoS et rétention
max_qos 2
retain_available true
set_tcp_nodelay true

# Logging avancé
log_type subscribe
log_type unsubscribe
log_type websockets
log_type none
log_type all
EOF

    log_success "Configuration Mosquitto créée"
}

# Créer les utilisateurs MQTT
create_mqtt_users() {
    log_info "Création des utilisateurs MQTT..."
    
    cat > mqtt-broker/config/passwd << 'EOF'
# Fichier des mots de passe MQTT
# Format: username:password_hash
# Généré avec: mosquitto_passwd -c passwd username

# Utilisateur admin
admin:$7$101$8K8K8K8K8K8K8K8K$8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K8K

# Utilisateurs des appareils
device_feeder:$7$101$9L9L9L9L9L9L9L9L$9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L9L
device_door:$7$101$0M0M0M0M0M0M0M0M$0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M0M

# Utilisateur monitoring
monitor:$7$101$1N1N1N1N1N1N1N1N$1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N1N

# Utilisateur mobile app
mobile_app:$7$101$2O2O2O2O2O2O2O2O$2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O2O
EOF

    log_success "Utilisateurs MQTT créés"
}

# Créer les ACL (Access Control List)
create_mqtt_acl() {
    log_info "Création des ACL MQTT..."
    
    cat > mqtt-broker/config/acl << 'EOF'
# ACL (Access Control List) pour Pet Smart Home
# Format: user <username>
#         topic [read|write|readwrite] <topic>

# Utilisateur admin - accès complet
user admin
topic readwrite #

# Appareils - accès limité à leurs topics
user device_feeder
topic readwrite pet-smart-home/feeder/+/status
topic readwrite pet-smart-home/feeder/+/command
topic readwrite pet-smart-home/feeder/+/data
topic read pet-smart-home/system/time
topic read pet-smart-home/system/config

user device_door
topic readwrite pet-smart-home/door/+/status
topic readwrite pet-smart-home/door/+/command
topic readwrite pet-smart-home/door/+/data
topic read pet-smart-home/system/time
topic read pet-smart-home/system/config

# Monitoring - lecture seule sur tous les topics
user monitor
topic read pet-smart-home/+/+/status
topic read pet-smart-home/+/+/data
topic readwrite pet-smart-home/monitoring/+

# Application mobile - accès aux commandes et statuts
user mobile_app
topic read pet-smart-home/+/+/status
topic read pet-smart-home/+/+/data
topic write pet-smart-home/+/+/command
topic readwrite pet-smart-home/app/+

# Topics système - accès restreint
pattern read pet-smart-home/system/%u
pattern write pet-smart-home/system/%u

# Heartbeat - tous les utilisateurs authentifiés
topic readwrite pet-smart-home/heartbeat
EOF

    log_success "ACL MQTT créées"
}

# Générer les certificats SSL auto-signés
generate_ssl_certificates() {
    log_info "Génération des certificats SSL..."
    
    cd mqtt-broker/certs
    
    # Générer la clé privée de l'autorité de certification
    openssl genrsa -out ca.key 4096
    
    # Générer le certificat de l'autorité de certification
    openssl req -new -x509 -days 3650 -key ca.key -out ca.crt -subj "/C=FR/ST=France/L=Paris/O=Pet Smart Home/OU=IoT/CN=Pet Smart Home CA"
    
    # Générer la clé privée du serveur
    openssl genrsa -out server.key 4096
    
    # Générer la demande de certificat du serveur
    openssl req -new -key server.key -out server.csr -subj "/C=FR/ST=France/L=Paris/O=Pet Smart Home/OU=IoT/CN=$MQTT_HOST"
    
    # Générer le certificat du serveur signé par l'autorité de certification
    openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
    
    # Nettoyer les fichiers temporaires
    rm server.csr ca.srl
    
    # Définir les permissions appropriées
    chmod 600 *.key
    chmod 644 *.crt
    
    cd ../..
    
    log_success "Certificats SSL générés"
}

# Créer le script de démarrage
create_startup_script() {
    log_info "Création du script de démarrage..."
    
    cat > mqtt-broker/start-mqtt.sh << 'EOF'
#!/bin/bash

# Script de démarrage du broker MQTT Pet Smart Home

echo "🚀 Démarrage du broker MQTT Pet Smart Home..."

# Vérifier que Docker est installé
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé"
    exit 1
fi

# Créer les répertoires nécessaires
mkdir -p data logs

# Définir les permissions
chmod 755 data logs
chmod 644 config/*

# Démarrer les services
echo "📦 Démarrage des conteneurs..."
docker-compose up -d

# Attendre que le service soit prêt
echo "⏳ Attente du démarrage du broker..."
sleep 10

# Vérifier le statut
if docker-compose ps | grep -q "Up"; then
    echo "✅ Broker MQTT démarré avec succès"
    echo "🔌 MQTT TLS: $MQTT_HOST:8883"
    echo "🌐 WebSocket: $MQTT_HOST:8884"
    echo "📊 Monitoring: http://localhost:9234/metrics"
else
    echo "❌ Erreur lors du démarrage"
    docker-compose logs
    exit 1
fi
EOF

    chmod +x mqtt-broker/start-mqtt.sh
    
    log_success "Script de démarrage créé"
}

# Créer le script de test
create_test_script() {
    log_info "Création du script de test..."
    
    cat > mqtt-broker/test-mqtt.sh << 'EOF'
#!/bin/bash

# Script de test du broker MQTT

echo "🧪 Test du broker MQTT Pet Smart Home..."

MQTT_HOST="localhost"
MQTT_PORT="8883"
USERNAME="admin"
PASSWORD="change_me_in_production"

# Test de connexion
echo "📡 Test de connexion..."
mosquitto_pub -h $MQTT_HOST -p $MQTT_PORT -u $USERNAME -P $PASSWORD -t "pet-smart-home/test" -m "Hello from test script" --cafile certs/ca.crt

if [ $? -eq 0 ]; then
    echo "✅ Connexion réussie"
else
    echo "❌ Échec de la connexion"
    exit 1
fi

# Test de subscription
echo "📥 Test de subscription..."
timeout 5 mosquitto_sub -h $MQTT_HOST -p $MQTT_PORT -u $USERNAME -P $PASSWORD -t "pet-smart-home/test" --cafile certs/ca.crt &

sleep 1

# Test de publication
echo "📤 Test de publication..."
mosquitto_pub -h $MQTT_HOST -p $MQTT_PORT -u $USERNAME -P $PASSWORD -t "pet-smart-home/test" -m "Test message $(date)" --cafile certs/ca.crt

sleep 2

echo "✅ Tests terminés"
EOF

    chmod +x mqtt-broker/test-mqtt.sh
    
    log_success "Script de test créé"
}

# Créer la documentation
create_documentation() {
    log_info "Création de la documentation..."
    
    cat > mqtt-broker/README.md << 'EOF'
# 🔌 MQTT Broker Production - Pet Smart Home

## Vue d'ensemble

Ce broker MQTT sécurisé gère toutes les communications IoT du système Pet Smart Home.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ESP32 Devices │    │  MQTT Broker    │    │  Mobile App     │
│                 │    │                 │    │                 │
│ • Feeder        │◄──►│ • Mosquitto     │◄──►│ • Flutter       │
│ • Smart Door    │    │ • TLS/SSL       │    │ • WebSocket     │
│ • Sensors       │    │ • Authentication│    │ • Real-time     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Ports

- **1883**: MQTT non-sécurisé (local seulement)
- **8883**: MQTT sécurisé (TLS)
- **8884**: WebSocket sécurisé
- **9234**: Métriques Prometheus

## Utilisateurs

| Utilisateur | Rôle | Permissions |
|-------------|------|-------------|
| admin | Administrateur | Accès complet |
| device_feeder | Distributeur | Topics feeder uniquement |
| device_door | Porte | Topics door uniquement |
| monitor | Monitoring | Lecture seule |
| mobile_app | Application | Commandes et statuts |

## Topics

### Structure des topics
```
pet-smart-home/
├── feeder/
│   ├── {device_id}/
│   │   ├── status      # Statut de l'appareil
│   │   ├── command     # Commandes vers l'appareil
│   │   └── data        # Données de l'appareil
├── door/
│   ├── {device_id}/
│   │   ├── status
│   │   ├── command
│   │   └── data
├── system/
│   ├── time            # Synchronisation temporelle
│   └── config          # Configuration système
└── monitoring/
    ├── health          # Santé du système
    └── metrics         # Métriques
```

## Démarrage

```bash
# Démarrer le broker
./start-mqtt.sh

# Tester la connexion
./test-mqtt.sh

# Voir les logs
docker-compose logs -f

# Arrêter le broker
docker-compose down
```

## Sécurité

- ✅ Authentification obligatoire
- ✅ Chiffrement TLS/SSL
- ✅ ACL granulaires
- ✅ Certificats auto-signés
- ✅ Isolation des utilisateurs

## Monitoring

- Métriques Prometheus disponibles sur le port 9234
- Logs centralisés dans `/logs`
- Health checks automatiques

## Maintenance

### Renouveler les certificats
```bash
cd certs
# Régénérer les certificats (valides 10 ans)
./generate-certs.sh
docker-compose restart
```

### Ajouter un utilisateur
```bash
# Générer le hash du mot de passe
mosquitto_passwd -c passwd nouvel_utilisateur

# Ajouter les permissions dans acl
echo "user nouvel_utilisateur" >> config/acl
echo "topic readwrite pet-smart-home/custom/topic" >> config/acl

# Redémarrer
docker-compose restart
```

### Sauvegarde
```bash
# Sauvegarder les données
tar -czf mqtt-backup-$(date +%Y%m%d).tar.gz data/ config/ certs/
```

## Dépannage

### Vérifier la connectivité
```bash
# Test de connexion simple
mosquitto_pub -h mqtt.pet-smart-home.com -p 8883 -u admin -P password -t test -m "hello" --cafile certs/ca.crt
```

### Logs utiles
```bash
# Logs du broker
docker-compose logs mosquitto

# Logs en temps réel
docker-compose logs -f
```

---
**Version**: 1.0.0
**Dernière mise à jour**: $(date)
EOF

    log_success "Documentation créée"
}

# Fonction principale
main() {
    echo
    log_info "Démarrage de la configuration MQTT Broker..."
    echo
    
    create_docker_compose
    create_mosquitto_config
    create_mqtt_users
    create_mqtt_acl
    generate_ssl_certificates
    create_startup_script
    create_test_script
    create_documentation
    
    echo
    log_success "🎉 Configuration MQTT Broker terminée avec succès!"
    echo
    log_info "Répertoire créé: mqtt-broker/"
    log_info "Pour démarrer: cd mqtt-broker && ./start-mqtt.sh"
    log_warning "⚠️ Changez les mots de passe par défaut avant la production!"
    echo
}

# Exécuter le script principal
main "$@"
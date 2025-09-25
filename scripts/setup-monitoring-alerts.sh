#!/bin/bash

# Script de configuration du monitoring avec alertes
# Pet Smart Home - Système de surveillance complet

set -e

echo "📊 Configuration Monitoring & Alertes - Pet Smart Home"
echo "====================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
GRAFANA_PORT="3000"
PROMETHEUS_PORT="9090"
ALERTMANAGER_PORT="9093"

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

# Créer la structure de monitoring
create_monitoring_structure() {
    log_info "Création de la structure de monitoring..."
    
    mkdir -p monitoring-stack/{prometheus,grafana,alertmanager,config,dashboards,rules,scripts}
    
    log_success "Structure de monitoring créée"
}

# Créer la configuration Docker Compose
create_docker_compose() {
    log_info "Création de la configuration Docker Compose..."
    
    cat > monitoring-stack/docker-compose.yml << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: pet-smart-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - ./prometheus/rules:/etc/prometheus/rules:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=15d'
      - '--web.enable-lifecycle'
      - '--web.enable-admin-api'
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    container_name: pet-smart-alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro
      - alertmanager-data:/alertmanager
    command:
      - '--config.file=/etc/alertmanager/alertmanager.yml'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: pet-smart-grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/grafana.ini:/etc/grafana/grafana.ini:ro
      - ./grafana/provisioning:/etc/grafana/provisioning:ro
      - ./dashboards:/var/lib/grafana/dashboards:ro
      - grafana-data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin123
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: pet-smart-node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring

  mqtt-exporter:
    image: sapcc/mosquitto-exporter:latest
    container_name: pet-smart-mqtt-exporter
    restart: unless-stopped
    ports:
      - "9234:9234"
    environment:
      - BROKER_ENDPOINT=tcp://mqtt.pet-smart-home.com:1883
      - MQTT_USERNAME=monitor
      - MQTT_PASSWORD=monitor_password
    networks:
      - monitoring

  blackbox-exporter:
    image: prom/blackbox-exporter:latest
    container_name: pet-smart-blackbox-exporter
    restart: unless-stopped
    ports:
      - "9115:9115"
    volumes:
      - ./config/blackbox.yml:/etc/blackbox_exporter/config.yml:ro
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  prometheus-data:
  alertmanager-data:
  grafana-data:
EOF

    log_success "Docker Compose créé"
}

# Créer la configuration Prometheus
create_prometheus_config() {
    log_info "Création de la configuration Prometheus..."
    
    cat > monitoring-stack/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'mqtt-broker'
    static_configs:
      - targets: ['mqtt-exporter:9234']

  - job_name: 'ota-server'
    static_configs:
      - targets: ['ota.pet-smart-home.com:8080']
    metrics_path: '/api/metrics'
    scheme: https
    tls_config:
      insecure_skip_verify: true

  - job_name: 'firebase-functions'
    static_configs:
      - targets: ['europe-west1-pet-smart-home-prod.cloudfunctions.net']
    metrics_path: '/metrics'
    scheme: https

  - job_name: 'esp32-devices'
    static_configs:
      - targets: 
        - '192.168.1.100:80'  # Feeder
        - '192.168.1.101:80'  # Door
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'blackbox-http'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://app.pet-smart-home.com
        - https://ota.pet-smart-home.com/health
        - https://mqtt.pet-smart-home.com:8884
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  - job_name: 'mobile-app-analytics'
    static_configs:
      - targets: ['firebase-analytics-proxy:8080']
    metrics_path: '/metrics'
    scrape_interval: 60s
EOF

    log_success "Configuration Prometheus créée"
}

# Créer les règles d'alerte
create_alert_rules() {
    log_info "Création des règles d'alerte..."
    
    cat > monitoring-stack/prometheus/rules/pet-smart-home.yml << 'EOF'
groups:
  - name: pet-smart-home-devices
    rules:
      - alert: DeviceOffline
        expr: up{job=~"esp32-devices"} == 0
        for: 5m
        labels:
          severity: critical
          service: iot-device
        annotations:
          summary: "Appareil Pet Smart Home hors ligne"
          description: "L'appareil {{ $labels.instance }} est hors ligne depuis plus de 5 minutes."

      - alert: LowBatteryLevel
        expr: battery_level < 20
        for: 2m
        labels:
          severity: warning
          service: iot-device
        annotations:
          summary: "Niveau de batterie faible"
          description: "L'appareil {{ $labels.device_id }} a un niveau de batterie de {{ $value }}%."

      - alert: FoodLevelLow
        expr: food_level_percent < 10
        for: 1m
        labels:
          severity: warning
          service: feeder
        annotations:
          summary: "Niveau de nourriture faible"
          description: "Le distributeur {{ $labels.device_id }} a un niveau de nourriture de {{ $value }}%."

      - alert: FeederJammed
        expr: feeder_status == 3
        for: 30s
        labels:
          severity: critical
          service: feeder
        annotations:
          summary: "Distributeur bloqué"
          description: "Le distributeur {{ $labels.device_id }} est bloqué et nécessite une intervention."

  - name: pet-smart-home-infrastructure
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
          service: infrastructure
        annotations:
          summary: "Utilisation CPU élevée"
          description: "L'utilisation CPU sur {{ $labels.instance }} est de {{ $value }}%."

      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
          service: infrastructure
        annotations:
          summary: "Utilisation mémoire élevée"
          description: "L'utilisation mémoire sur {{ $labels.instance }} est de {{ $value }}%."

      - alert: DiskSpaceLow
        expr: (1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: critical
          service: infrastructure
        annotations:
          summary: "Espace disque faible"
          description: "L'espace disque sur {{ $labels.instance }} est utilisé à {{ $value }}%."

  - name: pet-smart-home-services
    rules:
      - alert: ServiceDown
        expr: up{job=~"ota-server|mqtt-broker"} == 0
        for: 2m
        labels:
          severity: critical
          service: "{{ $labels.job }}"
        annotations:
          summary: "Service indisponible"
          description: "Le service {{ $labels.job }} sur {{ $labels.instance }} est indisponible."

      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m]) > 0.1
        for: 5m
        labels:
          severity: warning
          service: api
        annotations:
          summary: "Taux d'erreur élevé"
          description: "Le taux d'erreur sur {{ $labels.instance }} est de {{ $value | humanizePercentage }}."

      - alert: MQTTConnectionsHigh
        expr: mqtt_connected_clients > 100
        for: 5m
        labels:
          severity: warning
          service: mqtt
        annotations:
          summary: "Nombre de connexions MQTT élevé"
          description: "Le broker MQTT a {{ $value }} connexions actives."

  - name: pet-smart-home-business
    rules:
      - alert: NoFeedingActivity
        expr: increase(feeding_events_total[24h]) == 0
        for: 1h
        labels:
          severity: warning
          service: business
        annotations:
          summary: "Aucune activité de distribution"
          description: "Aucune distribution de nourriture détectée dans les dernières 24h pour {{ $labels.device_id }}."

      - alert: UnusualDoorActivity
        expr: increase(door_access_events_total[1h]) > 50
        for: 5m
        labels:
          severity: warning
          service: business
        annotations:
          summary: "Activité inhabituelle de la porte"
          description: "{{ $value }} accès à la porte détectés dans la dernière heure pour {{ $labels.device_id }}."
EOF

    log_success "Règles d'alerte créées"
}

# Créer la configuration Alertmanager
create_alertmanager_config() {
    log_info "Création de la configuration Alertmanager..."
    
    cat > monitoring-stack/alertmanager/alertmanager.yml << 'EOF'
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@pet-smart-home.com'
  smtp_auth_username: 'alerts@pet-smart-home.com'
  smtp_auth_password: 'your-email-password'

route:
  group_by: ['alertname', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical-alerts'
    - match:
        service: iot-device
      receiver: 'device-alerts'
    - match:
        service: infrastructure
      receiver: 'infrastructure-alerts'

receivers:
  - name: 'default'
    email_configs:
      - to: 'admin@pet-smart-home.com'
        subject: '[Pet Smart Home] {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Labels: {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
          {{ end }}

  - name: 'critical-alerts'
    email_configs:
      - to: 'admin@pet-smart-home.com,support@pet-smart-home.com'
        subject: '[CRITICAL] Pet Smart Home Alert'
        body: |
          🚨 ALERTE CRITIQUE 🚨
          
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Severity: {{ .Labels.severity }}
          Service: {{ .Labels.service }}
          Time: {{ .StartsAt }}
          {{ end }}
    slack_configs:
      - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
        channel: '#alerts'
        title: '🚨 Pet Smart Home Critical Alert'
        text: |
          {{ range .Alerts }}
          *{{ .Annotations.summary }}*
          {{ .Annotations.description }}
          {{ end }}

  - name: 'device-alerts'
    email_configs:
      - to: 'devices@pet-smart-home.com'
        subject: '[Device] Pet Smart Home Alert'
        body: |
          📱 ALERTE APPAREIL 📱
          
          {{ range .Alerts }}
          Device Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Device: {{ .Labels.device_id }}
          {{ end }}

  - name: 'infrastructure-alerts'
    email_configs:
      - to: 'infra@pet-smart-home.com'
        subject: '[Infrastructure] Pet Smart Home Alert'
        body: |
          🖥️ ALERTE INFRASTRUCTURE 🖥️
          
          {{ range .Alerts }}
          Infrastructure Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          Instance: {{ .Labels.instance }}
          {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'instance']
EOF

    log_success "Configuration Alertmanager créée"
}

# Créer la configuration Grafana
create_grafana_config() {
    log_info "Création de la configuration Grafana..."
    
    cat > monitoring-stack/grafana/grafana.ini << 'EOF'
[server]
http_port = 3000
domain = grafana.pet-smart-home.com

[security]
admin_user = admin
admin_password = admin123
secret_key = your-secret-key-change-me

[users]
allow_sign_up = false
allow_org_create = false
auto_assign_org = true
auto_assign_org_role = Viewer

[auth.anonymous]
enabled = false

[dashboards]
default_home_dashboard_path = /var/lib/grafana/dashboards/pet-smart-home-overview.json

[alerting]
enabled = true
execute_alerts = true

[smtp]
enabled = true
host = smtp.gmail.com:587
user = alerts@pet-smart-home.com
password = your-email-password
from_address = alerts@pet-smart-home.com
from_name = Pet Smart Home Grafana

[log]
mode = console file
level = info
EOF

    # Créer la configuration de provisioning
    mkdir -p monitoring-stack/grafana/provisioning/{datasources,dashboards}
    
    cat > monitoring-stack/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    cat > monitoring-stack/grafana/provisioning/dashboards/dashboards.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'Pet Smart Home'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /var/lib/grafana/dashboards
EOF

    log_success "Configuration Grafana créée"
}

# Créer les dashboards Grafana
create_grafana_dashboards() {
    log_info "Création des dashboards Grafana..."
    
    cat > monitoring-stack/dashboards/pet-smart-home-overview.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Pet Smart Home - Vue d'ensemble",
    "tags": ["pet-smart-home"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Appareils en ligne",
        "type": "stat",
        "targets": [
          {
            "expr": "sum(up{job=\"esp32-devices\"})",
            "legendFormat": "Appareils connectés"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 1},
                {"color": "green", "value": 2}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Niveau de nourriture",
        "type": "gauge",
        "targets": [
          {
            "expr": "food_level_percent",
            "legendFormat": "{{device_id}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "min": 0,
            "max": 100,
            "unit": "percent",
            "thresholds": {
              "steps": [
                {"color": "red", "value": 0},
                {"color": "yellow", "value": 20},
                {"color": "green", "value": 50}
              ]
            }
          }
        },
        "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0}
      },
      {
        "id": 3,
        "title": "Activité des distributions",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(feeding_events_total[5m])",
            "legendFormat": "{{device_id}}"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 8}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

    log_success "Dashboards Grafana créés"
}

# Créer la configuration Blackbox Exporter
create_blackbox_config() {
    log_info "Création de la configuration Blackbox Exporter..."
    
    cat > monitoring-stack/config/blackbox.yml << 'EOF'
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      valid_status_codes: []
      method: GET
      follow_redirects: true
      preferred_ip_protocol: "ip4"

  http_post_2xx:
    prober: http
    timeout: 5s
    http:
      method: POST
      headers:
        Content-Type: application/json
      body: '{"test": true}'

  tcp_connect:
    prober: tcp
    timeout: 5s

  mqtt_connect:
    prober: tcp
    timeout: 5s
    tcp:
      query_response:
        - expect: "CONNACK"
          send: "CONNECT"
EOF

    log_success "Configuration Blackbox Exporter créée"
}

# Créer les scripts de gestion
create_management_scripts() {
    log_info "Création des scripts de gestion..."
    
    # Script de démarrage
    cat > monitoring-stack/scripts/start.sh << 'EOF'
#!/bin/bash

echo "📊 Démarrage du stack de monitoring Pet Smart Home..."

# Créer les répertoires nécessaires
mkdir -p {prometheus,grafana,alertmanager}/data

# Définir les permissions
chmod 755 */data

# Démarrer les services
echo "📦 Démarrage des conteneurs..."
docker-compose up -d

# Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 20

# Vérifier le statut
if docker-compose ps | grep -q "Up"; then
    echo "✅ Stack de monitoring démarré avec succès"
    echo "📊 Prometheus: http://localhost:9090"
    echo "📈 Grafana: http://localhost:3000 (admin/admin123)"
    echo "🚨 Alertmanager: http://localhost:9093"
    echo "📡 Node Exporter: http://localhost:9100"
else
    echo "❌ Erreur lors du démarrage"
    docker-compose logs
    exit 1
fi
EOF

    # Script de test des alertes
    cat > monitoring-stack/scripts/test-alerts.sh << 'EOF'
#!/bin/bash

echo "🧪 Test des alertes Pet Smart Home..."

# Test d'alerte critique
echo "📤 Envoi d'une alerte de test..."
curl -X POST http://localhost:9093/api/v1/alerts \
  -H "Content-Type: application/json" \
  -d '[
    {
      "labels": {
        "alertname": "TestAlert",
        "severity": "critical",
        "service": "test"
      },
      "annotations": {
        "summary": "Alerte de test",
        "description": "Ceci est une alerte de test pour vérifier la configuration."
      },
      "startsAt": "'$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)'",
      "endsAt": "'$(date -u -d '+5 minutes' +%Y-%m-%dT%H:%M:%S.%3NZ)'"
    }
  ]'

echo "✅ Alerte de test envoyée"
echo "📧 Vérifiez votre email et Slack"
EOF

    # Script de sauvegarde
    cat > monitoring-stack/scripts/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="monitoring-backup-$TIMESTAMP.tar.gz"

echo "💾 Sauvegarde du stack de monitoring..."

# Créer le répertoire de sauvegarde
mkdir -p $BACKUP_DIR

# Arrêter les services temporairement
docker-compose stop

# Créer l'archive
tar -czf $BACKUP_DIR/$BACKUP_FILE \
    prometheus/ \
    grafana/ \
    alertmanager/ \
    config/ \
    dashboards/ \
    docker-compose.yml

# Redémarrer les services
docker-compose start

echo "✅ Sauvegarde créée: $BACKUP_DIR/$BACKUP_FILE"

# Nettoyer les anciennes sauvegardes
find $BACKUP_DIR -name "monitoring-backup-*.tar.gz" -type f -mtime +7 -delete
EOF

    # Rendre les scripts exécutables
    chmod +x monitoring-stack/scripts/*.sh
    
    log_success "Scripts de gestion créés"
}

# Créer la documentation
create_monitoring_docs() {
    log_info "Création de la documentation de monitoring..."
    
    cat > monitoring-stack/README.md << 'EOF'
# 📊 Stack de Monitoring - Pet Smart Home

## Vue d'ensemble

Stack complet de monitoring et d'alertes pour le système Pet Smart Home.

## Services

- **Prometheus**: Collecte et stockage des métriques
- **Grafana**: Visualisation et dashboards
- **Alertmanager**: Gestion des alertes
- **Node Exporter**: Métriques système
- **MQTT Exporter**: Métriques MQTT
- **Blackbox Exporter**: Tests de connectivité

## Ports

- **3000**: Grafana (dashboards)
- **9090**: Prometheus (métriques)
- **9093**: Alertmanager (alertes)
- **9100**: Node Exporter
- **9115**: Blackbox Exporter
- **9234**: MQTT Exporter

## Démarrage

```bash
# Démarrer le stack
./scripts/start.sh

# Tester les alertes
./scripts/test-alerts.sh

# Sauvegarder
./scripts/backup.sh
```

## Accès

### Grafana
- URL: http://localhost:3000
- Login: admin / admin123
- Dashboards: Pet Smart Home Overview

### Prometheus
- URL: http://localhost:9090
- Targets: Status > Targets
- Rules: Status > Rules

### Alertmanager
- URL: http://localhost:9093
- Alerts: Alerts
- Silences: Silences

## Métriques Surveillées

### Appareils IoT
- `up`: Statut de connexion
- `battery_level`: Niveau de batterie
- `food_level_percent`: Niveau de nourriture
- `feeding_events_total`: Nombre de distributions
- `door_access_events_total`: Accès à la porte

### Infrastructure
- `node_cpu_seconds_total`: Utilisation CPU
- `node_memory_MemAvailable_bytes`: Mémoire disponible
- `node_filesystem_avail_bytes`: Espace disque

### Services
- `http_requests_total`: Requêtes HTTP
- `mqtt_connected_clients`: Connexions MQTT
- `up`: Disponibilité des services

## Alertes Configurées

### Critiques
- Appareil hors ligne > 5 min
- Distributeur bloqué
- Service indisponible
- Espace disque < 10%

### Avertissements
- Batterie < 20%
- Nourriture < 10%
- CPU > 80%
- Mémoire > 85%

## Configuration des Notifications

### Email
Modifier `alertmanager/alertmanager.yml`:
```yaml
global:
  smtp_smarthost: 'your-smtp-server:587'
  smtp_from: 'alerts@your-domain.com'
  smtp_auth_username: 'your-username'
  smtp_auth_password: 'your-password'
```

### Slack
Ajouter le webhook dans `alertmanager.yml`:
```yaml
slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    channel: '#alerts'
```

## Dashboards Personnalisés

### Créer un nouveau dashboard
1. Aller sur Grafana
2. Create > Dashboard
3. Add Panel
4. Configurer la requête PromQL
5. Sauvegarder

### Exemples de requêtes PromQL
```promql
# Appareils en ligne
sum(up{job="esp32-devices"})

# Niveau de nourriture moyen
avg(food_level_percent)

# Taux de distribution par heure
rate(feeding_events_total[1h]) * 3600

# Utilisation CPU
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

## Maintenance

### Mise à jour des règles
```bash
# Recharger la configuration Prometheus
curl -X POST http://localhost:9090/-/reload

# Recharger Alertmanager
curl -X POST http://localhost:9093/-/reload
```

### Nettoyage des données
```bash
# Nettoyer les anciennes métriques (15 jours par défaut)
docker exec pet-smart-prometheus \
  promtool tsdb delete-series --match='{__name__=~".*"}' \
  --start=$(date -d '15 days ago' +%s)
```

### Logs
```bash
# Voir tous les logs
docker-compose logs -f

# Logs spécifiques
docker-compose logs prometheus
docker-compose logs grafana
docker-compose logs alertmanager
```

## Dépannage

### Prometheus ne collecte pas les métriques
1. Vérifier les targets: http://localhost:9090/targets
2. Vérifier la connectivité réseau
3. Vérifier les credentials d'authentification

### Alertes non envoyées
1. Vérifier Alertmanager: http://localhost:9093
2. Tester la configuration SMTP
3. Vérifier les règles d'alerte

### Grafana ne se connecte pas à Prometheus
1. Vérifier la datasource dans Grafana
2. Tester la connectivité: http://prometheus:9090
3. Vérifier les logs Grafana

---
**Version**: 1.0.0
**Dernière mise à jour**: $(date)
EOF

    log_success "Documentation de monitoring créée"
}

# Fonction principale
main() {
    echo
    log_info "Démarrage de la configuration du monitoring..."
    echo
    
    create_monitoring_structure
    create_docker_compose
    create_prometheus_config
    create_alert_rules
    create_alertmanager_config
    create_grafana_config
    create_grafana_dashboards
    create_blackbox_config
    create_management_scripts
    create_monitoring_docs
    
    echo
    log_success "🎉 Configuration du monitoring terminée avec succès!"
    echo
    log_info "Répertoire créé: monitoring-stack/"
    log_info "Pour démarrer: cd monitoring-stack && ./scripts/start.sh"
    log_warning "⚠️ Configurez les notifications email/Slack avant la production!"
    echo
}

# Exécuter le script principal
main "$@"
#!/bin/bash

# Script de déploiement du serveur OTA
# Pet Smart Home - Serveur de mise à jour Over-The-Air

set -e

echo "🔄 Déploiement Serveur OTA - Pet Smart Home"
echo "==========================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
OTA_DOMAIN="ota.pet-smart-home.com"
OTA_PORT="8080"
SSL_PORT="8443"

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

# Créer la structure de déploiement
create_deployment_structure() {
    log_info "Création de la structure de déploiement..."
    
    mkdir -p ota-deployment/{config,ssl,firmwares,logs,scripts}
    
    # Copier le serveur OTA existant
    cp -r ota-server/* ota-deployment/
    
    log_success "Structure de déploiement créée"
}

# Créer le Dockerfile pour la production
create_production_dockerfile() {
    log_info "Création du Dockerfile de production..."
    
    cat > ota-deployment/Dockerfile << 'EOF'
FROM node:18-alpine

# Métadonnées
LABEL maintainer="Pet Smart Home Team"
LABEL version="1.0.0"
LABEL description="OTA Update Server for Pet Smart Home IoT devices"

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=8080
ENV SSL_PORT=8443

# Créer l'utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Répertoire de travail
WORKDIR /app

# Copier les fichiers de dépendances
COPY package*.json ./

# Installer les dépendances de production
RUN npm ci --only=production && \
    npm cache clean --force

# Copier le code source
COPY . .

# Créer les répertoires nécessaires
RUN mkdir -p firmwares logs uploads && \
    chown -R nodejs:nodejs /app

# Exposer les ports
EXPOSE 8080 8443

# Basculer vers l'utilisateur non-root
USER nodejs

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js

# Commande de démarrage
CMD ["node", "server.js"]
EOF

    log_success "Dockerfile de production créé"
}

# Créer le script de health check
create_healthcheck() {
    log_info "Création du script de health check..."
    
    cat > ota-deployment/healthcheck.js << 'EOF'
const http = require('http');

const options = {
  hostname: 'localhost',
  port: process.env.PORT || 8080,
  path: '/api/health',
  method: 'GET',
  timeout: 2000
};

const req = http.request(options, (res) => {
  if (res.statusCode === 200) {
    process.exit(0);
  } else {
    process.exit(1);
  }
});

req.on('error', () => {
  process.exit(1);
});

req.on('timeout', () => {
  req.destroy();
  process.exit(1);
});

req.end();
EOF

    log_success "Health check créé"
}

# Créer la configuration Docker Compose
create_docker_compose() {
    log_info "Création de la configuration Docker Compose..."
    
    cat > ota-deployment/docker-compose.yml << 'EOF'
version: '3.8'

services:
  ota-server:
    build: .
    container_name: pet-smart-ota-server
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "8443:8443"
    volumes:
      - ./firmwares:/app/firmwares
      - ./logs:/app/logs
      - ./ssl:/app/ssl:ro
      - ./config:/app/config:ro
    environment:
      - NODE_ENV=production
      - PORT=8080
      - SSL_PORT=8443
      - OTA_AUTH_TOKEN=${OTA_AUTH_TOKEN}
      - MAX_FILE_SIZE=10485760
      - ALLOWED_ORIGINS=https://app.pet-smart-home.com,https://admin.pet-smart-home.com
      - LOG_LEVEL=info
      - RATE_LIMIT_WINDOW=900000
      - RATE_LIMIT_MAX=100
    networks:
      - ota-network
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  nginx:
    image: nginx:alpine
    container_name: pet-smart-ota-nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/ssl/certs:ro
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - ota-server
    networks:
      - ota-network

  prometheus:
    image: prom/prometheus:latest
    container_name: pet-smart-ota-prometheus
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./config/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    networks:
      - ota-network

networks:
  ota-network:
    driver: bridge

volumes:
  prometheus-data:
EOF

    log_success "Docker Compose créé"
}

# Créer la configuration Nginx
create_nginx_config() {
    log_info "Création de la configuration Nginx..."
    
    mkdir -p ota-deployment/nginx
    
    cat > ota-deployment/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    error_log /var/log/nginx/error.log warn;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Rate limiting
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=download:10m rate=5r/s;

    # Upstream
    upstream ota-backend {
        server ota-server:8080;
        keepalive 32;
    }

    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name ota.pet-smart-home.com;
        return 301 https://$server_name$request_uri;
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name ota.pet-smart-home.com;

        # SSL configuration
        ssl_certificate /etc/ssl/certs/server.crt;
        ssl_certificate_key /etc/ssl/certs/server.key;
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;
        ssl_session_cache shared:SSL:10m;
        ssl_session_timeout 10m;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
        add_header X-Frame-Options DENY always;
        add_header X-Content-Type-Options nosniff always;
        add_header X-XSS-Protection "1; mode=block" always;
        add_header Referrer-Policy "strict-origin-when-cross-origin" always;

        # Client max body size (for firmware uploads)
        client_max_body_size 20M;

        # API endpoints
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            proxy_pass http://ota-backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_cache_bypass $http_upgrade;
            proxy_read_timeout 300s;
            proxy_connect_timeout 75s;
        }

        # Firmware downloads
        location /firmware/ {
            limit_req zone=download burst=10 nodelay;
            proxy_pass http://ota-backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_read_timeout 600s;
            proxy_connect_timeout 75s;
        }

        # Health check
        location /health {
            proxy_pass http://ota-backend/api/health;
            access_log off;
        }

        # Metrics (protected)
        location /metrics {
            allow 10.0.0.0/8;
            allow 172.16.0.0/12;
            allow 192.168.0.0/16;
            deny all;
            proxy_pass http://ota-backend/api/metrics;
        }

        # Default location
        location / {
            return 404;
        }
    }
}
EOF

    log_success "Configuration Nginx créée"
}

# Créer la configuration Prometheus
create_prometheus_config() {
    log_info "Création de la configuration Prometheus..."
    
    cat > ota-deployment/config/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'ota-server'
    static_configs:
      - targets: ['ota-server:8080']
    metrics_path: '/api/metrics'
    scrape_interval: 30s

  - job_name: 'nginx'
    static_configs:
      - targets: ['nginx:80']
    metrics_path: '/metrics'
    scrape_interval: 30s

  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

    log_success "Configuration Prometheus créée"
}

# Générer les certificats SSL
generate_ssl_certificates() {
    log_info "Génération des certificats SSL..."
    
    cd ota-deployment/ssl
    
    # Générer la clé privée
    openssl genrsa -out server.key 4096
    
    # Générer le certificat auto-signé
    openssl req -new -x509 -days 3650 -key server.key -out server.crt \
        -subj "/C=FR/ST=France/L=Paris/O=Pet Smart Home/OU=OTA/CN=$OTA_DOMAIN"
    
    # Définir les permissions
    chmod 600 server.key
    chmod 644 server.crt
    
    cd ../..
    
    log_success "Certificats SSL générés"
}

# Créer les scripts de déploiement
create_deployment_scripts() {
    log_info "Création des scripts de déploiement..."
    
    # Script de démarrage
    cat > ota-deployment/scripts/start.sh << 'EOF'
#!/bin/bash

echo "🚀 Démarrage du serveur OTA Pet Smart Home..."

# Vérifier les variables d'environnement
if [ -z "$OTA_AUTH_TOKEN" ]; then
    echo "❌ Variable OTA_AUTH_TOKEN non définie"
    exit 1
fi

# Créer les répertoires nécessaires
mkdir -p firmwares logs/nginx

# Définir les permissions
chmod 755 firmwares logs

# Construire et démarrer les services
echo "🔨 Construction des images Docker..."
docker-compose build

echo "📦 Démarrage des services..."
docker-compose up -d

# Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 15

# Vérifier le statut
if docker-compose ps | grep -q "Up"; then
    echo "✅ Serveur OTA démarré avec succès"
    echo "🌐 HTTP: http://localhost:80"
    echo "🔒 HTTPS: https://localhost:443"
    echo "📊 Prometheus: http://localhost:9090"
    echo "🏥 Health: https://localhost:443/health"
else
    echo "❌ Erreur lors du démarrage"
    docker-compose logs
    exit 1
fi
EOF

    # Script d'arrêt
    cat > ota-deployment/scripts/stop.sh << 'EOF'
#!/bin/bash

echo "🛑 Arrêt du serveur OTA Pet Smart Home..."

docker-compose down

echo "✅ Serveur OTA arrêté"
EOF

    # Script de mise à jour
    cat > ota-deployment/scripts/update.sh << 'EOF'
#!/bin/bash

echo "🔄 Mise à jour du serveur OTA Pet Smart Home..."

# Sauvegarder les firmwares
echo "💾 Sauvegarde des firmwares..."
tar -czf firmwares-backup-$(date +%Y%m%d-%H%M%S).tar.gz firmwares/

# Arrêter les services
docker-compose down

# Reconstruire les images
echo "🔨 Reconstruction des images..."
docker-compose build --no-cache

# Redémarrer les services
echo "📦 Redémarrage des services..."
docker-compose up -d

echo "✅ Mise à jour terminée"
EOF

    # Script de sauvegarde
    cat > ota-deployment/scripts/backup.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="ota-backup-$TIMESTAMP.tar.gz"

echo "💾 Sauvegarde du serveur OTA..."

# Créer le répertoire de sauvegarde
mkdir -p $BACKUP_DIR

# Créer l'archive
tar -czf $BACKUP_DIR/$BACKUP_FILE \
    firmwares/ \
    logs/ \
    config/ \
    ssl/ \
    docker-compose.yml \
    .env

echo "✅ Sauvegarde créée: $BACKUP_DIR/$BACKUP_FILE"

# Nettoyer les anciennes sauvegardes (garder les 7 dernières)
find $BACKUP_DIR -name "ota-backup-*.tar.gz" -type f -mtime +7 -delete

echo "🧹 Anciennes sauvegardes nettoyées"
EOF

    # Rendre les scripts exécutables
    chmod +x ota-deployment/scripts/*.sh
    
    log_success "Scripts de déploiement créés"
}

# Créer le fichier d'environnement
create_env_file() {
    log_info "Création du fichier d'environnement..."
    
    cat > ota-deployment/.env << 'EOF'
# Configuration du serveur OTA Pet Smart Home

# Token d'authentification (CHANGEZ EN PRODUCTION!)
OTA_AUTH_TOKEN=your-super-secret-token-change-me

# Configuration du serveur
NODE_ENV=production
PORT=8080
SSL_PORT=8443

# Limites
MAX_FILE_SIZE=10485760
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=100

# Logging
LOG_LEVEL=info

# CORS
ALLOWED_ORIGINS=https://app.pet-smart-home.com,https://admin.pet-smart-home.com

# Base de données (optionnel)
# DATABASE_URL=postgresql://user:password@localhost:5432/ota_db

# Monitoring
PROMETHEUS_ENABLED=true
METRICS_ENABLED=true

# Notifications (optionnel)
# SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
# EMAIL_SMTP_HOST=smtp.gmail.com
# EMAIL_SMTP_PORT=587
# EMAIL_USER=alerts@pet-smart-home.com
# EMAIL_PASS=your-email-password
EOF

    log_success "Fichier d'environnement créé"
}

# Créer la documentation de déploiement
create_deployment_docs() {
    log_info "Création de la documentation de déploiement..."
    
    cat > ota-deployment/README.md << 'EOF'
# 🔄 Serveur OTA Production - Pet Smart Home

## Vue d'ensemble

Serveur de mise à jour Over-The-Air (OTA) pour les appareils ESP32 du système Pet Smart Home.

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ESP32 Device  │    │  Nginx Proxy    │    │  OTA Server     │
│                 │    │                 │    │                 │
│ • Check Update  │◄──►│ • SSL/TLS       │◄──►│ • Node.js       │
│ • Download FW   │    │ • Rate Limiting │    │ • File Storage  │
│ • Install       │    │ • Load Balance  │    │ • Versioning    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │  Prometheus     │
                       │  • Metrics      │
                       │ • Monitoring    │
                       └─────────────────┘
```

## Services

- **OTA Server**: Serveur Node.js principal
- **Nginx**: Proxy inverse avec SSL/TLS
- **Prometheus**: Collecte de métriques

## Ports

- **80**: HTTP (redirection vers HTTPS)
- **443**: HTTPS (API OTA)
- **9090**: Prometheus (métriques)

## Déploiement

### 1. Configuration initiale
```bash
# Modifier les variables d'environnement
nano .env

# Générer un token sécurisé
openssl rand -hex 32
```

### 2. Démarrage
```bash
# Démarrer tous les services
./scripts/start.sh

# Vérifier le statut
docker-compose ps
```

### 3. Test
```bash
# Test de santé
curl -k https://localhost:443/health

# Test d'API
curl -k -H "Authorization: Bearer your-token" \
  "https://localhost:443/api/check-update?deviceId=test&currentVersion=1.0.0"
```

## API Endpoints

### Check Update
```
GET /api/check-update?deviceId={id}&currentVersion={version}
Authorization: Bearer {token}
```

### Upload Firmware
```
POST /api/upload-firmware
Authorization: Bearer {token}
Content-Type: multipart/form-data

Body:
- firmware: file
- version: string
- changelog: string (optional)
```

### Download Firmware
```
GET /firmware/{filename}
Authorization: Bearer {token}
```

### Health Check
```
GET /health
```

### Metrics
```
GET /api/metrics
```

## Gestion des Firmwares

### Structure des fichiers
```
firmwares/
├── esp32-feeder/
│   ├── v1.0.0/
│   │   ├── firmware.bin
│   │   └── manifest.json
│   └── v1.1.0/
│       ├── firmware.bin
│       └── manifest.json
└── esp32-door/
    ├── v1.0.0/
    └── v1.1.0/
```

### Upload d'un nouveau firmware
```bash
curl -k -X POST \
  -H "Authorization: Bearer your-token" \
  -F "firmware=@firmware-v1.1.0.bin" \
  -F "version=1.1.0" \
  -F "deviceType=esp32-feeder" \
  -F "changelog=Bug fixes and improvements" \
  "https://localhost:443/api/upload-firmware"
```

## Monitoring

### Métriques disponibles
- Nombre de vérifications de mise à jour
- Nombre de téléchargements
- Taille des firmwares
- Temps de réponse
- Erreurs HTTP

### Alertes
- Espace disque faible
- Taux d'erreur élevé
- Latence élevée
- Service indisponible

## Sécurité

- ✅ HTTPS obligatoire
- ✅ Authentification par token
- ✅ Rate limiting
- ✅ Validation des fichiers
- ✅ Headers de sécurité
- ✅ Isolation des conteneurs

## Maintenance

### Sauvegarde
```bash
./scripts/backup.sh
```

### Mise à jour
```bash
./scripts/update.sh
```

### Logs
```bash
# Logs en temps réel
docker-compose logs -f

# Logs spécifiques
docker-compose logs ota-server
docker-compose logs nginx
```

### Nettoyage
```bash
# Nettoyer les anciens firmwares
find firmwares/ -name "*.bin" -mtime +30 -delete

# Nettoyer les logs
find logs/ -name "*.log" -mtime +7 -delete
```

## Dépannage

### Service ne démarre pas
```bash
# Vérifier les logs
docker-compose logs

# Vérifier la configuration
docker-compose config

# Reconstruire les images
docker-compose build --no-cache
```

### Erreurs SSL
```bash
# Régénérer les certificats
cd ssl
openssl genrsa -out server.key 4096
openssl req -new -x509 -days 3650 -key server.key -out server.crt
```

### Performance
```bash
# Métriques Prometheus
curl http://localhost:9090/metrics

# Statistiques Nginx
curl -k https://localhost:443/nginx_status
```

---
**Version**: 1.0.0
**Dernière mise à jour**: $(date)
EOF

    log_success "Documentation de déploiement créée"
}

# Fonction principale
main() {
    echo
    log_info "Démarrage du déploiement du serveur OTA..."
    echo
    
    create_deployment_structure
    create_production_dockerfile
    create_healthcheck
    create_docker_compose
    create_nginx_config
    create_prometheus_config
    generate_ssl_certificates
    create_deployment_scripts
    create_env_file
    create_deployment_docs
    
    echo
    log_success "🎉 Déploiement du serveur OTA terminé avec succès!"
    echo
    log_info "Répertoire créé: ota-deployment/"
    log_info "Pour démarrer: cd ota-deployment && ./scripts/start.sh"
    log_warning "⚠️ Modifiez le fichier .env avant le démarrage!"
    log_warning "⚠️ Changez le token d'authentification!"
    echo
}

# Exécuter le script principal
main "$@"
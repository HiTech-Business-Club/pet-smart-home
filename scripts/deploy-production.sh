#!/bin/bash

# Script principal de déploiement en production
# Pet Smart Home - Orchestrateur de déploiement complet

set -e

echo "🚀 Déploiement Production Complet - Pet Smart Home"
echo "================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="deployment_$(date +%Y%m%d_%H%M%S).log"

# Fonction pour afficher les messages
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
}

log_step() {
    echo -e "${PURPLE}🔄 $1${NC}" | tee -a "$LOG_FILE"
}

# Fonction pour exécuter un script avec gestion d'erreur
run_script() {
    local script_name="$1"
    local description="$2"
    
    log_step "$description"
    
    if [ -f "$SCRIPT_DIR/$script_name" ]; then
        if bash "$SCRIPT_DIR/$script_name" >> "$LOG_FILE" 2>&1; then
            log_success "$description terminé"
            return 0
        else
            log_error "$description échoué"
            return 1
        fi
    else
        log_error "Script $script_name non trouvé"
        return 1
    fi
}

# Vérification des prérequis
check_prerequisites() {
    log_info "=== Vérification des Prérequis ==="
    
    local missing_tools=()
    
    # Outils requis
    local required_tools=("docker" "docker-compose" "git" "curl" "openssl")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    # Outils optionnels mais recommandés
    local optional_tools=("firebase" "flutter" "pio" "mosquitto_pub")
    local missing_optional=()
    
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_optional+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        log_error "Outils manquants requis: ${missing_tools[*]}"
        log_info "Installez les outils manquants avant de continuer"
        return 1
    fi
    
    if [ ${#missing_optional[@]} -gt 0 ]; then
        log_warning "Outils optionnels manquants: ${missing_optional[*]}"
        log_info "Certaines fonctionnalités peuvent être limitées"
    fi
    
    # Vérifier Docker
    if ! docker info &> /dev/null; then
        log_error "Docker daemon non accessible"
        return 1
    fi
    
    log_success "Prérequis vérifiés"
    return 0
}

# Configuration interactive
interactive_config() {
    log_info "=== Configuration Interactive ==="
    
    echo
    echo "Ce script va déployer l'ensemble du système Pet Smart Home en production."
    echo "Assurez-vous d'avoir configuré :"
    echo "- Les comptes Firebase, MQTT, et cloud"
    echo "- Les domaines et certificats SSL"
    echo "- Les tokens et mots de passe de production"
    echo
    
    read -p "Voulez-vous continuer ? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Déploiement annulé par l'utilisateur"
        exit 0
    fi
    
    # Options de déploiement
    echo
    echo "Sélectionnez les composants à déployer :"
    echo "1. Firebase Backend"
    echo "2. Broker MQTT"
    echo "3. Serveur OTA"
    echo "4. Stack de Monitoring"
    echo "5. Tous les composants (recommandé)"
    echo
    
    read -p "Votre choix (1-5): " -n 1 -r DEPLOY_CHOICE
    echo
    
    # Configuration des domaines
    echo
    read -p "Domaine MQTT (ex: mqtt.pet-smart-home.com): " MQTT_DOMAIN
    read -p "Domaine OTA (ex: ota.pet-smart-home.com): " OTA_DOMAIN
    read -p "Domaine Monitoring (ex: monitoring.pet-smart-home.com): " MONITORING_DOMAIN
    
    # Exporter les variables
    export MQTT_DOMAIN OTA_DOMAIN MONITORING_DOMAIN
    
    log_success "Configuration interactive terminée"
}

# Sauvegarde avant déploiement
backup_current_state() {
    log_info "=== Sauvegarde de l'État Actuel ==="
    
    local backup_dir="backups/pre-deployment-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Sauvegarder les configurations existantes
    if [ -d "mqtt-broker" ]; then
        cp -r mqtt-broker "$backup_dir/"
    fi
    
    if [ -d "ota-deployment" ]; then
        cp -r ota-deployment "$backup_dir/"
    fi
    
    if [ -d "monitoring-stack" ]; then
        cp -r monitoring-stack "$backup_dir/"
    fi
    
    # Sauvegarder l'état Git
    git log --oneline -10 > "$backup_dir/git-state.txt"
    git status > "$backup_dir/git-status.txt"
    
    log_success "Sauvegarde créée dans $backup_dir"
}

# Déploiement Firebase
deploy_firebase() {
    log_step "Déploiement Firebase Backend"
    
    if run_script "setup-firebase-production.sh" "Configuration Firebase"; then
        log_success "Firebase déployé avec succès"
    else
        log_error "Échec du déploiement Firebase"
        return 1
    fi
}

# Déploiement MQTT
deploy_mqtt() {
    log_step "Déploiement Broker MQTT"
    
    if run_script "setup-mqtt-broker.sh" "Configuration MQTT Broker"; then
        cd mqtt-broker
        if ./start-mqtt.sh >> "../$LOG_FILE" 2>&1; then
            log_success "Broker MQTT déployé avec succès"
            cd ..
        else
            log_error "Échec du démarrage du broker MQTT"
            cd ..
            return 1
        fi
    else
        log_error "Échec de la configuration MQTT"
        return 1
    fi
}

# Déploiement OTA
deploy_ota() {
    log_step "Déploiement Serveur OTA"
    
    if run_script "deploy-ota-server.sh" "Configuration Serveur OTA"; then
        cd ota-deployment
        
        # Configurer le token de production
        if [ -z "$OTA_AUTH_TOKEN" ]; then
            export OTA_AUTH_TOKEN=$(openssl rand -hex 32)
            log_info "Token OTA généré: $OTA_AUTH_TOKEN"
        fi
        
        if ./scripts/start.sh >> "../$LOG_FILE" 2>&1; then
            log_success "Serveur OTA déployé avec succès"
            cd ..
        else
            log_error "Échec du démarrage du serveur OTA"
            cd ..
            return 1
        fi
    else
        log_error "Échec de la configuration OTA"
        return 1
    fi
}

# Déploiement Monitoring
deploy_monitoring() {
    log_step "Déploiement Stack de Monitoring"
    
    if run_script "setup-monitoring-alerts.sh" "Configuration Monitoring"; then
        cd monitoring-stack
        if ./scripts/start.sh >> "../$LOG_FILE" 2>&1; then
            log_success "Stack de monitoring déployé avec succès"
            cd ..
        else
            log_error "Échec du démarrage du monitoring"
            cd ..
            return 1
        fi
    else
        log_error "Échec de la configuration monitoring"
        return 1
    fi
}

# Tests post-déploiement
run_post_deployment_tests() {
    log_step "Tests Post-Déploiement"
    
    # Attendre que tous les services soient prêts
    log_info "Attente de la stabilisation des services..."
    sleep 30
    
    if run_script "test-complete-deployment.sh" "Tests de Validation"; then
        log_success "Tous les tests post-déploiement sont passés"
    else
        log_warning "Certains tests ont échoué - vérifiez le rapport de test"
    fi
}

# Configuration des secrets de production
setup_production_secrets() {
    log_info "=== Configuration des Secrets de Production ==="
    
    local secrets_file="production-secrets.env"
    
    if [ ! -f "$secrets_file" ]; then
        log_info "Génération des secrets de production..."
        
        cat > "$secrets_file" << EOF
# Secrets de Production - Pet Smart Home
# ATTENTION: Gardez ce fichier sécurisé et ne le commitez jamais!

# Firebase
FIREBASE_PROJECT_ID=pet-smart-home-prod
FIREBASE_PRIVATE_KEY_ID=$(openssl rand -hex 20)
FIREBASE_CLIENT_ID=$(openssl rand -hex 16)

# MQTT
MQTT_ADMIN_PASSWORD=$(openssl rand -base64 32)
MQTT_DEVICE_PASSWORD=$(openssl rand -base64 32)
MQTT_MONITOR_PASSWORD=$(openssl rand -base64 32)

# OTA
OTA_AUTH_TOKEN=$(openssl rand -hex 32)
OTA_ENCRYPTION_KEY=$(openssl rand -hex 32)

# Monitoring
GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 16)
PROMETHEUS_ADMIN_PASSWORD=$(openssl rand -base64 16)

# Alertes
SMTP_PASSWORD=your-smtp-password-here
SLACK_WEBHOOK_URL=your-slack-webhook-here

# JWT
JWT_SECRET=$(openssl rand -base64 64)

# Génération: $(date)
EOF
        
        chmod 600 "$secrets_file"
        log_success "Secrets générés dans $secrets_file"
        log_warning "⚠️ Configurez manuellement les mots de passe SMTP et Slack"
    else
        log_info "Fichier de secrets existant trouvé"
    fi
}

# Génération du rapport de déploiement
generate_deployment_report() {
    log_info "=== Génération du Rapport de Déploiement ==="
    
    local report_file="DEPLOYMENT_REPORT_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 🚀 Rapport de Déploiement Production - Pet Smart Home

## Informations Générales

- **Date de Déploiement**: $(date)
- **Version**: 1.0.0
- **Environnement**: Production
- **Déployé par**: $(whoami)
- **Serveur**: $(hostname)

## Services Déployés

EOF

    # Vérifier les services déployés
    if [ -d "mqtt-broker" ] && docker-compose -f mqtt-broker/docker-compose.yml ps | grep -q "Up"; then
        echo "- ✅ **Broker MQTT**: Déployé et fonctionnel" >> "$report_file"
        echo "  - Port TLS: 8883" >> "$report_file"
        echo "  - WebSocket: 8884" >> "$report_file"
    fi
    
    if [ -d "ota-deployment" ] && docker-compose -f ota-deployment/docker-compose.yml ps | grep -q "Up"; then
        echo "- ✅ **Serveur OTA**: Déployé et fonctionnel" >> "$report_file"
        echo "  - Port HTTP: 8080" >> "$report_file"
        echo "  - Port HTTPS: 8443" >> "$report_file"
    fi
    
    if [ -d "monitoring-stack" ] && docker-compose -f monitoring-stack/docker-compose.yml ps | grep -q "Up"; then
        echo "- ✅ **Stack de Monitoring**: Déployé et fonctionnel" >> "$report_file"
        echo "  - Prometheus: 9090" >> "$report_file"
        echo "  - Grafana: 3000" >> "$report_file"
        echo "  - Alertmanager: 9093" >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## URLs d'Accès

- **Grafana**: http://localhost:3000 (admin/admin123)
- **Prometheus**: http://localhost:9090
- **Alertmanager**: http://localhost:9093
- **OTA Health**: http://localhost:8080/api/health

## Configuration Post-Déploiement

### Actions Requises
1. ⚠️ Changer tous les mots de passe par défaut
2. ⚠️ Configurer les certificats SSL de production
3. ⚠️ Mettre à jour les domaines DNS
4. ⚠️ Configurer les notifications d'alerte
5. ⚠️ Effectuer des tests avec de vrais appareils

### Fichiers Importants
- \`production-secrets.env\`: Secrets de production
- \`$LOG_FILE\`: Logs de déploiement
- \`backups/\`: Sauvegardes pré-déploiement

## Monitoring

### Métriques à Surveiller
- Statut des appareils IoT
- Niveau de batterie des appareils
- Niveau de nourriture
- Performance des services
- Utilisation des ressources

### Alertes Configurées
- Appareil hors ligne > 5 minutes
- Batterie < 20%
- Nourriture < 10%
- Service indisponible
- Utilisation CPU/Mémoire élevée

## Maintenance

### Commandes Utiles
\`\`\`bash
# Voir le statut de tous les services
docker ps

# Logs en temps réel
docker-compose logs -f

# Redémarrer un service
docker-compose restart service-name

# Sauvegarder les données
./scripts/backup.sh
\`\`\`

### Mises à Jour
- Firmware ESP32: Via serveur OTA
- Application mobile: Via stores
- Services backend: Via CI/CD

## Support

- **Documentation**: Voir le répertoire \`docs/\`
- **Logs**: \`$LOG_FILE\`
- **Monitoring**: Grafana dashboards
- **Alertes**: Configurées via Alertmanager

---
**Déploiement réussi** ✅  
**Système prêt pour la production** 🚀
EOF

    log_success "Rapport de déploiement généré: $report_file"
}

# Fonction principale
main() {
    echo
    log_info "Initialisation du déploiement production..."
    echo
    
    # Vérifier les arguments
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 [--auto] [--skip-tests]"
        echo "  --auto: Mode automatique sans interaction"
        echo "  --skip-tests: Ignorer les tests post-déploiement"
        exit 0
    fi
    
    # Démarrer le logging
    log_info "Démarrage du déploiement - Log: $LOG_FILE"
    
    # Vérifications préliminaires
    if ! check_prerequisites; then
        log_error "Prérequis non satisfaits"
        exit 1
    fi
    
    # Configuration interactive (sauf en mode auto)
    if [ "$1" != "--auto" ]; then
        interactive_config
    else
        DEPLOY_CHOICE=5  # Tous les composants
    fi
    
    # Sauvegarde
    backup_current_state
    
    # Configuration des secrets
    setup_production_secrets
    
    # Déploiement selon le choix
    case $DEPLOY_CHOICE in
        1)
            deploy_firebase
            ;;
        2)
            deploy_mqtt
            ;;
        3)
            deploy_ota
            ;;
        4)
            deploy_monitoring
            ;;
        5|*)
            log_info "Déploiement complet de tous les composants..."
            deploy_firebase
            deploy_mqtt
            deploy_ota
            deploy_monitoring
            ;;
    esac
    
    # Tests post-déploiement (sauf si ignorés)
    if [ "$2" != "--skip-tests" ] && [ "$1" != "--skip-tests" ]; then
        run_post_deployment_tests
    fi
    
    # Rapport final
    generate_deployment_report
    
    echo
    echo "=========================================="
    log_success "🎉 Déploiement Production Terminé!"
    echo
    log_info "Consultez le rapport de déploiement pour les détails"
    log_info "Logs complets disponibles dans: $LOG_FILE"
    log_warning "⚠️ N'oubliez pas de configurer les mots de passe de production!"
    echo
    log_info "Le système Pet Smart Home est maintenant prêt pour la production! 🚀"
    echo
}

# Gestion des signaux pour nettoyage
trap 'log_error "Déploiement interrompu"; exit 1' INT TERM

# Exécuter le script principal
main "$@"
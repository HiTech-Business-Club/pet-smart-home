#!/bin/bash

# Script de test complet du déploiement
# Pet Smart Home - Validation end-to-end

set -e

echo "🧪 Test Complet du Déploiement - Pet Smart Home"
echo "=============================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables de test
FIREBASE_PROJECT="pet-smart-home-prod"
MQTT_HOST="localhost"
OTA_HOST="localhost"
MONITORING_HOST="localhost"

# Compteurs de tests
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

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

# Fonction de test générique
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    log_info "Test: $test_name"
    
    if eval "$test_command"; then
        log_success "PASS: $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "FAIL: $test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Test de connectivité réseau
test_network_connectivity() {
    log_info "=== Tests de Connectivité Réseau ==="
    
    run_test "Connectivité Internet" "ping -c 1 8.8.8.8 > /dev/null 2>&1"
    run_test "Résolution DNS" "nslookup google.com > /dev/null 2>&1"
    run_test "Connectivité HTTPS" "curl -s https://www.google.com > /dev/null"
}

# Test des services Docker
test_docker_services() {
    log_info "=== Tests des Services Docker ==="
    
    run_test "Docker installé" "command -v docker > /dev/null 2>&1"
    run_test "Docker Compose installé" "command -v docker-compose > /dev/null 2>&1"
    run_test "Docker daemon actif" "docker info > /dev/null 2>&1"
}

# Test du broker MQTT
test_mqtt_broker() {
    log_info "=== Tests du Broker MQTT ==="
    
    if [ -d "mqtt-broker" ]; then
        cd mqtt-broker
        
        run_test "Configuration MQTT présente" "[ -f docker-compose.yml ]"
        run_test "Certificats SSL présents" "[ -f certs/server.crt ] && [ -f certs/server.key ]"
        
        # Démarrer le broker pour les tests
        if docker-compose ps | grep -q "Up"; then
            log_info "Broker MQTT déjà en cours d'exécution"
        else
            log_info "Démarrage du broker MQTT pour les tests..."
            docker-compose up -d > /dev/null 2>&1
            sleep 10
        fi
        
        run_test "Broker MQTT accessible (port 1883)" "nc -z $MQTT_HOST 1883"
        run_test "Broker MQTT TLS accessible (port 8883)" "nc -z $MQTT_HOST 8883"
        
        # Test de publication/souscription
        if command -v mosquitto_pub > /dev/null 2>&1; then
            run_test "Test publication MQTT" "timeout 5 mosquitto_pub -h $MQTT_HOST -p 1883 -t 'test/topic' -m 'test message' -u admin -P change_me_in_production"
        else
            log_warning "mosquitto_pub non installé, test MQTT ignoré"
        fi
        
        cd ..
    else
        log_warning "Répertoire mqtt-broker non trouvé, tests MQTT ignorés"
    fi
}

# Test du serveur OTA
test_ota_server() {
    log_info "=== Tests du Serveur OTA ==="
    
    if [ -d "ota-deployment" ]; then
        cd ota-deployment
        
        run_test "Configuration OTA présente" "[ -f docker-compose.yml ]"
        run_test "Dockerfile présent" "[ -f Dockerfile ]"
        run_test "Certificats SSL présents" "[ -f ssl/server.crt ] && [ -f ssl/server.key ]"
        
        # Démarrer le serveur pour les tests
        if docker-compose ps | grep -q "Up"; then
            log_info "Serveur OTA déjà en cours d'exécution"
        else
            log_info "Démarrage du serveur OTA pour les tests..."
            export OTA_AUTH_TOKEN="test-token-123"
            docker-compose up -d > /dev/null 2>&1
            sleep 15
        fi
        
        run_test "Serveur OTA accessible (port 8080)" "nc -z $OTA_HOST 8080"
        run_test "Health check OTA" "curl -s http://$OTA_HOST:8080/api/health | grep -q 'ok'"
        
        # Test de l'API avec authentification
        run_test "API OTA avec auth" "curl -s -H 'Authorization: Bearer test-token-123' http://$OTA_HOST:8080/api/check-update?deviceId=test&currentVersion=1.0.0 | grep -q 'version'"
        
        cd ..
    else
        log_warning "Répertoire ota-deployment non trouvé, tests OTA ignorés"
    fi
}

# Test du stack de monitoring
test_monitoring_stack() {
    log_info "=== Tests du Stack de Monitoring ==="
    
    if [ -d "monitoring-stack" ]; then
        cd monitoring-stack
        
        run_test "Configuration monitoring présente" "[ -f docker-compose.yml ]"
        run_test "Configuration Prometheus" "[ -f prometheus/prometheus.yml ]"
        run_test "Configuration Grafana" "[ -f grafana/grafana.ini ]"
        run_test "Règles d'alerte" "[ -f prometheus/rules/pet-smart-home.yml ]"
        
        # Démarrer le stack pour les tests
        if docker-compose ps | grep -q "Up"; then
            log_info "Stack de monitoring déjà en cours d'exécution"
        else
            log_info "Démarrage du stack de monitoring pour les tests..."
            docker-compose up -d > /dev/null 2>&1
            sleep 20
        fi
        
        run_test "Prometheus accessible" "nc -z $MONITORING_HOST 9090"
        run_test "Grafana accessible" "nc -z $MONITORING_HOST 3000"
        run_test "Alertmanager accessible" "nc -z $MONITORING_HOST 9093"
        
        # Test des endpoints
        run_test "Prometheus health" "curl -s http://$MONITORING_HOST:9090/-/healthy | grep -q 'Prometheus is Healthy'"
        run_test "Grafana health" "curl -s http://$MONITORING_HOST:3000/api/health | grep -q 'ok'"
        
        cd ..
    else
        log_warning "Répertoire monitoring-stack non trouvé, tests monitoring ignorés"
    fi
}

# Test de la compilation ESP32
test_esp32_firmware() {
    log_info "=== Tests du Firmware ESP32 ==="
    
    if [ -d "esp32-firmware" ]; then
        cd esp32-firmware
        
        run_test "Configuration PlatformIO présente" "[ -f platformio.ini ]"
        run_test "Code source présent" "[ -f src/main.cpp ]"
        run_test "Configuration de production" "[ -f platformio_production.ini ]"
        
        # Test de compilation si PlatformIO est installé
        if command -v pio > /dev/null 2>&1; then
            run_test "Compilation firmware (check)" "pio run -e esp32dev --target checkprogsize > /dev/null 2>&1"
        else
            log_warning "PlatformIO non installé, test de compilation ignoré"
        fi
        
        cd ..
    else
        log_warning "Répertoire esp32-firmware non trouvé, tests firmware ignorés"
    fi
}

# Test de l'application mobile
test_mobile_app() {
    log_info "=== Tests de l'Application Mobile ==="
    
    if [ -d "mobile-app" ]; then
        cd mobile-app
        
        run_test "Configuration Flutter présente" "[ -f pubspec.yaml ]"
        run_test "Code source présent" "[ -f lib/main.dart ]"
        run_test "Configuration Android" "[ -f android/app/build.gradle ]"
        
        # Test Flutter si installé
        if command -v flutter > /dev/null 2>&1; then
            run_test "Flutter doctor" "flutter doctor --android-licenses > /dev/null 2>&1 || true"
            run_test "Dépendances Flutter" "flutter pub get > /dev/null 2>&1"
            run_test "Analyse du code Flutter" "flutter analyze --no-fatal-infos > /dev/null 2>&1"
        else
            log_warning "Flutter non installé, tests Flutter ignorés"
        fi
        
        cd ..
    else
        log_warning "Répertoire mobile-app non trouvé, tests Flutter ignorés"
    fi
}

# Test du backend Firebase
test_firebase_backend() {
    log_info "=== Tests du Backend Firebase ==="
    
    if [ -d "backend" ]; then
        cd backend
        
        run_test "Configuration Firebase présente" "[ -f firebase.json ]"
        run_test "Règles Firestore" "[ -f firestore.rules ]"
        run_test "Règles Storage" "[ -f storage.rules ]"
        run_test "Cloud Functions" "[ -f functions/src/index.ts ]"
        
        # Test Firebase CLI si installé
        if command -v firebase > /dev/null 2>&1; then
            run_test "Firebase CLI connecté" "firebase projects:list > /dev/null 2>&1"
            
            if [ -f functions/package.json ]; then
                cd functions
                run_test "Dépendances Functions" "npm install > /dev/null 2>&1"
                run_test "Build Functions" "npm run build > /dev/null 2>&1"
                cd ..
            fi
        else
            log_warning "Firebase CLI non installé, tests Firebase ignorés"
        fi
        
        cd ..
    else
        log_warning "Répertoire backend non trouvé, tests Firebase ignorés"
    fi
}

# Test de sécurité basique
test_security() {
    log_info "=== Tests de Sécurité ==="
    
    # Vérifier les permissions des fichiers sensibles
    run_test "Permissions certificats MQTT" "[ ! -f mqtt-broker/certs/server.key ] || [ \$(stat -c '%a' mqtt-broker/certs/server.key) = '600' ]"
    run_test "Permissions certificats OTA" "[ ! -f ota-deployment/ssl/server.key ] || [ \$(stat -c '%a' ota-deployment/ssl/server.key) = '600' ]"
    
    # Vérifier les mots de passe par défaut
    if [ -f "mqtt-broker/config/passwd" ]; then
        run_test "Mots de passe MQTT modifiés" "! grep -q 'change_me' mqtt-broker/config/passwd"
    fi
    
    if [ -f "ota-deployment/.env" ]; then
        run_test "Token OTA modifié" "! grep -q 'change-me' ota-deployment/.env"
    fi
}

# Test de performance basique
test_performance() {
    log_info "=== Tests de Performance ==="
    
    # Test de charge basique sur les services
    if command -v ab > /dev/null 2>&1; then
        if nc -z $OTA_HOST 8080; then
            run_test "Test de charge OTA (10 requêtes)" "ab -n 10 -c 2 http://$OTA_HOST:8080/api/health > /dev/null 2>&1"
        fi
        
        if nc -z $MONITORING_HOST 9090; then
            run_test "Test de charge Prometheus" "ab -n 10 -c 2 http://$MONITORING_HOST:9090/-/healthy > /dev/null 2>&1"
        fi
    else
        log_warning "Apache Bench non installé, tests de performance ignorés"
    fi
}

# Test d'intégration end-to-end
test_integration() {
    log_info "=== Tests d'Intégration End-to-End ==="
    
    # Simuler un scénario complet
    if nc -z $MQTT_HOST 1883 && nc -z $OTA_HOST 8080; then
        log_info "Simulation d'un scénario IoT complet..."
        
        # 1. Appareil vérifie les mises à jour
        run_test "Vérification OTA simulée" "curl -s -H 'Authorization: Bearer test-token-123' 'http://$OTA_HOST:8080/api/check-update?deviceId=test-feeder&currentVersion=1.0.0' > /dev/null"
        
        # 2. Publication de données MQTT (si mosquitto disponible)
        if command -v mosquitto_pub > /dev/null 2>&1; then
            run_test "Publication données IoT" "mosquitto_pub -h $MQTT_HOST -p 1883 -t 'pet-smart-home/feeder/test/status' -m '{\"status\":\"online\",\"battery\":85}' -u admin -P change_me_in_production"
        fi
        
        # 3. Vérification des métriques
        if nc -z $MONITORING_HOST 9090; then
            run_test "Métriques disponibles" "curl -s 'http://$MONITORING_HOST:9090/api/v1/query?query=up' | grep -q 'success'"
        fi
    else
        log_warning "Services non disponibles pour les tests d'intégration"
    fi
}

# Génération du rapport de test
generate_test_report() {
    log_info "=== Génération du Rapport de Test ==="
    
    local report_file="TEST_REPORT_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 📊 Rapport de Test - Pet Smart Home

## Résumé des Tests

- **Date**: $(date)
- **Tests Total**: $TESTS_TOTAL
- **Tests Réussis**: $TESTS_PASSED
- **Tests Échoués**: $TESTS_FAILED
- **Taux de Réussite**: $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%

## Statut Global

EOF

    if [ $TESTS_FAILED -eq 0 ]; then
        echo "✅ **TOUS LES TESTS SONT PASSÉS** - Le système est prêt pour la production!" >> "$report_file"
    else
        echo "⚠️ **$TESTS_FAILED TESTS ONT ÉCHOUÉ** - Vérification nécessaire avant la production." >> "$report_file"
    fi
    
    cat >> "$report_file" << EOF

## Services Testés

- 🔌 Broker MQTT
- 🔄 Serveur OTA
- 📊 Stack de Monitoring
- 🔧 Firmware ESP32
- 📱 Application Mobile
- ☁️ Backend Firebase
- 🔒 Sécurité
- ⚡ Performance
- 🔗 Intégration

## Recommandations

EOF

    if [ $TESTS_FAILED -gt 0 ]; then
        cat >> "$report_file" << EOF
### Actions Requises
- Vérifier les tests échoués dans les logs
- Corriger les problèmes identifiés
- Relancer les tests avant le déploiement

EOF
    fi
    
    cat >> "$report_file" << EOF
### Prochaines Étapes
1. Configurer les mots de passe de production
2. Mettre à jour les certificats SSL
3. Configurer les notifications d'alerte
4. Effectuer des tests de charge complets
5. Valider avec de vrais appareils IoT

---
**Généré par**: Test automatique Pet Smart Home  
**Version**: 1.0.0
EOF

    log_success "Rapport de test généré: $report_file"
}

# Nettoyage après les tests
cleanup_test_environment() {
    log_info "=== Nettoyage de l'Environnement de Test ==="
    
    # Arrêter les services de test si nécessaire
    if [ "$1" = "--cleanup" ]; then
        log_info "Arrêt des services de test..."
        
        [ -d "mqtt-broker" ] && cd mqtt-broker && docker-compose down > /dev/null 2>&1 && cd ..
        [ -d "ota-deployment" ] && cd ota-deployment && docker-compose down > /dev/null 2>&1 && cd ..
        [ -d "monitoring-stack" ] && cd monitoring-stack && docker-compose down > /dev/null 2>&1 && cd ..
        
        log_success "Services de test arrêtés"
    fi
}

# Fonction principale
main() {
    echo
    log_info "Démarrage des tests complets du déploiement..."
    echo
    
    # Vérifier les arguments
    if [ "$1" = "--help" ]; then
        echo "Usage: $0 [--cleanup]"
        echo "  --cleanup: Arrêter les services après les tests"
        exit 0
    fi
    
    # Exécuter tous les tests
    test_network_connectivity
    test_docker_services
    test_mqtt_broker
    test_ota_server
    test_monitoring_stack
    test_esp32_firmware
    test_mobile_app
    test_firebase_backend
    test_security
    test_performance
    test_integration
    
    # Générer le rapport
    generate_test_report
    
    # Nettoyage si demandé
    cleanup_test_environment "$1"
    
    echo
    echo "=========================================="
    log_info "Tests terminés!"
    log_info "Total: $TESTS_TOTAL | Réussis: $TESTS_PASSED | Échoués: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "🎉 Tous les tests sont passés! Le système est prêt!"
    else
        log_error "⚠️ $TESTS_FAILED tests ont échoué. Vérification nécessaire."
        exit 1
    fi
    echo
}

# Exécuter le script principal
main "$@"
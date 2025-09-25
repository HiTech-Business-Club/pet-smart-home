#!/bin/bash

# Script de configuration Firebase pour la production
# Pet Smart Home - Configuration automatisée

set -e

echo "🚀 Configuration Firebase Production - Pet Smart Home"
echo "=================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PROJECT_ID="pet-smart-home-prod"
REGION="europe-west1"
STORAGE_BUCKET="${PROJECT_ID}.appspot.com"

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

# Vérifier si Firebase CLI est installé
check_firebase_cli() {
    log_info "Vérification de Firebase CLI..."
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI n'est pas installé"
        log_info "Installation de Firebase CLI..."
        npm install -g firebase-tools
        log_success "Firebase CLI installé"
    else
        log_success "Firebase CLI trouvé"
    fi
}

# Connexion à Firebase
firebase_login() {
    log_info "Connexion à Firebase..."
    if ! firebase projects:list &> /dev/null; then
        log_warning "Connexion Firebase requise"
        firebase login --no-localhost
    fi
    log_success "Connecté à Firebase"
}

# Créer le projet Firebase
create_firebase_project() {
    log_info "Création du projet Firebase: $PROJECT_ID"
    
    # Vérifier si le projet existe déjà
    if firebase projects:list | grep -q "$PROJECT_ID"; then
        log_warning "Le projet $PROJECT_ID existe déjà"
    else
        log_info "Création du nouveau projet..."
        firebase projects:create "$PROJECT_ID" --display-name "Pet Smart Home Production"
        log_success "Projet Firebase créé: $PROJECT_ID"
    fi
}

# Configurer le projet local
configure_local_project() {
    log_info "Configuration du projet local..."
    cd backend
    
    # Initialiser Firebase si nécessaire
    if [ ! -f ".firebaserc" ]; then
        firebase use --add "$PROJECT_ID"
        log_success "Projet configuré localement"
    else
        firebase use "$PROJECT_ID"
        log_success "Projet sélectionné: $PROJECT_ID"
    fi
    
    cd ..
}

# Déployer les règles et fonctions
deploy_backend() {
    log_info "Déploiement du backend Firebase..."
    cd backend
    
    # Installer les dépendances des Cloud Functions
    log_info "Installation des dépendances..."
    cd functions
    npm install
    cd ..
    
    # Déployer les règles Firestore
    log_info "Déploiement des règles Firestore..."
    firebase deploy --only firestore:rules --project="$PROJECT_ID"
    
    # Déployer les règles Storage
    log_info "Déploiement des règles Storage..."
    firebase deploy --only storage --project="$PROJECT_ID"
    
    # Déployer les Cloud Functions
    log_info "Déploiement des Cloud Functions..."
    firebase deploy --only functions --project="$PROJECT_ID"
    
    cd ..
    log_success "Backend Firebase déployé"
}

# Générer le rapport de configuration
generate_config_report() {
    log_info "Génération du rapport de configuration..."
    
    cat > FIREBASE_PRODUCTION_REPORT.md << EOF
# 📊 Rapport de Configuration Firebase Production

## Informations du Projet
- **Project ID**: $PROJECT_ID
- **Région**: $REGION
- **Storage Bucket**: $STORAGE_BUCKET
- **Date de création**: $(date)

## Services Configurés
- ✅ Firestore Database
- ✅ Cloud Functions
- ✅ Cloud Storage
- ✅ Authentication
- ✅ Hosting (optionnel)

## URLs Importantes
- **Console Firebase**: https://console.firebase.google.com/project/$PROJECT_ID
- **Firestore**: https://console.firebase.google.com/project/$PROJECT_ID/firestore
- **Functions**: https://console.firebase.google.com/project/$PROJECT_ID/functions
- **Storage**: https://console.firebase.google.com/project/$PROJECT_ID/storage
- **Authentication**: https://console.firebase.google.com/project/$PROJECT_ID/authentication

## Configuration Manuelle Requise

### 1. Authentication
- Aller sur la console Firebase Authentication
- Activer Email/Password et Google Sign-In
- Configurer les domaines autorisés

### 2. Secrets et Variables
- Configurer les variables d'environnement dans GitHub Secrets
- Mettre à jour les mots de passe dans production.json
- Configurer les webhooks et tokens d'API

### 3. Monitoring
- Configurer les alertes email/SMS
- Mettre en place les webhooks Slack
- Configurer les métriques personnalisées

## Prochaines Étapes
1. Tester la connexion depuis l'application mobile
2. Déployer le serveur OTA
3. Configurer le broker MQTT
4. Mettre en place le monitoring
5. Tests d'intégration complets

## Sécurité
- ⚠️ Changer tous les mots de passe par défaut
- ⚠️ Configurer les règles de sécurité Firestore
- ⚠️ Activer l'audit logging
- ⚠️ Configurer les sauvegardes automatiques

---
**Généré le**: $(date)
**Version**: 1.0.0
EOF
    
    log_success "Rapport de configuration généré: FIREBASE_PRODUCTION_REPORT.md"
}

# Fonction principale
main() {
    echo
    log_info "Démarrage de la configuration Firebase Production..."
    echo
    
    check_firebase_cli
    firebase_login
    create_firebase_project
    configure_local_project
    deploy_backend
    generate_config_report
    
    echo
    log_success "🎉 Configuration Firebase Production terminée avec succès!"
    echo
    log_info "Consultez le fichier FIREBASE_PRODUCTION_REPORT.md pour les détails"
    log_warning "N'oubliez pas de compléter la configuration manuelle dans la console Firebase"
    echo
}

# Exécuter le script principal
main "$@"
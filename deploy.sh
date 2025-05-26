#!/bin/bash

# Script de déploiement SonarQube pour VPS Dokploy
# Usage: ./deploy.sh [production|development]

set -e

ENVIRONMENT=${1:-development}
COMPOSE_FILE="docker-compose.yml"

if [ "$ENVIRONMENT" = "production" ]; then
    COMPOSE_FILE="docker-compose.dokploy.yml"
fi

echo "🚀 Déploiement de SonarQube en mode: $ENVIRONMENT"

# Vérifications préalables
echo "📋 Vérification des prérequis..."

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé"
    exit 1
fi

# Vérifier Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas installé"
    exit 1
fi

# Vérifier les paramètres système
echo "🔧 Vérification des paramètres système..."

MAX_MAP_COUNT=$(sysctl -n vm.max_map_count)
if [ "$MAX_MAP_COUNT" -lt 524288 ]; then
    echo "⚠️  vm.max_map_count est trop bas ($MAX_MAP_COUNT). Configuration..."
    sudo sysctl -w vm.max_map_count=524288
    echo 'vm.max_map_count=524288' | sudo tee -a /etc/sysctl.conf
fi

FILE_MAX=$(sysctl -n fs.file-max)
if [ "$FILE_MAX" -lt 131072 ]; then
    echo "⚠️  fs.file-max est trop bas ($FILE_MAX). Configuration..."
    sudo sysctl -w fs.file-max=131072
    echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.conf
fi

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo "📝 Création du fichier .env..."
    cat > .env << EOF
# Base de données PostgreSQL
POSTGRES_USER=sonar
POSTGRES_PASSWORD=$(openssl rand -base64 32)
POSTGRES_DB=sonar

# Port SonarQube
SONAR_PORT=9000
EOF
    echo "✅ Fichier .env créé avec un mot de passe aléatoire"
fi

# Arrêter les conteneurs existants
echo "🛑 Arrêt des conteneurs existants..."
docker-compose -f $COMPOSE_FILE down 2>/dev/null || true

# Nettoyer les images obsolètes
echo "🧹 Nettoyage des images obsolètes..."
docker system prune -f

# Construire et démarrer
echo "🔨 Construction et démarrage des conteneurs..."
if [ "$ENVIRONMENT" = "production" ]; then
    docker-compose -f $COMPOSE_FILE build --no-cache
fi

docker-compose -f $COMPOSE_FILE up -d

# Attendre que les services soient prêts
echo "⏳ Attente du démarrage des services..."
sleep 30

# Vérifier le statut des conteneurs
echo "🔍 Vérification du statut des conteneurs..."
docker-compose -f $COMPOSE_FILE ps

# Test de connectivité
echo "🌐 Test de connectivité SonarQube..."
for i in {1..30}; do
    if curl -sf http://localhost:9000/api/system/status > /dev/null; then
        echo "✅ SonarQube est accessible !"
        break
    fi
    echo "⏳ Tentative $i/30..."
    sleep 10
done

echo ""
echo "🎉 Déploiement terminé !"
echo ""
echo "📊 Accès à SonarQube:"
echo "   URL: http://$(hostname -I | awk '{print $1}'):9000"
echo "   Login: admin"
echo "   Mot de passe: admin (à changer lors de la première connexion)"
echo ""
echo "🔧 Commandes utiles:"
echo "   Logs SonarQube: docker-compose -f $COMPOSE_FILE logs -f sonarqube"
echo "   Logs PostgreSQL: docker-compose -f $COMPOSE_FILE logs -f db"
echo "   Arrêter: docker-compose -f $COMPOSE_FILE down"
echo "   Redémarrer: docker-compose -f $COMPOSE_FILE restart"
echo ""
echo "⚠️  N'oubliez pas de:"
echo "   1. Changer le mot de passe admin"
echo "   2. Configurer HTTPS avec un reverse proxy"
echo "   3. Sauvegarder régulièrement vos données" 
#!/bin/bash

# Script de vérification du déploiement SonarQube
# Serveur cible: 168.231.87.2

SERVER_IP="168.231.87.2"
DOKPLOY_PORT="3000"
SONAR_PORT="9000"

echo "🔍 Vérification du déploiement SonarQube sur $SERVER_IP"
echo "=================================================="

# Fonction pour tester la connectivité
test_connectivity() {
    local url=$1
    local service=$2
    
    echo -n "📡 Test de connectivité $service ($url)... "
    
    if curl -s --connect-timeout 10 --max-time 30 "$url" > /dev/null; then
        echo "✅ OK"
        return 0
    else
        echo "❌ ÉCHEC"
        return 1
    fi
}

# Test de l'interface Dokploy
echo ""
echo "🐳 Vérification de Dokploy"
test_connectivity "http://$SERVER_IP:$DOKPLOY_PORT" "Dokploy"

# Test de SonarQube
echo ""
echo "📊 Vérification de SonarQube"
test_connectivity "http://$SERVER_IP:$SONAR_PORT" "SonarQube Web"

# Test de l'API SonarQube
echo ""
echo "🔌 Vérification de l'API SonarQube"
API_URL="http://$SERVER_IP:$SONAR_PORT/api/system/status"
echo -n "📡 Test API SonarQube ($API_URL)... "

API_RESPONSE=$(curl -s --connect-timeout 10 --max-time 30 "$API_URL" 2>/dev/null)
if echo "$API_RESPONSE" | grep -q '"status":"UP"'; then
    echo "✅ OK (SonarQube fonctionne)"
elif [ -n "$API_RESPONSE" ]; then
    echo "⚠️  Réponse reçue mais statut inconnu: $API_RESPONSE"
else
    echo "❌ Pas de réponse"
fi

# Test de la page de login SonarQube
echo ""
echo "🔐 Vérification de la page de login"
LOGIN_URL="http://$SERVER_IP:$SONAR_PORT/sessions/new"
echo -n "📡 Test page de login ($LOGIN_URL)... "

if curl -s --connect-timeout 10 --max-time 30 "$LOGIN_URL" | grep -q "login"; then
    echo "✅ OK"
else
    echo "❌ ÉCHEC"
fi

echo ""
echo "📈 Tests de performance"
echo "======================"

# Test de latence
echo -n "⏱️  Latence vers le serveur... "
PING_RESULT=$(ping -c 3 $SERVER_IP 2>/dev/null | grep "avg" | cut -d'/' -f5 | cut -d'.' -f1)
if [ -n "$PING_RESULT" ]; then
    echo "${PING_RESULT}ms"
else
    echo "Non disponible"
fi

# Test de débit (basique)
echo -n "🚀 Test de débit HTTP... "
TIME_RESULT=$(curl -w "%{time_total}" -s -o /dev/null "http://$SERVER_IP:$SONAR_PORT" 2>/dev/null)
if [ -n "$TIME_RESULT" ]; then
    echo "${TIME_RESULT}s"
else
    echo "Non disponible"
fi

echo ""
echo "🔗 URLs utiles"
echo "=============="
echo "🐳 Dokploy:        http://$SERVER_IP:$DOKPLOY_PORT"
echo "📊 SonarQube:      http://$SERVER_IP:$SONAR_PORT"
echo "🔌 API Status:     http://$SERVER_IP:$SONAR_PORT/api/system/status"
echo "🔐 Login:          http://$SERVER_IP:$SONAR_PORT/sessions/new"
echo "📚 Documentation: http://$SERVER_IP:$SONAR_PORT/documentation"

echo ""
echo "💡 Prochaines étapes"
echo "==================="
echo "1. Connectez-vous à Dokploy: http://$SERVER_IP:$DOKPLOY_PORT"
echo "2. Créez un nouveau projet 'Compose'"
echo "3. Uploadez le fichier docker-compose.dokploy.yml"
echo "4. Configurez les variables d'environnement"
echo "5. Déployez le projet"
echo "6. Accédez à SonarQube: http://$SERVER_IP:$SONAR_PORT"
echo "7. Login: admin / admin (à changer immédiatement)"

echo ""
echo "✅ Vérification terminée !" 
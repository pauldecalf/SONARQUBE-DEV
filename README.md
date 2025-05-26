# SonarQube Docker pour VPS Dokploy

Configuration Docker pour déployer SonarQube avec PostgreSQL sur VPS utilisant Dokploy.

**🎯 Serveur cible :** http://168.231.87.2:3000/

## 📋 Prérequis

- VPS avec au moins 4GB de RAM (recommandé : 8GB)
- Dokploy installé et configuré sur 168.231.87.2:3000
- Accès SSH au serveur (optionnel pour les optimisations)

## 🚀 Déploiement rapide sur Dokploy

### 1. Vérification préalable
```bash
# Testez la connectivité avec votre serveur
./check-deployment.sh
```

### 2. Déploiement via Dokploy

1. **Accédez à Dokploy** : http://168.231.87.2:3000/
2. **Créez un nouveau projet** → Sélectionnez "Compose"
3. **Uploadez** le fichier `docker-compose.dokploy.yml`
4. **Configurez les variables d'environnement** :
   ```env
   POSTGRES_USER=sonar
   POSTGRES_PASSWORD=VotreMotDePasseSecurise123!
   POSTGRES_DB=sonar
   SONAR_PORT=9000
   ```
5. **Déployez** et attendez que le statut soit "Running"

### 3. Accès à SonarQube

Une fois déployé, SonarQube sera accessible sur :
- **URL principale** : http://168.231.87.2:9000
- **Login par défaut** : admin / admin

⚠️ **Important** : Changez le mot de passe admin lors de la première connexion !

## ⚙️ Configuration avancée

### Optimisations système (recommandées)

Connectez-vous en SSH à votre serveur et exécutez :

```bash
# Configuration pour SonarQube/Elasticsearch
sudo sysctl -w vm.max_map_count=524288
echo 'vm.max_map_count=524288' | sudo tee -a /etc/sysctl.conf

# Augmentation des limites de fichiers
sudo sysctl -w fs.file-max=131072
echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.conf

# Application des changements
sudo sysctl -p
```

### Variables d'environnement personnalisées

Vous pouvez personnaliser les variables suivantes dans Dokploy :

```env
# Base de données
POSTGRES_USER=sonar
POSTGRES_PASSWORD=VotreMotDePasseSecurise123!
POSTGRES_DB=sonar

# Configuration SonarQube
SONAR_PORT=9000
```

## 🔧 Fichiers de configuration

### Fichiers principaux
- `docker-compose.dokploy.yml` - Configuration optimisée pour Dokploy
- `docker-compose.yml` - Configuration de base
- `Dockerfile` - Image SonarQube personnalisée (optionnel)
- `DOKPLOY_DEPLOYMENT.md` - Guide détaillé de déploiement

### Scripts utiles
- `check-deployment.sh` - Vérification de connectivité
- `deploy.sh` - Script de déploiement automatisé (local)

## 🔍 Vérification du déploiement

### Test automatique
```bash
./check-deployment.sh
```

### Test manuel
```bash
# Test de l'API SonarQube
curl http://168.231.87.2:9000/api/system/status

# Réponse attendue : {"status":"UP"}
```

## 📊 Monitoring et maintenance

### Via l'interface Dokploy
- **Logs** : Consultez les logs en temps réel dans l'interface
- **Métriques** : Surveillance des performances
- **Redéploiement** : Mise à jour en un clic

### Commandes utiles (SSH)
```bash
# Vérification des conteneurs
docker ps | grep sonar

# Logs SonarQube
docker logs -f sonarqube

# Logs PostgreSQL
docker logs -f sonarqube-db

# Statistiques
docker stats sonarqube sonarqube-db
```

## 🛡️ Sécurité

### Recommandations
1. **Changez le mot de passe admin** immédiatement
2. **Configurez HTTPS** via un reverse proxy
3. **Limitez l'accès réseau** si nécessaire
4. **Mettez à jour régulièrement** via Dokploy

### Configuration firewall (si nécessaire)
```bash
# Ouvrir le port SonarQube
sudo ufw allow 9000/tcp
sudo ufw reload
```

## 🔗 Intégration CI/CD

### Configuration des pipelines

Une fois SonarQube déployé, configurez vos projets :

```bash
# Exemple avec SonarScanner
sonar-scanner \
  -Dsonar.projectKey=mon-projet \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://168.231.87.2:9000 \
  -Dsonar.login=votre-token
```

### GitLab CI exemple
```yaml
sonarqube-check:
  script:
    - sonar-scanner
      -Dsonar.projectKey=$CI_PROJECT_NAME
      -Dsonar.sources=.
      -Dsonar.host.url=http://168.231.87.2:9000
      -Dsonar.login=$SONAR_TOKEN
```

## 🆘 Dépannage

### Problèmes courants

#### SonarQube ne démarre pas
```bash
# Vérifier vm.max_map_count
ssh root@168.231.87.2 "sysctl vm.max_map_count"

# Doit être >= 524288
```

#### Problème de base de données
```bash
# Test connexion PostgreSQL
docker exec sonarqube-db psql -U sonar -d sonar -c "SELECT 1;"
```

#### Problème d'accès réseau
```bash
# Test de connectivité
curl -f http://168.231.87.2:9000

# Vérification firewall
sudo ufw status
```

### Support
- **Interface Dokploy** : http://168.231.87.2:3000/
- **Logs en temps réel** : Disponibles dans Dokploy
- **Documentation SonarQube** : http://168.231.87.2:9000/documentation

## 💾 Sauvegarde

### Sauvegarde automatique via script
```bash
# Se connecter au serveur
ssh root@168.231.87.2

# Sauvegarde des volumes
docker run --rm \
  -v sonarqube_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/sonarqube-backup-$(date +%Y%m%d).tar.gz /data
```

### Restauration
```bash
# Restaurer depuis une sauvegarde
docker run --rm \
  -v sonarqube_data:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/sonarqube-backup-YYYYMMDD.tar.gz -C /
```

## ✅ Checklist de déploiement

- [ ] Dokploy accessible sur http://168.231.87.2:3000/
- [ ] Paramètres système optimisés (vm.max_map_count, etc.)
- [ ] Projet créé dans Dokploy (type "Compose")
- [ ] Variables d'environnement configurées
- [ ] Déploiement réussi (statut "Running")
- [ ] SonarQube accessible sur http://168.231.87.2:9000
- [ ] Mot de passe admin changé
- [ ] Premier projet analysé avec succès
- [ ] Sauvegarde configurée

## 📝 Notes importantes

- **Première installation** : Peut prendre 5-10 minutes
- **Ressources recommandées** : 4GB RAM minimum, 8GB recommandé
- **Stockage** : Les données sont persistées dans des volumes Docker
- **Mises à jour** : Utilisez le bouton "Redeploy" dans Dokploy 
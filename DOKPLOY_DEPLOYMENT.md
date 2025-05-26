# Guide de déploiement SonarQube sur Dokploy
**Serveur cible :** http://168.231.87.2:3000/

## 🚀 Étapes de déploiement

### 1. Préparation des fichiers

Assurez-vous d'avoir tous les fichiers nécessaires :
- `docker-compose.dokploy.yml` (configuration principale)
- `Dockerfile` (optionnel)
- `init-scripts/01-configure-postgres.sql` (optimisations DB)

### 2. Connexion à Dokploy

1. Accédez à votre interface Dokploy : **http://168.231.87.2:3000/**
2. Connectez-vous avec vos identifiants

### 3. Création du projet dans Dokploy

#### Option A : Déploiement via Git Repository
1. Dans Dokploy, cliquez sur **"New Project"**
2. Sélectionnez **"Compose"**
3. Configurez :
   - **Name** : `sonarqube-production`
   - **Repository URL** : L'URL de votre repo Git
   - **Branch** : `main` ou `master`
   - **Compose File Path** : `docker-compose.dokploy.yml`

#### Option B : Upload direct des fichiers
1. Cliquez sur **"New Project"**
2. Sélectionnez **"Compose"**
3. Uploadez directement le fichier `docker-compose.dokploy.yml`

### 4. Configuration des variables d'environnement

Dans Dokploy, ajoutez ces variables d'environnement :

```env
POSTGRES_USER=sonar
POSTGRES_PASSWORD=VotreMotDePasseSecurise123!
POSTGRES_DB=sonar
SONAR_PORT=9000
```

### 5. Configuration du domaine et proxy

#### Configuration simple (IP directe)
- **Host** : `168.231.87.2`
- **Port** : `9000`
- **Protocol** : `HTTP`

#### Configuration avec sous-domaine (optionnel)
Si vous avez un domaine :
- **Host** : `sonar.votre-domaine.com`
- **Port** : `9000`
- **Protocol** : `HTTPS`
- **SSL** : Activé (Let's Encrypt)

### 6. Déploiement

1. Cliquez sur **"Deploy"**
2. Attendez que le statut passe à **"Running"**
3. Vérifiez les logs pour s'assurer que tout fonctionne

## 🔧 Configuration spécifique au serveur

### Optimisations système requises

Connectez-vous en SSH à votre serveur `168.231.87.2` et exécutez :

```bash
# Augmenter vm.max_map_count pour Elasticsearch (dans SonarQube)
echo 'vm.max_map_count=524288' | sudo tee -a /etc/sysctl.conf
sudo sysctl -w vm.max_map_count=524288

# Augmenter les limites de fichiers
echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.conf
sudo sysctl -w fs.file-max=131072

# Appliquer les changements
sudo sysctl -p
```

### Configuration firewall (si nécessaire)

```bash
# Ouvrir le port 9000 si le firewall est actif
sudo ufw allow 9000/tcp
sudo ufw reload
```

## 📊 Accès à SonarQube

### URLs d'accès
- **Principal** : http://168.231.87.2:9000
- **API** : http://168.231.87.2:9000/api
- **Documentation** : http://168.231.87.2:9000/documentation

### Identifiants par défaut
- **Utilisateur** : `admin`
- **Mot de passe** : `admin`

⚠️ **IMPORTANT** : Changez immédiatement le mot de passe après la première connexion !

## 🔍 Vérification du déploiement

### Via l'interface Dokploy
1. Vérifiez que le statut est **"Running"**
2. Consultez les logs pour détecter d'éventuelles erreurs
3. Testez l'accès via l'URL configurée

### Via l'API SonarQube
```bash
# Test de connectivité
curl -f http://168.231.87.2:9000/api/system/status

# Réponse attendue : {"status":"UP"}
```

### Via SSH (sur le serveur)
```bash
# Vérifier les conteneurs
docker ps | grep sonar

# Vérifier les logs
docker logs sonarqube
docker logs sonarqube-db
```

## 🛠️ Maintenance

### Mise à jour via Dokploy
1. Dans l'interface Dokploy, allez dans votre projet
2. Cliquez sur **"Redeploy"**
3. Dokploy va automatiquement recréer les conteneurs

### Sauvegarde des données
```bash
# Se connecter au serveur
ssh root@168.231.87.2

# Sauvegarde des volumes
docker run --rm \
  -v sonarqube_sonarqube_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/sonarqube-backup-$(date +%Y%m%d).tar.gz /data
```

## 🆘 Dépannage

### SonarQube ne démarre pas
```bash
# Vérifier vm.max_map_count
ssh root@168.231.87.2 "sysctl vm.max_map_count"

# Vérifier les logs
docker logs sonarqube

# Redémarrer les conteneurs via Dokploy
```

### Problème de base de données
```bash
# Tester la connexion PostgreSQL
docker exec sonarqube-db psql -U sonar -d sonar -c "SELECT 1;"

# Vérifier les logs PostgreSQL
docker logs sonarqube-db
```

### Problème d'accès réseau
```bash
# Vérifier que le port est ouvert
nmap -p 9000 168.231.87.2

# Vérifier les règles de firewall
sudo ufw status
```

## 📈 Monitoring et logs

### Dans Dokploy
- Utilisez l'onglet **"Logs"** pour voir les logs en temps réel
- L'onglet **"Metrics"** pour surveiller les performances

### Commandes utiles
```bash
# Logs SonarQube en temps réel
docker logs -f sonarqube

# Logs PostgreSQL
docker logs -f sonarqube-db

# Statistiques des conteneurs
docker stats sonarqube sonarqube-db
```

## 🔗 Intégration CI/CD

Une fois SonarQube déployé, configurez vos pipelines CI/CD :

```yaml
# Exemple pour GitLab CI
sonarqube-check:
  script:
    - sonar-scanner
      -Dsonar.projectKey=$CI_PROJECT_NAME
      -Dsonar.sources=.
      -Dsonar.host.url=http://168.231.87.2:9000
      -Dsonar.login=$SONAR_TOKEN
```

## ✅ Checklist finale

- [ ] Serveur accessible sur http://168.231.87.2:3000/
- [ ] Paramètres système configurés (vm.max_map_count, etc.)
- [ ] Variables d'environnement définies dans Dokploy
- [ ] Déploiement réussi (statut "Running")
- [ ] SonarQube accessible sur http://168.231.87.2:9000
- [ ] Mot de passe admin changé
- [ ] Test d'analyse d'un projet
- [ ] Sauvegarde configurée 
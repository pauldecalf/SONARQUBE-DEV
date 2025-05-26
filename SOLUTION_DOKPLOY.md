# 🚨 Résolution du problème de déploiement Dokploy

## Problème rencontré

```
Nixpacks was unable to generate a build plan for this app.
Please check the documentation for supported languages: https://nixpacks.com
```

## 🔍 Cause du problème

Dokploy essaie d'utiliser Nixpacks pour construire l'application au lieu de reconnaître que c'est un projet Docker Compose.

## ✅ Solutions

### Solution 1 : Configuration correcte dans Dokploy (Recommandée)

1. **Supprimer l'application actuelle**
   - Dans Dokploy (http://168.231.87.2:3000/), allez dans votre projet `sonarqube-sonarqube-rovhs5`
   - Cliquez sur "Delete" pour supprimer l'application

2. **Créer une nouvelle application avec le bon type**
   - Cliquez sur **"New Project"**
   - **NE PAS** sélectionner "GitHub" ou "Git Repository"
   - Sélectionnez **"Compose"** directement
   - Nommez votre projet : `sonarqube-production`

3. **Configuration manuelle**
   - Dans l'onglet "Compose", collez le contenu du fichier `docker-compose.dokploy.yml`
   - Configurez les variables d'environnement dans l'onglet "Environment" :
     ```
     POSTGRES_USER=sonar
     POSTGRES_PASSWORD=VotreMotDePasseSecurise123!
     POSTGRES_DB=sonar
     SONAR_PORT=9000
     ```
   - Cliquez sur "Deploy"

### Solution 2 : Correction du repository GitHub

Si vous voulez continuer avec GitHub, ajoutez ces fichiers à votre repository :

1. **Fichier `dokploy.json`** (déjà créé dans ce projet)
   ```json
   {
     "type": "compose",
     "composeFile": "docker-compose.dokploy.yml",
     "environment": {
       "POSTGRES_USER": "sonar",
       "POSTGRES_PASSWORD": "VotreMotDePasseSecurise123!",
       "POSTGRES_DB": "sonar",
       "SONAR_PORT": "9000"
     }
   }
   ```

2. **Pusher les modifications sur GitHub**
   ```bash
   git add dokploy.json
   git commit -m "Add Dokploy configuration"
   git push origin main
   ```

3. **Recréer l'application dans Dokploy**
   - Supprimez l'application actuelle
   - Créez une nouvelle application "GitHub"
   - Sélectionnez votre repository `pauldecalf/SONARQUBE-DEV`
   - Dokploy devrait maintenant détecter le fichier `dokploy.json`

### Solution 3 : Configuration via les paramètres de l'application

Si l'application existe déjà :

1. **Aller dans les paramètres de l'application**
2. **Changer le "Source Type"** de "Nixpacks" vers "Docker Compose"
3. **Spécifier le fichier compose** : `docker-compose.dokploy.yml`
4. **Redéployer**

## 📋 Étapes détaillées pour la Solution 1 (Recommandée)

### Étape 1 : Suppression de l'application actuelle
1. Connectez-vous à http://168.231.87.2:3000/
2. Trouvez l'application `sonarqube-sonarqube-rovhs5`
3. Cliquez sur l'application puis sur "Settings"
4. Scrollez vers le bas et cliquez sur "Delete Application"
5. Confirmez la suppression

### Étape 2 : Création d'une nouvelle application Compose
1. Sur le dashboard Dokploy, cliquez sur **"New Project"**
2. Sélectionnez **"Compose"** (PAS GitHub)
3. Configurez :
   - **Name** : `sonarqube-production`
   - **Description** : `SonarQube avec PostgreSQL`

### Étape 3 : Configuration du Docker Compose
Dans l'onglet "Compose", collez ce contenu :

```yaml
version: '3.8'

services:
  sonarqube:
    image: sonarqube:10.3-community
    container_name: sonarqube
    depends_on:
      - db
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://db:5432/sonar
      SONAR_JDBC_USERNAME: ${POSTGRES_USER:-sonar}
      SONAR_JDBC_PASSWORD: ${POSTGRES_PASSWORD:-sonar}
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: true
      SONAR_WEB_HOST: 0.0.0.0
      SONAR_WEB_PORT: 9000
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
    ports:
      - "${SONAR_PORT:-9000}:9000"
    networks:
      - sonar-network
    restart: unless-stopped
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:9000/api/system/status || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 80s

  db:
    image: postgres:15-alpine
    container_name: sonarqube-db
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-sonar}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-sonar}
      POSTGRES_DB: ${POSTGRES_DB:-sonar}
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --lc-collate=C --lc-ctype=C"
    volumes:
      - postgresql_data:/var/lib/postgresql/data
    networks:
      - sonar-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-sonar}"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  sonarqube_data:
    driver: local
  sonarqube_extensions:
    driver: local
  sonarqube_logs:
    driver: local
  postgresql_data:
    driver: local

networks:
  sonar-network:
    driver: bridge
```

### Étape 4 : Configuration des variables d'environnement
Dans l'onglet "Environment", ajoutez :
```
POSTGRES_USER=sonar
POSTGRES_PASSWORD=VotreMotDePasseSecurise123!
POSTGRES_DB=sonar
SONAR_PORT=9000
```

### Étape 5 : Configuration du domaine (optionnel)
Dans l'onglet "Domains" :
- **Host** : `168.231.87.2` ou votre domaine
- **Port** : `9000`
- **Protocol** : `HTTP` (ou HTTPS si vous avez un certificat)

### Étape 6 : Déploiement
1. Cliquez sur **"Deploy"**
2. Attendez que le statut passe à "Running"
3. Vérifiez les logs pour s'assurer que tout fonctionne

## 🔍 Vérification du déploiement

### Via Dokploy
1. Vérifiez que l'application a le statut "Running"
2. Consultez les logs dans l'onglet "Logs"
3. Testez l'accès via l'URL configurée

### Via l'URL directe
- Accédez à : http://168.231.87.2:9000
- Vous devriez voir la page de login SonarQube
- Login : `admin` / Mot de passe : `admin`

### Via l'API
```bash
curl http://168.231.87.2:9000/api/system/status
# Réponse attendue : {"status":"UP"}
```

## 🆘 Si le problème persiste

1. **Vérifiez les logs Dokploy** dans l'interface
2. **Vérifiez les logs des conteneurs** :
   ```bash
   ssh root@168.231.87.2
   docker logs sonarqube
   docker logs sonarqube-db
   ```
3. **Vérifiez les paramètres système** :
   ```bash
   sysctl vm.max_map_count  # Doit être >= 524288
   ```

## 📞 Support

Si vous continuez à avoir des problèmes :
1. Consultez les logs dans Dokploy
2. Vérifiez que les variables d'environnement sont correctement définies
3. Assurez-vous que le fichier `docker-compose.dokploy.yml` est correctement formaté

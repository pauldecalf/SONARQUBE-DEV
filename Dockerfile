FROM sonarqube:10.3-community

# Installation des plugins utiles (optionnel)
USER root

# Création du répertoire pour les plugins personnalisés
RUN mkdir -p /opt/sonarqube/extensions/plugins

# Configuration système pour optimiser les performances
RUN echo "vm.max_map_count=524288" >> /etc/sysctl.conf && \
    echo "fs.file-max=131072" >> /etc/sysctl.conf

# Retour à l'utilisateur sonarqube
USER sonarqube

# Copie de configurations personnalisées si nécessaire
# COPY --chown=sonarqube:sonarqube conf/sonar.properties /opt/sonarqube/conf/

# Variables d'environnement par défaut
ENV SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true

EXPOSE 9000 
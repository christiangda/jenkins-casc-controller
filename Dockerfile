ARG IMAGE_TAG=${IMAGE_TAG:-2.375.1-lts-jdk17}
FROM jenkins/jenkins:${IMAGE_TAG}

# Healthcheck endpoint
ARG HEALTHCHECK_ENDPOINT=${HEALTHCHECK_ENDPOINT:-http://localhost:8080/login}

# This variable specify where we want to store JCasC files
# https://github.com/jenkinsci/configuration-as-code-plugin/blob/master/README.md#getting-started
ENV JENKINS_REF=/usr/share/jenkins/ref
ENV CASC_JENKINS_CONFIG=/usr/share/jenkins/ref/casc_configs
ENV HOME=/var/jenkins_home
ENV JENKINS_HOME=/var/jenkins_home

# This is necessary to install or update the image
# https://github.com/jenkinsci/docker#installing-more-tools
USER root
RUN apt update -y && apt upgrade -y \
  && rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true

# drop back to secure user
USER jenkins

# copy files and maintaint the folder structure
COPY --chown=jenkins:jenkins config/casc/ ${CASC_JENKINS_CONFIG}/

# Skip initial setup
# https://github.com/jenkinsci/docker#usage-1
RUN echo 2.0 > ${JENKINS_REF}/jenkins.install.UpgradeWizard.state

# copy custom groovy scripts
COPY config/scripts/ ${JENKINS_REF}/init.groovy.d/

# install plugins
COPY config/plugins/plugins.txt ${JENKINS_REF}/plugins.txt
RUN jenkins-plugin-cli -f ${JENKINS_REF}/plugins.txt

# place for certificate or keystore
RUN mkdir $JENKINS_HOME/keystore
VOLUME $JENKINS_HOME/keystore

WORKDIR ${HOME}

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

HEALTHCHECK --interval=2m --timeout=5s \
  CMD curl --insecure --fail $HEALTHCHECK_ENDPOINT >/dev/null || exit 1

ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/entrypoint.sh"]
#CMD ["/usr/bin/tini","--","/usr/local/bin/entrypoint.sh"]
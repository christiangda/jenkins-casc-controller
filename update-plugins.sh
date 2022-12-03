#!/bin/bash

set -e

JENKINS_PLUGINS_LIST_FILE="config/plugins/plugins.txt"
TMP_PLUGINS_LIST_FILE="plugins.tmp"
CONTAINER_IMAGE_NAME="jenkins/casc-jdk17-local-update-plugins"
RUNING_IMAGE_NAME="jcasc-jdk17-local"

if [[ ! -f ./update-plugins-list.sh ]] && [[ ! -f ./Dockerfile ]]; then
    printf "Please run this script from the root of the project ⚠️\n"
    exit 1
fi

rm -rf $TMP_PLUGINS_LIST_FILE
rm -rf ./Dockerfile.tmp
sed '/ENTRYPOINT/d' ./Dockerfile > ./Dockerfile.tmp
docker build --tag $CONTAINER_IMAGE_NAME -f ./Dockerfile.tmp .
rm -rf ./Dockerfile.tmp

rm -rf $TMP_PLUGINS_LIST_FILE
docker run --rm -ti \
    --name $RUNING_IMAGE_NAME \
  ${CONTAINER_IMAGE_NAME} bash -c "jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt --available-updates --output txt" > $TMP_PLUGINS_LIST_FILE 2>/dev/null
#mv $TMP_PLUGINS_LIST_FILE $JENKINS_PLUGINS_LIST_FILE
cat $TMP_PLUGINS_LIST_FILE | sort > $JENKINS_PLUGINS_LIST_FILE
rm -rf $TMP_PLUGINS_LIST_FILE

printf "Plugins updated ✅\n"

exit 0
#!/bin/bash

set -e

# http://www.amp-what.com/unicode/search/
# red cross mark = ❌
# green cross mark = ❎
# yellow warning sign = ⚠️
# green check mark = ✅
# yellow ligthining = ⚡
# finger pointing up = ☝
# exclamation mark = ❗
# hand open = ✋
# tips = 💡

SCRIPT_TOOLS="aws docker jq keytool grep awk patch"
CONTAINER_IMAGE_NAME="jenkins/jcasc-jdk17-local"
RUNING_IMAGE_NAME="jcasc-jdk17-local"

JENKINS_HOME="/var/jenkins_home/keystore"
JENKINS_KEYSTORE="${JENKINS_HOME}/keystore"
JENKINS_ETC_HOSTS_FILE="/etc/hosts"
JENKINS_ETC_HOSTS_IP="127.0.0.1"
JENKINS_REF="/usr/share/jenkins/ref"

JCASC_CONTROLLER_URL_PROTOCOL="https"
JCASC_CONTROLLER_INTERNAL_URL_PROTOCOL="https"
JCASC_CONTROLLER_NAME="jenkins.local"
JCASC_CONTROLLER_INTERNAL_NAME="jenkins.local"
JCASC_CONTROLLER_PORT=443
JCASC_CONTROLLER_INTERNAL_PORT=443
JCASC_CONTROLLER_JNLP_PORT=50000

DOCKER_ENV_VARS="local_env_vars"
HEALTHCHECK_ENDPOINT="https://localhost:443/login"

#######################################################################################################################
# Arguments of the script
function print_usage() {
  printf "Usage: %s -x <path to SAML XML Metadata file> -s <path to private ssh key>\n" "$0"
}

while getopts ':x:s:' flag; do
  case "${flag}" in
    x)
      printf "Using SAML XML file %s \n" "${OPTARG}"
      export SAML_METADATA_FILE="${OPTARG}"
      ;;
    s)
      printf "Using SSH Private key file %s \n" "${OPTARG}"
      export SSH_PRIVATE_KEY_FILE="${OPTARG}"
      ;;
    *)
      print_usage
      exit 0
      ;;
  esac
done
if (( $OPTIND == 1 )); then
   print_usage
   exit 0
fi

#######################################################################################################################
# Check if you have necessary tools installed
printf "Check if tools are installed ...\n"
for tool in $SCRIPT_TOOLS; do
  if ! [ -x "$(command -v ${tool})" ]; then
    printf "  '$tool' is not installed ✋\n"
    exit 1
  fi
  printf "  '$tool' is installed ✅\n"
done

if [[ ! -f ./run-local.sh ]] && [[ ! -f ./Dockerfile ]]; then
    printf "Please run this script from the root of the project ❌	\n"
    exit 1
fi

if [[ ! -f $DOCKER_ENV_VARS ]]; then
    printf "Please create a file %s and fill it with necessary variables ❌	\n" "${DOCKER_ENV_VARS}"
    exit 1
fi


#######################################################################################################################
# This section is about preparing the Dockerfile and jcasc configuiration
# before building the new docker image
printf "\n\n"

printf "Building container image \n"
docker build --tag $CONTAINER_IMAGE_NAME -f ./Dockerfile .
printf "  %s ✅\n" "$CONTAINER_IMAGE_NAME"

#######################################################################################################################
# create a new certificate for jenkins, needed to run jenkins using https protocol requested by Google SAML Application
# https://stackoverflow.com/questions/29755014/setup-secured-jenkins-master-with-docker
sleep 2
printf "Create Certificate Authority \n"
KEYSTORE_PASSWORD="thepass"
rm -rf jenkins_keystore.jks
keytool -genkey \
  -keyalg RSA \
  -keystore jenkins_keystore.jks \
  -alias $JCASC_CONTROLLER_NAME \
  -storepass $KEYSTORE_PASSWORD \
  -keypass $KEYSTORE_PASSWORD \
  -validity 2048 \
  -dname "CN=${JCASC_CONTROLLER_NAME}, OU=DevOps, O=slashdevops.com, L=Barcelona, ST=Barcelona, C=ES"
printf "  jenkins_keystore.jks ✅\n"

#######################################################################################################################
# add/update the name jenkins.local to the hosts file, needed by Google SAML Application
printf "Adding entry to hosts file ⚡ \n"
# https://stackoverflow.com/questions/19339248/append-line-to-etc-hosts-file-with-shell-script
# find existing instances in the host file and save the line numbers
HOST_ENTRY="${JENKINS_ETC_HOSTS_IP} ${JCASC_CONTROLLER_NAME}"
ALREADY_IN_HOST=$(grep "$HOST_ENTRY" $JENKINS_ETC_HOSTS_FILE 1>/dev/null && echo 'found' || echo '')
MATCHES_IN_HOST="$(grep -n ${JCASC_CONTROLLER_NAME} ${JENKINS_ETC_HOSTS_FILE} | cut -f1 -d:)"

if [ -z "$ALREADY_IN_HOST" ]
then
  printf "Please enter your OS local user password if requested ... ✋\n"
  if [ ! -z "$MATCHES_IN_HOST" ]
  then
      # iterate over the line numbers on which matches were found
      while read -r line_number; do
          # replace the text of each line with the desired host entry
          sudo sed -i '' "${line_number}s/.*/${HOST_ENTRY} /" $JENKINS_ETC_HOSTS_FILE
      done <<< "$MATCHES_IN_HOST"
      printf "  Updated existing hosts entry ✅ \n"
  else
      echo "$HOST_ENTRY" | sudo tee -a $JENKINS_ETC_HOSTS_FILE > /dev/null
      printf "  Added new hosts entry ✅ \n"
  fi
fi

#######################################################################################################################
# Run the new jenkins docker image
printf "Running fresh container image ✅ \n"
printf "NOTE: Use the command 'docker exec -ti %s bash' to have connection to the runing container 💡 \n" "${RUNING_IMAGE_NAME}"
sleep 3

docker run --rm \
    --name $RUNING_IMAGE_NAME \
    --env-file=${DOCKER_ENV_VARS} \
    -p "${JCASC_CONTROLLER_JNLP_PORT}:${JCASC_CONTROLLER_JNLP_PORT}" \
    -p "${JCASC_CONTROLLER_PORT}:${JCASC_CONTROLLER_PORT}" \
    -e "JCASC_CONTROLLER_INTERNAL_URL_PROTOCOL=${JCASC_CONTROLLER_INTERNAL_URL_PROTOCOL}" \
    -e "JCASC_CONTROLLER_URL_PROTOCOL=${JCASC_CONTROLLER_URL_PROTOCOL}" \
    -e "JCASC_CONTROLLER_INTERNAL_NAME=${JCASC_CONTROLLER_INTERNAL_NAME}" \
    -e "JCASC_CONTROLLER_NAME=${JCASC_CONTROLLER_NAME}" \
    -e "JCASC_CONTROLLER_INTERNAL_PORT=${JCASC_CONTROLLER_INTERNAL_PORT}" \
    -e "JCASC_CONTROLLER_PORT=${JCASC_CONTROLLER_PORT}" \
    -e "JCASC_CONTROLLER_JNLP_PORT=${JCASC_CONTROLLER_JNLP_PORT}" \
    -e "HEALTHCHECK_ENDPOINT=${HEALTHCHECK_ENDPOINT}" \
    -v "${PWD}/jenkins_keystore.jks:${JENKINS_KEYSTORE}/jenkins_keystore.jks" \
    -v "${SAML_METADATA_FILE}:${JENKINS_REF}/saml-xml-metadata.xml" \
    -v "${SSH_PRIVATE_KEY_FILE}:${JENKINS_REF}/id_rsa" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    $CONTAINER_IMAGE_NAME \
      --httpPort=-1 \
      --httpsPort=$JCASC_CONTROLLER_PORT \
      --httpsKeyStore=${JENKINS_KEYSTORE}/jenkins_keystore.jks \
      --httpsKeyStorePassword=$KEYSTORE_PASSWORD

exit 0
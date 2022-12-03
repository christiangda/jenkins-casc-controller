#!/bin/bash
set -e

printf "Runing entrypoint.sh\n"
echo && echo

# http://www.amp-what.com/unicode/search/
# red cross mark = ❌
# yellow warning sign = ⚠️
# green check mark = ✅
# yellow ligthining = \xe2\x9a\xa0 o ⚡
# finger pointing up = ☝
# exclamation mark = ❗
# hand open = ✋
# left hanf 👈

# Validates necessary env vars for JCasC configuration
# CASC_JENKINS_CONFIG is defined inDockerfile
printf "Validate JCasC Environment Variables ...\n"
CASC_ENV_VARS=$(grep -E -o '\${.+}' -R $CASC_JENKINS_CONFIG | awk -F: '{ print $2}' | sed 's/\${//g'| sed 's/}//g' | sort | uniq)
[[ $? -gt 0 ]] && exit 1

CASC_ENV_VARS_STATE="to validate"
for VAR_NAME in $CASC_ENV_VARS; do
  # "${!VAR_NAME}" here the symbol "!" get the real variable and not the name
  # https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
  if [[ "${!VAR_NAME-notset}" == "notset" ]]; then # also I tried with [[ -v "${!VAR_NAME}" ]] and never work in macos
    printf "  $VAR_NAME ❗, this is not set, please set it\n"
    CASC_ENV_VARS_STATE="fail"
  elif [[ -z "${!VAR_NAME}" ]]; then
    printf "  $VAR_NAME	✋, this is empty, please fill it!\n"
    CASC_ENV_VARS_STATE="fail"
  else
    printf "  $VAR_NAME ✅\n"
  fi
done

[[ "${CASC_ENV_VARS_STATE}" == "fail" ]] && exit 1

printf "\n\n"
printf "Jenkins URLs... ✋\n"
printf "  External: "${JCASC_CONTROLLER_URL_PROTOCOL}://${JCASC_CONTROLLER_NAME}:${JCASC_CONTROLLER_PORT}" 👈\n"
printf "  Internal: "${JCASC_CONTROLLER_INTERNAL_URL_PROTOCOL}://${JCASC_CONTROLLER_INTERNAL_NAME}:${JCASC_CONTROLLER_INTERNAL_PORT}" 👈\n"

sleep 2
printf "\n\n"

printf "Runing jenkins.sh ...\n"
/usr/local/bin/jenkins.sh "$@"
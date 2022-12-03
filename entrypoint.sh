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
  if [[ "$VAR_NAME" =~ ^(file|base64|readFile|decodeBase64|readFileBase64|json)$ ]]; then
    break
  fi

  # "${!VAR_NAME}" here the symbol "!" get the real variable and not the name
  # https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html
  if [[ "${!VAR_NAME-notset}" == "notset" ]]; then # also I tried with [[ -v "${!VAR_NAME}" ]] and never work in macos
    printf "  %s ❗, this is not set, please set it\n" "$VAR_NAME"
    CASC_ENV_VARS_STATE="fail"
  elif [[ -z "${!VAR_NAME}" ]]; then
    printf "  %s	✋, this is empty, please fill it!\n" "$VAR_NAME"
    CASC_ENV_VARS_STATE="fail"
  else
    printf "  %s ✅\n" "$VAR_NAME"
  fi
done

[[ "${CASC_ENV_VARS_STATE}" == "fail" ]] && exit 1

printf "\n\n"
printf "Jenkins URLs... ✋\n"
printf "  External: %s 👈\n" "${JCASC_CONTROLLER_URL_PROTOCOL}://${JCASC_CONTROLLER_NAME}:${JCASC_CONTROLLER_PORT}"
printf "  Internal: %s 👈\n" "${JCASC_CONTROLLER_INTERNAL_URL_PROTOCOL}://${JCASC_CONTROLLER_INTERNAL_NAME}:${JCASC_CONTROLLER_INTERNAL_PORT}"

sleep 2
printf "\n\n"

printf "Runing jenkins.sh ...\n"
/usr/local/bin/jenkins.sh "$@"
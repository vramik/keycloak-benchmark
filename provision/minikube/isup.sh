#!/usr/bin/env bash
# set -x

# when no arguments was given
if [ $# -eq 0 ]
then
  HOST=$(minikube ip).nip.io
else
  HOST=$0
fi


MAXRETRIES=600

declare -A SERVICES=( \
 ["keycloak.${HOST}"]="realms/master/.well-known/openid-configuration" \
 ["grafana.${HOST}"]="" \
 ["prometheus.${HOST}"]="" \
 ["sqlpad.${HOST}"]="" \
 ["jaeger.${HOST}"]="" \
 ["kubebox.${HOST}"]="" \
 ["cryostat.${HOST}"]="" \
 )

for SERVICE in "${!SERVICES[@]}"; do
  RETRIES=$MAXRETRIES
  # loop until we connect successfully or failed
  until kubectl get ingress -A 2>/dev/null | grep ${SERVICE} >/dev/null && curl -k -f -v https://${SERVICE}/${SERVICES[${SERVICE}]} >/dev/null 2>/dev/null
  do
    if [ "${RETRIES}" == "${MAXRETRIES}" ] && [ "${CI}" != "true" ]
    then
      echo -n "Waiting for services to start on ${SERVICE}"
    fi

    RETRIES=$(($RETRIES - 1))
    if [ $RETRIES -eq 0 ]
    then
        echo "Failed to connect"
        exit 1
    fi
    # wait a bit
    if [ "$GITHUB_ACTIONS" == "" ]; then
      echo -n "."
    fi
    sleep 5
  done
  echo https://${SERVICE}/ is up
done

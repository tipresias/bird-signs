#!/bin/bash

set -euo pipefail

DOCKER_COMPOSE_FILE=/var/www/bird_signs/docker-compose.yml
PORT=8080

# We need travis_wait for Travis CI builds, because installing R packages takes forever.
# On a local machine, we can just build & deploy as normal.
if [ -n "$(LC_ALL=C type -t travis_wait)" ] && [ "$(LC_ALL=C type -t travis_wait)" = function ]
then
  travis_wait 30 gcloud builds submit --config cloudbuild.yaml
else
  gcloud builds submit --config cloudbuild.yaml
fi

GOOGLE_ENV_VARS="
GCR_TOKEN=${GCR_TOKEN},\
R_ENV=production,\
SPLASH_SERVICE=${SPLASH_SERVICE}
"

gcloud beta run deploy bird-signs \
  --image gcr.io/${PROJECT_ID}/bird-signs \
  --memory 4Gi \
  --region australia-southeast1 \
  --platform managed \
  --max-instances 5 \
  --update-env-vars ${GOOGLE_ENV_VARS}

if [ $? != 0 ]
then
  exit $?
fi

sudo chmod 600 ~/.ssh/deploy_rsa
sudo chmod 755 ~/.ssh
scp -i ~/.ssh/deploy_rsa docker-compose.prod.yml ${DEPLOY_USER}@${IP_ADDRESS}:${DOCKER_COMPOSE_FILE}

ssh -i ~/.ssh/deploy_rsa ${DEPLOY_USER}@${IP_ADDRESS} "docker pull cfranklin11/tipresias_afl_data:latest \
  && docker-compose -f ${DOCKER_COMPOSE_FILE} up -d"

if [ $? != 0 ]
then
  exit $?
fi

./scripts/wait-for-it.sh ${IP_ADDRESS}:${PORT} \
  -t 60 \
  -- ./scripts/post_deploy.sh

exit $?

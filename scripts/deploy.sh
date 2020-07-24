#!/bin/bash

set -euo pipefail

DOCKER_COMPOSE_FILE=/var/www/bird_signs/docker-compose.yml
PORT=8080

sudo chmod 600 ~/.ssh/deploy_rsa
sudo chmod 755 ~/.ssh
scp -i ~/.ssh/deploy_rsa docker-compose.prod.yml ${DEPLOY_USER}@${IP_ADDRESS}:${DOCKER_COMPOSE_FILE}

ssh -i ~/.ssh/deploy_rsa ${DEPLOY_USER}@${IP_ADDRESS} "docker pull cfranklin11/tipresias_afl_data:latest \
  && docker-compose -f ${DOCKER_COMPOSE_FILE} up -d"

./scripts/wait-for-it.sh ${IP_ADDRESS}:${PORT} \
  -t 60 \
  -- ./scripts/post_deploy.sh

#!/bin/bash

set -euo pipefail

DOCKER_COMPOSE_FILE=/var/www/bird-signs/docker-compose.prod.yml

sudo chmod 600 ~/.ssh/deploy_rsa
sudo chmod 755 ~/.ssh
scp -i ~/.ssh/deploy_rsa docker-compose.prod.yml ${DEPLOY_USER}@${IP_ADDRESS}:${DOCKER_COMPOSE_FILE}

ssh -i ~/.ssh/deploy_rsa ${DEPLOY_USER}@${IP_ADDRESS} "docker pull cfranklin11/tipresias_afl_data:latest \
  && docker-compose -f ${DOCKER_COMPOSE_FILE} up -d --build"

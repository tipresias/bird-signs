#!/bin/bash

set -euo pipefail

DOCKER_COMPOSE_FILE=/var/www/bird_signs/docker-compose.yml
PORT=8080

gcloud builds submit --config cloudbuild.yaml

GOOGLE_ENV_VARS="
GCR_TOKEN=${GCR_TOKEN},\
R_ENV=production,\
"

gcloud beta run deploy bird-signs \
  --image gcr.io/${PROJECT_ID}/bird-signs \
  --memory 4Gi \
  --region australia-southeast1 \
  --platform managed \
  --max-instances 5 \
  --update-env-vars ${GOOGLE_ENV_VARS}

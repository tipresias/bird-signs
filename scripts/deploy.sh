#!/bin/bash

set -euo pipefail

gcloud builds submit --config cloudbuild.yaml ./afl_data
gcloud beta run deploy ${SERVICE_NAME} \
  --image gcr.io/${PROJECT_ID}/afl_data \
  --memory 2Gi \
  --region us-central1 \
  --platform managed \
  --update-env-vars GCR_TOKEN=${GCR_TOKEN},R_ENV=production

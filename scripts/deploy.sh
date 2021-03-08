#!/bin/bash

set -euo pipefail

gcloud builds submit --config cloudbuild.yaml

GOOGLE_ENV_VARS="
GCR_TOKEN=${GCR_TOKEN},\
R_ENV=production,\
"

gcloud run deploy bird-signs \
  --quiet \
  --image gcr.io/${PROJECT_ID}/bird-signs \
  --memory 4Gi \
  --timeout 900 \
  --region australia-southeast1 \
  --max-instances 5 \
  --concurrency 1 \
  --platform managed \
  --update-env-vars ${GOOGLE_ENV_VARS}

#!/bin/bash

set -euo pipefail

# We need travis_wait for Travis CI builds, because installing R packages takes forever.
# On a local machine, we can just build & deploy as normal.
if [ -n "$(LC_ALL=C type -t travis_wait)" ] && [ "$(LC_ALL=C type -t travis_wait)" = function ]
  then
    travis_wait 30 gcloud builds submit --config cloudbuild.yaml ./afl_data
  else
    gcloud builds submit --config cloudbuild.yaml ./afl_data
fi

gcloud beta run deploy ${SERVICE_NAME} \
  --image gcr.io/${PROJECT_ID}/afl_data \
  --memory 2Gi \
  --region us-central1 \
  --platform managed \
  --update-env-vars GCR_TOKEN=${GCR_TOKEN},R_ENV=production

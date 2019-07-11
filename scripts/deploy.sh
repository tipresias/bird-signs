gcloud auth activate-service-account --key-file ${HOME}/.gcloud/keyfile.json

gcloud builds submit --config cloudbuild.yaml ./afl_data
gcloud beta run deploy ${SERVICE_NAME} --image gcr.io/${PROJECT_ID}/afl_data --memory 2Gi
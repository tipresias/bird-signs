# Bird Signs

[![Build Status](https://travis-ci.com/tipresias/bird-signs.svg?branch=master)](https://travis-ci.com/tipresias/bird-signs)

The AFL data API for the Tipresias app and related data-science services

## Running things

### Setup

- To manage environemnt variables:
    - Install [`direnv`](https://direnv.net/)
    - Add `eval "$(direnv hook bash)"` to the bottom of `~/.bashrc`
    - Run `direnv allow .` inside the project directory
- To build and run the app: `docker-compose up --build`

### Run the app

- `docker-compose up`
- Navigate to `localhost:8080`.

### Testing

- `docker-compose run --rm afl_data Rscript -e "devtools::test()"`

### Deploy

  - `gcloud builds submit --config cloudbuild.yaml ./afl_data`
  - `gcloud beta run deploy $SERVICE_NAME --image gcr.io/$PROJECT_ID/afl_data --memory 2Gi`

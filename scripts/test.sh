#!/bin/bash

set -euo pipefail

docker-compose run --rm app Rscript -e "devtools::test()"

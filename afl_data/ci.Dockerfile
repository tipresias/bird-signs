# A Bit awkward, but preferable to the alternative:
# we use a different Dockerfile for CI, because Google Cloud can't deploy
# when we specify the image with '@sha256', but without it, Travis rebuilds
# the image from scratch every time.
FROM rocker/tidyverse:4.0.0@sha256:1ba79a338ff8338a99e523b73136cac31f4a0433f74914f40872f34cbca017ab

RUN apt-get update \
  && apt-get -y --allow-downgrades --fix-broken install \
  # Special version of firefox package for debian stable, which is the base
  # for the tidyverse image
  firefox-esr \
  # The following needed for RSelenium
  default-jre \
  lbzip2

WORKDIR /app/afl_data

COPY init.R ./

ARG LOAD_RSELENIUM="RSelenium::rsDriver(browser = 'firefox', extraCapabilities = list('moz:firefoxOptions' = list(args = list('--headless'))))"

RUN Rscript init.R \
  # We create an RSelenium driver to download the necessary binaries
  # during the build step rather than doing so every time
  # the relevant API endpoint is called, because it slows down API calls
  # way too much.
  && Rscript -e "${LOAD_RSELENIUM}"

COPY . /app/afl_data

EXPOSE 8080

CMD Rscript app.R

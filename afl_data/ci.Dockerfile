# A Bit awkward, but preferable to the alternative:
# we use a different Dockerfile for CI, because Google Cloud can't deploy
# when we specify the image with '@sha256', but without it, Travis rebuilds
# the image from scratch every time.
FROM rocker/tidyverse:4.0.2@sha256:d6a1292df5bece13e3119abe7ae5cd7a8cc7ffd533ae60853968481fff0b2e94

RUN apt-get update \
  && apt-get -y --allow-downgrades --fix-broken install \
  # The following needed for RSelenium
  default-jre \
  lbzip2

WORKDIR /app/afl_data

COPY init.R ./

RUN Rscript init.R

COPY . /app/afl_data

EXPOSE 8080

CMD Rscript app.R

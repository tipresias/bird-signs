# A Bit awkward, but preferable to the alternative:
# we use a different Dockerfile for CI, because Google Cloud can't deploy
# when we specify the image with '@sha256', but without it, Travis rebuilds
# the image from scratch every time.
FROM rocker/tidyverse:4.0.2@sha256:98dee553ee3673e4dbd34f094be8f9e8f82d96942ba6710e4da44f5256d7eefa

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

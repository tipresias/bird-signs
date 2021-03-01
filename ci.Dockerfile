# A Bit awkward, but preferable to the alternative:
# we use a different Dockerfile for CI, because Google Cloud can't deploy
# when we specify the image with '@sha256', but without it, Travis rebuilds
# the image from scratch every time.
FROM rocker/tidyverse:4.0.2@sha256:8de8e9a19cfdbef9ddc551bc1aab838533240fea7908faae2ae6f9458a0dc253

WORKDIR /app

COPY init.R .

RUN Rscript init.R

COPY ./afl_data .

CMD Rscript app.R

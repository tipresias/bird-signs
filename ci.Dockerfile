# A Bit awkward, but preferable to the alternative:
# we use a different Dockerfile for CI, because Google Cloud can't deploy
# when we specify the image with '@sha256', but without it, Travis rebuilds
# the image from scratch every time.
FROM rocker/tidyverse:4.0.2@sha256:1ce8340f3deee657a5c9cb6005762211880a11fc3ead1539ef8aa48d462146bb

WORKDIR /app

COPY init.R .

RUN Rscript init.R

COPY ./afl_data .

CMD Rscript app.R

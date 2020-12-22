# A Bit awkward, but preferable to the alternative:
# we use a different Dockerfile for CI, because Google Cloud can't deploy
# when we specify the image with '@sha256', but without it, Travis rebuilds
# the image from scratch every time.
FROM rocker/tidyverse:4.0.2@sha256:b434972c07ed4b57dd1ac79620c9599580a37fb2dd727a75cdf4900f42c77b47

WORKDIR /app

COPY init.R .

RUN Rscript init.R

COPY ./afl_data .

CMD Rscript app.R

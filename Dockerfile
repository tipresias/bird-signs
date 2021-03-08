FROM rocker/tidyverse:4.0.0-ubuntu18.04

# We need tzdata to avoid the following from readr:
# Warning in OlsonNames() : no Olson database found
# <simpleError: Unknown TZ UTC>
RUN apt-get --no-install-recommends update \
  && apt-get -y --no-install-recommends install tzdata

WORKDIR /app

COPY init.R .

RUN Rscript init.R

COPY ./afl_data .

CMD Rscript app.R

FROM rocker/tidyverse:3.6.1

RUN apt-get update \
  && apt-get -y --allow-downgrades --fix-broken install \
  # Special version of firefox package for debian stable, which is the base
  # for the tidyverse image
  firefox-esr

WORKDIR /app/afl_data

COPY init.R ./
RUN Rscript init.R

COPY . /app/afl_data

EXPOSE 8080

CMD Rscript app.R

FROM rocker/tidyverse:4.0.3

WORKDIR /app

COPY init.R .

RUN Rscript init.R

COPY ./afl_data .

CMD Rscript app.R

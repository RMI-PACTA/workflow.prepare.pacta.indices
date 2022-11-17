FROM rocker/tidyverse

ARG GITHUB_PAT
ENV GITHUB_PAT $GITHUB_PAT

# install system dependencies
ARG SYS_DEPS="\
    git \
    nano \
    "

RUN apt-get update \
    && apt-get install -y --no-install-recommends $SYS_DEPS \
    && chmod -R a+rwX /root \
    && rm -rf /var/lib/apt/lists/*

# install R package dependencies
RUN Rscript -e 'install.packages("remotes")'

# install PACTA R packages
RUN Rscript -e "remotes::install_github(repo = 'RMI-PACTA/pacta.portfolio.analysis')"

# copy imports.R separately from rest of deps to optimize caching
COPY imports.R /workflow.prepare.pacta.indices/imports.R

RUN Rscript -e " \
    source('/workflow.prepare.pacta.indices/imports.R'); \
    install.packages(requirements) \
"

# copy in workflow repo
COPY . /workflow.prepare.pacta.indices

RUN mkdir pacta-data
RUN mkdir bound

WORKDIR /workflow.prepare.pacta.indices

CMD Rscript --vanilla /workflow.prepare.pacta.indices/prepare_pacta_indices.R

# using rocker r-vers as a base with R 4.2.3
# https://hub.docker.com/r/rocker/r-ver
# https://rocker-project.org/images/versioned/r-ver.html
#
# sets CRAN repo to use Posit Package Manager to freeze R package versions to
# those available on 2023-03-31
# https://packagemanager.rstudio.com/client/#/repos/2/overview
# https://packagemanager.rstudio.com/cran/__linux__/jammy/2023-03-31+MbiAEzHt
#
# sets CTAN repo to freeze TeX package dependencies to those available on
# 2021-12-31
# https://www.texlive.info/tlnet-archive/2021/12/31/tlnet/


FROM --platform=linux/amd64 rocker/r-ver:4.2.3
ARG CRAN_REPO="https://packagemanager.rstudio.com/cran/__linux__/jammy/2023-03-31+MbiAEzHt"
RUN echo "options(repos = c(CRAN = '$CRAN_REPO'))" >> "${R_HOME}/etc/Rprofile.site"

ARG GITHUB_PAT
ENV GITHUB_PAT $GITHUB_PAT

# install system dependencies
ARG SYS_DEPS="git"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends $SYS_DEPS \
    && chmod -R a+rwX /root \
    && rm -rf /var/lib/apt/lists/*

# install R package dependencies
RUN Rscript -e "install.packages('pak')"

# install PACTA R packages
RUN Rscript -e "pak::pkg_install(pkg = 'RMI-PACTA/pacta.data.scraping')"
RUN Rscript -e "pak::pkg_install(pkg = 'RMI-PACTA/pacta.portfolio.import')"
RUN Rscript -e "pak::pkg_install(pkg = 'RMI-PACTA/pacta.portfolio.analysis')"
RUN Rscript -e "pak::pkg_install(pkg = 'RMI-PACTA/pacta.portfolio.audit')"
RUN Rscript -e "pak::pkg_install(pkg = 'RMI-PACTA/pacta.portfolio.utils')"

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

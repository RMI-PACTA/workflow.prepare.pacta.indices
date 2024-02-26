# using rocker r-vers as a base with R 4.2.3
# https://hub.docker.com/r/rocker/r-ver
# https://rocker-project.org/images/versioned/r-ver.html
#
# sets CRAN repo to use Posit Package Manager to freeze R package versions to
# those available on 2023-03-31
# https://packagemanager.rstudio.com/client/#/repos/2/overview
# https://packagemanager.rstudio.com/cran/__linux__/jammy/2023-03-31+MbiAEzHt

FROM transitionmonitordockerregistry.azurecr.io/rmi_pacta:2021q4_1.0.0
ARG CRAN_REPO="https://packagemanager.posit.co/cran/__linux__/jammy/2023-10-30"
RUN echo "options(repos = c(CRAN = '$CRAN_REPO'))" >> "${R_HOME}/etc/Rprofile.site"

# Install R dependencies
COPY DESCRIPTION /workflow.prepare.pacta.indices/DESCRIPTION

# install R package dependencies
RUN Rscript -e "\
  install.packages('pak'); \
  deps <- pak::local_install_deps(root = '/workflow.prepare.pacta.indices'); \
  "

# copy in workflow repo
COPY prepare_pacta_indices.R /workflow.prepare.pacta.indices/prepare_pacta_indices.R

WORKDIR /workflow.prepare.pacta.indices

CMD ["Rscript", "--vanilla", "/workflow.prepare.pacta.indices/prepare_pacta_indices.R"]

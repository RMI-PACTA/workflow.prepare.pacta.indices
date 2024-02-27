FROM ghcr.io/rmi-pacta/workflow.transition.monitor:main
# inherit CRAN REPO and R options from base image

# Install R dependencies
COPY DESCRIPTION /workflow.prepare.pacta.indices/DESCRIPTION

# install R package dependencies
RUN Rscript -e "\
  install.packages('pak'); \
  deps <- pak::local_install_deps(root = '/workflow.prepare.pacta.indices'); \
  "

# copy in workflow repo
COPY prepare_pacta_indices.R config.yml /workflow.prepare.pacta.indices/

WORKDIR /workflow.prepare.pacta.indices

CMD ["Rscript", "--vanilla", "/workflow.prepare.pacta.indices/prepare_pacta_indices.R"]

FROM ghcr.io/rmi-pacta/workflow.transition.monitor:main
# inherit CRAN REPO and R options from base image

# Install R dependencies
COPY DESCRIPTION /app/DESCRIPTION

# install R package dependencies
RUN Rscript -e "\
  install.packages('pak'); \
  deps <- pak::local_install_deps(root = '/app'); \
  "

# copy in workflow repo
COPY main.R config.yml /app/

WORKDIR /app

CMD ["Rscript", "--vanilla", "/app/main.R"]

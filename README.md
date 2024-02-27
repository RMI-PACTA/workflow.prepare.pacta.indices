# workflow.prepare.pacta.indices

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) 
<!-- badges: end -->

The goal of `workflow.prepare.pacta.indices` is to run indices through PACTA, 
and format them for the Transition Monitor webtool. 

## Running Prepare PACTA Indices workflow  

### Required input

The index preparation Dockerfile uses the `ghcr.io/rmi-pacta/workflow.transition.monitor` docker image as a base image.
Although the image is public, pulling public images from GHCR requires authentication.

You can authenticate to GHCR with any valid GitHub Personal Access token

``` bash
echo $GITHUB_PAT | docker login ghcr.io -u <USERNAME> --password-stdin
```

### Running in `docker-compose`

0. *Optional, but recommended.* 
    Make a `.env` file.
    This file will preserve the environment variables that control behavior on the host machine, as well as specifying the configuration to use.
    This file can be replaced or overridden by specifying environment variables on the host machine, or as part of invoking docker.
    For more information on specifying environment variables to `docker-compose`, please refer to the [documentation](https://docs.docker.com/compose/environment-variables/envvars-precedence/).
    An example of a `.env` file is:

``` env
PACTA_DATA_PATH=PATH/TO/PACTA/DATA/DIR
OUTPUT_PATH=PATH/TO/OUTPUT/DIR
R_CONFIG_ACTIVE=YYYYQQ
```

The `R_CONFIG_ACTIVE` variable should point to the appropriate set of configuration values specified in the `config.yml` file.

The `PACTA_DATA_PATH` variable should point to an appropriate directory with read access on the host system that contains a version of the PACTA analysis inputs for the desired quarter.

The `OUTPUT_PATH` variable should point to an appropriate directory with read-write access on the host system for saving the output files.

1. Run `docker-compose`

Once these variables have been set, simply run 

``` bash
docker-compose up --build
```

and the prepared indices will automatically populate a timestamped sub-directory in `OUTPUT_PATH`.

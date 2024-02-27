# workflow.prepare.pacta.indices

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) 
<!-- badges: end -->

The goal of `workflow.prepare.pacta.indices` is to run indices through PACTA, 
and format them for the Transition Monitor webtool. 

## Running Prepare PACTA Indices workflow  
### Required input

The index preparation Dockerfile uses the `transitionmonitordockerregistry/rmi_pacta` docker image as a base image. Pulling this image requires access to the Azure docker registry `transitionmonitordockerregistry`. 

You can log-in to this registry by calling:
``` bash
az acr login --name transitionmonitordockerregistry
``` 

### Running in `docker-compose`

0. *Optional, but recommended.* 
    Make a `.env` file.
    This file will preserve the environment variables that control behavior on the host machine, as well as specifying the configuration to use.
    This file can be replaced or overridden by specifying environment variables on the host machine, or as part of invoking docker.
    For more information on specifying environment variables to `docker-compose`, please refer to the [documentation](https://docs.docker.com/compose/environment-variables/envvars-precedence/).
    An example of a `.env` file is:

    ``` env
    PACTA_DATA_PATH=PATH/TO/pacta-data
    R_CONFIG_ACTIVE=YYYYQQ
    ```
    
    Where `R_CONFIG_ACTIVE` is a top-level key from `config.yml`.
    The `PACTA_DATA_PATH` variable should point to an appropriate directory with read access on the host system that contains a version of the PACTA analysis inputs for the desired quarter.

1. Run `docker-compose`

    Once these variables have been set, simply run

    ``` bash
    docker-compose up --build
    ```

    which will run the script with the defined configuration, and populate files into the paths specified.

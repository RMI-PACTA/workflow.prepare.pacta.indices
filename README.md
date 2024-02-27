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

### Running in Docker
The simplest way to run the data preparation process is by using docker. 

First, create a `.env` file in the root directory with the following fields: 

``` env
PACTA_DATA_PATH=PATH/TO/PACTA/DATA/DIR
OUTPUT_PATH=PATH/TO/OUTPUT/DIR
R_CONFIG_ACTIVE=YYYYQQ
```
The `R_CONFIG_ACTIVE` variable should point to the appropriate set of 
configuration values specified in the `config.yml` file. 

The `PACTA_DATA_PATH` variable should point to an appropriate directory with read access on the host system that contains a version of the PACTA analysis inputs for the desired quarter.

The `OUTPUT_PATH` variable should point to an appropriate directory with read-write access on the host system for saving the output files.

Once these variables have been set, simply run 

``` bash
docker-compose up --build
```

and the prepared indices will automatically populate a timestamped sub-directory in `OUTPUT_PATH`.

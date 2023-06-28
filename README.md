# workflow.prepare.pacta.indices

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) 
<!-- badges: end -->

The goal of `workflow.prepare.pacta.indices` is to run indices through PACTA, 
and format them for the Transition Monitor webtool. 

## Running Prepare PACTA Indices workflow  
### Required input

The index preparation Dockerfile uses the 
`transitionmonitordockerregistry/rmi_pacta` docker image as a base image. 

### Running in Docker
The simplest way to run the data preparation process is by using docker. 

First, create a `.env` file in the root directory with the following fields: 

``` env
PACTA_DATA_PATH=PATH/TO/pacta-data/YYYYQQ
R_CONFIG_ACTIVE=YYYYQQ
```
The `R_CONFIG_ACTIVE` variable should point to the appropriate set of 
configuration values specified in the `config.yml` file. 

Once these variables have been set, simply run 

``` bash
docker-compose up --build
```

and the prepared indices will automatically populate in the folder 
`PACTA_DATA_PATH`.

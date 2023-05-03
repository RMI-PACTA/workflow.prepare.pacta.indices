# workflow.prepare.pacta.indices

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) 
<!-- badges: end -->

The goal of `workflow.prepare.pacta.indices` is to run indices through PACTA, 
and format them for the Transition Monitor webtool. 

## Running Prepare PACTA Indices workflow  
### Required input

Preparing indices requires all PACTA input datasets, as prepared by 
`RMI-PACTA/pacta.data.preparation`.

It also requires access to the repo `RMI-PACTA/workflow.transition.monitor`.

### Running in Docker
The simplest way to run the data preparation process is by using docker. 

First, create a `.env` file in the root directory with the following fields: 

``` env
TRANSITION_MONITOR_PATH=PATH/TO/workflow.transition.monitor
PACTA_DATA_PATH=PATH/TO/pacta-data/2021Q4
```

Once these variables have been set, simply run 

``` bash
docker-compose up --build
```

and the prepared indices will automatically populate in the folder 
`PACTA_DATA_PATH`.

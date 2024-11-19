# workflow.prepare.pacta.indices

<!-- badges: start -->
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental) 
<!-- badges: end -->

Welcome to `workflow.prepare.pacta.indices`! This tool is designed to streamline the preparation of indices for use in either [workflow.transition.monitor](https://github.com/RMI-PACTA/workflow.transition.monitor).

## Running prepare PACTA indices workflow  

### Required input

The index preparation `Dockerfile` uses the `ghcr.io/rmi-pacta/workflow.transition.monitor` docker image as a base image. Although the image is public, pulling public images from GHCR requires authentication.

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
    PACTA_DATA_PATH=/PATH/TO/pacta-data/YYYYQQ
    INDICES_PREPARATION_INPUTS_PATH=/PATH/TO/workflow.benchmark.preparation/outputs
    INDICES_PREPARATION_OUTPUTS_PATH=./outputs
    R_CONFIG_ACTIVE=YYYYQQ
    LOG_LEVEL=DEBUG
    ```
    
    Where `R_CONFIG_ACTIVE` is a top-level key from `config.yml`.
    The `PACTA_DATA_PATH` variable should point to an appropriate directory with read access on the host system that contains a version of the PACTA analysis inputs for the desired quarter.
        The `INDICES_PREPARATION_INPUTS_PATH` variable should point to an appropriate directory with read access on the host system where the outputs of `workflow.benchmark.preparation` are stored. Defaults to `./inputs`. See the [workflow.benchmark.preparation](https://github.com/RMI-PACTA/workflow.benchmark.preparation) repository for more information.
    The `INDICES_PREPARATION_OUTPUTS_PATH` variable should point to an appropriate directory with write access on the host system where the outputs of the index preparation will be written. Defaults to `./outputs`.
    `LOG_LEVEL` sets the verbosity of logging messages (using standard `log4j` log levels)

1. Run `docker-compose`

    Once these variables have been set, simply run

    ``` bash
    docker-compose up --build
    ```

    which will run the script with the defined configuration, and populate files into the paths specified.

## Promotion of Datasets to PROD

### `workflow.transiton.monitor`

Data sets to prepare images from [`workflow.transition.monitor`](https://github.com/RMI-PACTA/workflow.transition.monitor/) are stored in the `pactadatadev` Storage Account (`RMI-SP-PACTA-DEV` Resource Group), in the file share `workflow-prepare-pacta-indices-outputs`.
The dataset used is defined by the direcotry name, which is an MD5 hash of the inputs, including the code used in `workflow.transition.monitor` to generate the results.

### `workflow.pacta.webapp` and `workflow.pacta.dashboard`

For the [workflow.pacta.webapp](https://github.com/RMI-PACTA/workflow.pacta.webapp/) and [workflow.pacta.dashboard](https://github.com/RMI-PACTA/workflow.pacta.dashboard/) images, the benchmark data is expected as a bind mount to the docker image (rather than "baked in" in `/pacta-data`, as with `workflow.transition.monitor`).
For Azure Container Instances running on our tenant, the expected file share to mount is `benchmark-data`, in the `rmipactawebappdata` Storage Account (in the `RMI-SP-PACTA-WEU-PAT-DEV` Resource Group).
The top level directories in that File Share correspond to the directories in the `pactadatadev/workflow-prepare-pacta-indices-outputs` file share, and should be passed as environment variables to the docker image (see workflow repos for more detail).

### Transferring from `pactadatadev` to `rmipactawebappdata`

Prepared datasets can be copied from `pactadatadev` to `rmipactawebappdata` with the following commands:

```sh

# Change as needed.
DIRNAME="65c1a416721b22a98c7925999ae03bc4"
TOKEN_START=$(date -u -j '+%Y-%m-%dT%H:%MZ')
TOKEN_EXPIRY=$(date -u -j -v "+20M" '+%Y-%m-%dT%H:%MZ')

DESTINATION_ACCOUNT_NAME="rmipactawebappdata"
DESTINATION_SHARE="benchmark-data"
DESTINATION_SAS="$(
    az storage share generate-sas \
        --account-name $DESTINATION_ACCOUNT_NAME \
        --expiry $TOKEN_EXPIRY \
        --permissions rcw \
        --name $DESTINATION_SHARE \
        --start $TOKEN_START \
        --output tsv
)"

# note permissions are different. rcl allows listing contents, rcw above is to write
SOURCE_ACCOUNT_NAME="pactadatadev"
SOURCE_SHARE="workflow-prepare-pacta-indices-outputs"
SOURCE_SAS="$(
    az storage share generate-sas \
        --account-name $SOURCE_ACCOUNT_NAME \
        --expiry $TOKEN_EXPIRY \
        --permissions rcl \
        --name $SOURCE_SHARE \
        --start $TOKEN_START \
        --output tsv
)"

COPY_SOURCE="https://$SOURCE_ACCOUNT_NAME.file.core.windows.net/$SOURCE_SHARE/$DIRNAME"?$SOURCE_SAS
COPY_DESTINATION="https://$DESTINATION_ACCOUNT_NAME.file.core.windows.net/$DESTINATION_SHARE/$DIRNAME?$DESTINATION_SAS" 
echo "$COPY_SOURCE"
echo "$COPY_DESTINATION"

azcopy copy \
    "$COPY_SOURCE" \
    "$COPY_DESTINATION" \
    --as-subdir=false \
    --recursive


```


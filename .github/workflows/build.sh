#!/bin/bash

# A script for building EPICS container images
#
# Note that this is implemented in bash to make it portable between
# CI frameworks. This approach uses the minimum of GitHub Actions
# and also works locally for testing outside of CI.
#
# PREREQUISITES: the caller should be authenticated to the
# container registry with the appropriate permissions to push
#
# INPUTS:
#   REPOSITORY: the container registry to push to
#   TAG: the tag to use for the container image
#   PUSH: if true, push the container image to the registry
#

# setup a buildx driver
# NOTE: if you have docker aliased to podman this line will fail but the
# rest of the script will run as podman does not need to create a context
docker buildx create --use 2> /dev/null

set -e

# Provide some defaults for the controlling Environment Variables.
PUSH=${PUSH:-false}
TAG=${TAG:-latest}

if [[ -z ${REPOSITORY} ]] ; then
    # For local builds, infer the ghcr registry from git remote
    REPOSITORY=$(git remote -v | sed  "s/.*@github.com:\(.*\)\.git.*/ghcr.io\/\1/" | tail -1)
    echo "inferred registry ${REPOSITORY}"
fi

cachefrom="--cache-from=${REPOSITORY}"
cacheto="--cache-to=${REPOSITORY}"

prep_args() {
    ARCHITECTURE=$1
    TARGET=$2

    image_name=${REPOSITORY}-${ARCHITECTURE}-${TARGET}:${TAG}
    args="
        --build-arg TARGET_ARCHITECTURE=${ARCHITECTURE}
        --target ${TARGET}
        -t ${image_name} .
    "

    if [[ ${PUSH} == "true" ]] ; then
        args="--push "${args}
    fi

    echo "CONTAINER BUILD FOR ${image_name} with ARCHITECTURE=${ARCHITECTURE}..."
}

# EDIT BELOW FOR YOUR BUILD MATRIX REQUIREMENTS
#
# All builds should use cachefrom and the last should use cacheto
# The last build should execute all stages for the cache to be fully useful.
#
# If None of the builds use all stages in the Dockerfile then consider adding
# cache-to to more than one build. But note there is a tradeoff in performance
# as every layer will get uploaded to the cache even if it just came out of the
# cache.

prep_args linux developer
docker buildx build ${cachefrom} ${args}

prep_args linux runtime
docker buildx build ${cachefrom} ${cacheto} ${args}

#!/bin/bash

# A script for building EPICS container images
#
# Note that this is done in bash to make it portable between
# CI frameworks. This approach uses the minimum of GitHub Actions
# features. It is also intended to work locally for testing outside
# of CI.
#
# PREREQUISITES: the caller should be authenticated to the
# container registry for push (when PUSH is true)
#


# setup a buildx driver
# NOTE: if you have docker aliased to podman this line will fail but the
# rest of the script will run as podman does not need to create a context
docker buildx create --use

set -e

# Provide some defaults for the controlling Environment Variables.
# Currently upported ARCHTECTURES are linux rtems
ARCHITECTURES=${ARCHITECTURES:-linux}
PUSH=${PUSH:-false}
TAG=${TAG:-latest}

if [[ -z ${REPOSITORY} ]] ; then
    # For local builds, infer the ghcr registry from git remote
    REPOSITORY=$(git remote -v | sed  "s/.*@github.com:\(.*\)\.git.*/ghcr.io\/\1/" | tail -1)
    echo "inferred registry ${REPOSITORY}"
fi

for ARCHITECTURE in ${ARCHITECTURES}; do
    for TARGET in developer runtime; do

        image_name=${REPOSITORY}-${ARCHITECTURE}-${TARGET}:${TAG}
        args="--build-arg TARGET_ARCHITECTURE=${ARCHITECTURE} --target ${TARGET} -t ${image_name} ."

        echo "BUILDING ${image_name} ..."

        if [[ ${PUSH} == "true" ]] ; then
            args="--push ${image_name} "${args}
        fi

        docker buildx build --cache-from=${REPOSITORY} --cache-to=${REPOSITORY}  ${args}
    done
done



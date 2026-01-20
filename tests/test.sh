#!/bin/bash

set -ex
ROOT_DIR=$(readlink -f $(dirname $0)/..)
pushd ${ROOT_DIR}

IMAGE_NAME=${IMAGE_NAME:-portal}
docker run --rm -v ./:/src -w /src --entrypoint Rscript ${IMAGE_NAME} /src/tests/test_dna.R
docker run --rm -v ./:/src -w /src --entrypoint Rscript ${IMAGE_NAME} /src/tests/test_rna.R
docker run --rm -v ./:/src -w /src --entrypoint Rscript ${IMAGE_NAME} /src/tests/test_protein.R
docker run --rm -v ./:/src -w /src --entrypoint Rscript ${IMAGE_NAME} /src/tests/test_metabolism.R
docker run --rm -v ./:/src -w /src --entrypoint Rscript ${IMAGE_NAME} /src/tests/test_plasmix_protein.R
docker run --rm -v ./:/src -w /src --entrypoint Rscript ${IMAGE_NAME} /src/tests/test_plasmix_metabolism.R
popd

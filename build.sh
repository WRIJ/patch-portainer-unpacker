#!/usr/bin/env bash
# Set bash to fail fast on errors or undefined variables
set -euo pipefail

# Set the script to run in the directory where it is located
cd "$(dirname "$0")"

PORTAINER_TAG=${1:-}

if [ -z "${PORTAINER_TAG}" ]; then
    echo "Usage: $0 <tag>"
    exit 1
fi

# Apply patches to the compose-unpacker
./patch.sh "${PORTAINER_TAG}"

# Determine the go version from the go.mod file
GO_VERSION=$(grep -oP 'go \K([0-9]+\.?)+' "./packages/compose-unpacker/go.mod")
if [ -z "${GO_VERSION}" ]; then
    echo "Could not determine Go version from go.mod"
    exit 1
fi

docker build \
    --build-arg PORTAINER_TAG="${PORTAINER_TAG}" \
    --build-arg GO_VERSION="${GO_VERSION}" \
    -t compose-unpacker:${PORTAINER_TAG} \
    .

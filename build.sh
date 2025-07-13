#!/usr/bin/env bash
# Set bash to fail fast on errors or undefined variables
set -euo pipefail

# Set the script to run in the directory where it is located
cd "$(dirname "$0")"

TAG=${1:-}

if [ -z "$TAG" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

rm -rf compose-unpacker portainer
git clone --depth 1 --branch "${TAG}" git@github.com:portainer/portainer.git
git clone --depth 1 --branch "${TAG}" git@github.com:portainer/compose-unpacker.git

# Determine the go version from the go.mod file
GO_VERSION=$(grep -oP 'go \K([0-9]+\.?)+' compose-unpacker/go.mod)
if [ -z "${GO_VERSION}" ]; then
  echo "Could not determine Go version from go.mod"
  exit 1
fi

# Patch the go.mod file to use the mounted portainer directory
patch -u compose-unpacker/go.mod patches/go.mod.patch

# Patch main.go as a test
patch -u compose-unpacker/main.go patches/main.go.patch

docker build -t compose-unpacker:${TAG} \
  --build-arg TAG="${TAG}" \
  --build-arg GO_VERSION="${GO_VERSION}" \
  .

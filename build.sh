#!/usr/bin/env bash
# Set bash to fail fast on errors or undefined variables
set -euo pipefail

# Set the script to run in the directory where it is located
cd "$(dirname "$0")"

TAG=${1:-}
PACKAGES_DIR="./packages"
PORTAINER_DIR="${PACKAGES_DIR}/portainer"
COMPOSE_UNPACKER_DIR="${PACKAGES_DIR}/compose-unpacker"

if [ -z "$TAG" ]; then
  echo "Usage: $0 <tag>"
  exit 1
fi

rm -rf "${COMPOSE_UNPACKER_DIR}" "${PORTAINER_DIR}"
git clone --depth 1 --branch "${TAG}" git@github.com:portainer/portainer.git "${PORTAINER_DIR}"
git clone --depth 1 --branch "${TAG}" git@github.com:portainer/compose-unpacker.git "${COMPOSE_UNPACKER_DIR}"

# Determine the go version from the go.mod file
GO_VERSION=$(grep -oP 'go \K([0-9]+\.?)+' "${COMPOSE_UNPACKER_DIR}/go.mod")
if [ -z "${GO_VERSION}" ]; then
  echo "Could not determine Go version from go.mod"
  exit 1
fi

# Patch the go.mod file to use the mounted portainer directory
patch -u "${COMPOSE_UNPACKER_DIR}/go.mod" patches/go.mod.patch

# Patch main.go as a test
patch -u "${COMPOSE_UNPACKER_DIR}/main.go" patches/main.go.patch

# Copy webhooks folder
cp -r patches/webhooks/ "${COMPOSE_UNPACKER_DIR}/webhooks/"

# Apply webhooks patch
patch -u "${COMPOSE_UNPACKER_DIR}/commands/compose_deploy.go" patches/compose_deploy.go.patch

docker build -t compose-unpacker:${TAG} \
  --build-arg TAG="${TAG}" \
  --build-arg GO_VERSION="${GO_VERSION}" \
  .

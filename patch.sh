#!/usr/bin/env bash
# Set bash to fail fast on errors or undefined variables
set -euo pipefail

# Set the script to run in the directory where it is located
cd "$(dirname "$0")"

PORTAINER_TAG=${1:-}
PACKAGES_DIR="./packages"
PORTAINER_DIR="${PACKAGES_DIR}/portainer"
COMPOSE_UNPACKER_DIR="${PACKAGES_DIR}/compose-unpacker"

if [ -z "${PORTAINER_TAG}" ]; then
    echo "Usage: $0 <tag>"
    exit 1
fi

rm -rf "${COMPOSE_UNPACKER_DIR}" "${PORTAINER_DIR}"
git clone --depth 1 --branch "${PORTAINER_TAG}" https://github.com/portainer/portainer.git "${PORTAINER_DIR}"
git clone --depth 1 --branch "${PORTAINER_TAG}" https://github.com/portainer/compose-unpacker.git "${COMPOSE_UNPACKER_DIR}"

# Patch the go.mod file to use the mounted portainer directory
patch -u "${COMPOSE_UNPACKER_DIR}/go.mod" patches/go.mod.patch

# Patch main.go as a test
patch -u "${COMPOSE_UNPACKER_DIR}/main.go" patches/main.go.patch

# Copy webhooks folder
cp -r patches/webhooks/ "${COMPOSE_UNPACKER_DIR}/webhooks/"

# Apply webhooks patch
patch -u "${COMPOSE_UNPACKER_DIR}/commands/compose_deploy.go" patches/compose_deploy.go.patch

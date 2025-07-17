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
if grep -q "replace github.com/portainer/portainer" "${COMPOSE_UNPACKER_DIR}/go.mod"; then
    # Replace the existing replace directive
    patch -u "${COMPOSE_UNPACKER_DIR}/go.mod" patches/go.mod.patch
else
    # Insert a new replace directive
    echo "replace github.com/portainer/portainer => /portainer" >> "${COMPOSE_UNPACKER_DIR}/go.mod"
fi

# Patch main.go as a test
patch -u "${COMPOSE_UNPACKER_DIR}/main.go" patches/main.go.patch

# Copy webhooks folder
cp -r patches/webhooks/ "${COMPOSE_UNPACKER_DIR}/webhooks/"

# Apply webhooks patch
if [ -f "${COMPOSE_UNPACKER_DIR}/commands/compose_deploy.go" ]; then
    # Current location
    patch -u "${COMPOSE_UNPACKER_DIR}/commands/compose_deploy.go" patches/compose_deploy.go.patch
else
    # Fallback location
    patch -u "${COMPOSE_UNPACKER_DIR}/deploy.go" patches/compose_deploy.go.patch
fi

#!/usr/bin/env bash
# Set bash to fail fast on errors or undefined variables
set -euo pipefail

# This script is used in GitHub Actions and expects tools like `gh` and `jq` to be available.
# The `gh` CLI should be authenticated, or a valid `GH_TOKEN` should be set in the environment.

# Default output to stdout for local testing
GITHUB_STEP_SUMMARY="${GITHUB_STEP_SUMMARY:-/dev/stdout}"
GITHUB_OUTPUT="${GITHUB_OUTPUT:-/dev/stdout}"

echo "Checking for unpatched releases..."

portainer_releases=($(
    gh release list \
        --repo portainer/portainer \
        --exclude-pre-releases \
        --limit 5 \
        --json tagName \
    | jq -r '.[] .tagName' \
))
echo "**Latest Portainer releases**: ${portainer_releases[*]}" >> "${GITHUB_STEP_SUMMARY}"

patched_releases=($(
    gh release list \
        --exclude-pre-releases \
        --limit 10 \
        --json tagName \
    | jq -r '.[] .tagName' \
))
echo "**Latest Patched releases**: ${patched_releases[*]}" >> "${GITHUB_STEP_SUMMARY}"

declare -A unique_patched_releases
for release in "${patched_releases[@]}"; do
    # Remove '-patched' suffix if it exists
    release=${release%-patched*}
    unique_patched_releases["${release}"]=1
done
echo >> "${GITHUB_STEP_SUMMARY}"

unpatched_releases=()
for release in "${portainer_releases[@]}"; do
    if [[ -z "${unique_patched_releases[${release}]:-}" ]]; then
        unpatched_releases+=("${release}")
    fi
done

if [ ${#unpatched_releases[@]} -eq 0 ]; then
    echo "🏆💯 **No unpatched releases found**." >> "${GITHUB_STEP_SUMMARY}"
    echo "found=false" >> "${GITHUB_OUTPUT}"
    echo "releases=[]" >> "${GITHUB_OUTPUT}"
else
    echo "💡❗ **${#unpatched_releases[@]} unpatched release(s) found**:" >> "${GITHUB_STEP_SUMMARY}"
    echo "${unpatched_releases[*]}" >> "${GITHUB_STEP_SUMMARY}"
    echo "found=true" >> "${GITHUB_OUTPUT}"
    echo "releases=$(printf '%s\n' "${unpatched_releases[@]}" | jq -R . | jq -cs .)" >> "${GITHUB_OUTPUT}"
fi

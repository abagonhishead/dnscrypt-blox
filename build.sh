#!/usr/bin/env bash
#
# Build the multi-architecture image and push it to the registry as a single
# manifest list. All supported platforms are built in one invocation -- buildx
# can only assemble a multi-arch manifest from a single build, not by combining
# separate per-platform builds.
#
# The upstream dnscrypt-proxy version (-v) is passed through as the
# DNSCRYPT_VERSION build arg -- it selects both the klutchell base image tag and
# the version of generate-domains-blocklist.py we fetch. The built image is
# tagged with that version *and* 'latest', both pushed from the one build.
#
# Pushing requires you to be logged in (`docker login`) as a user with write
# access to the target repository.
#
# Requires a buildx builder named 'multiarch' that can emit foreign platforms
# (the docker-container driver) plus QEMU binfmt handlers for the arm targets.
# See build-test.sh for the one-time setup commands.

set -euo pipefail

IMAGE="abagonhishead/dnscrypt-blox"
PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"

# Default matches the ARG DNSCRYPT_VERSION default in the Dockerfile.
VERSION="2.1.16"

usage() {
    cat <<EOF
Usage: ${0##*/} [-v|--version <dnscrypt-version>] [-h|--help]

Build and push ${IMAGE} for all supported platforms.

  -v, --version   Upstream dnscrypt-proxy version to build against (default: ${VERSION}).
                  Passed as the DNSCRYPT_VERSION build arg; also used as an image tag.
  -h, --help      Show this help and exit.

The image is pushed as both ${IMAGE}:<version> and ${IMAGE}:latest.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -v|--version)
            [ "$#" -ge 2 ] || { echo "error: $1 needs a value" >&2; usage >&2; exit 2; }
            VERSION="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

# Build context is the directory this script lives in.
CONTEXT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> Building and pushing ${IMAGE}:${VERSION} + ${IMAGE}:latest for ${PLATFORMS}"

docker buildx build \
    --builder multiarch \
    --platform "${PLATFORMS}" \
    --build-arg "DNSCRYPT_VERSION=${VERSION}" \
    --tag "${IMAGE}:${VERSION}" \
    --tag "${IMAGE}:latest" \
    --push \
    "${CONTEXT}"

echo ">>> Pushed ${IMAGE}:${VERSION} and ${IMAGE}:latest"

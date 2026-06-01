#!/usr/bin/env bash
#
# Build the multi-architecture image and push it to the registry as a single
# manifest list. All supported platforms are built in one invocation -- buildx
# can only assemble a multi-arch manifest from a single build, not by combining
# separate per-platform builds.
#
# Pushing requires you to be logged in (`docker login`) as a user with write
# access to the target repository.
#
# Requires a buildx builder named 'multiarch' that can emit foreign platforms 
# (the docker-container driver) plus QEMU binfmt handlers for the arm targets. 
# See build-test.sh for the one-time setup commands.

set -euo pipefail

IMAGE="abagonhishead/dnscrypt-blox"
TAG="${1:-latest}"

PLATFORMS="linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"

# Build context is the directory this script lives in.
CONTEXT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ">>> Building and pushing ${IMAGE}:${TAG} for ${PLATFORMS}"

docker buildx build \
    --builder multiarch \
    --platform "${PLATFORMS}" \
    --tag "${IMAGE}:${TAG}" \
    --push \
    "${CONTEXT}"

echo ">>> Pushed ${IMAGE}:${TAG}"

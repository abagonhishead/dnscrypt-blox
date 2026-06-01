#!/usr/bin/env bash
#
# Test-build the image for each supported platform, one at a time.
#
# Each platform is built with `--output type=cacheonly`, so nothing is loaded
# into the local Docker daemon or pushed anywhere -- this just confirms the
# Dockerfile builds cleanly on every target architecture.
#
# Requires a buildx builder that can emit foreign platforms (the docker-container
# driver) plus QEMU binfmt handlers for the arm targets. Create one with:
#   docker buildx create --name multiarch --driver docker-container --use
#   docker run --privileged --rm tonistiigi/binfmt --install arm64,arm
# (or install qemu-user-static / binfmt-support from your distro).

set -uo pipefail

usage() {
    cat <<EOF
Usage: ${0##*/} [-n|--no-cache] [-h|--help]

Test-build the image for each supported platform, one at a time.

  -n, --no-cache   Pass --no-cache to docker buildx, forcing a full rebuild
                   (useful for timing the blocklist generation honestly).
  -h, --help       Show this help and exit.
EOF
}

NO_CACHE=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        -n|--no-cache) NO_CACHE=(--no-cache) ;;
        -h|--help)     usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

PLATFORMS=(
    linux/amd64
    linux/arm64
    linux/arm/v7
    linux/arm/v6
)

# Build context is the directory this script lives in.
CONTEXT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

declare -a passed=()
declare -a failed=()

for platform in "${PLATFORMS[@]}"; do
    echo "=============================================================="
    echo ">>> Building ${platform}"
    echo "=============================================================="

    if docker buildx build \
        --builder multiarch \
        "${NO_CACHE[@]}" \
        --platform "${platform}" \
        --output type=cacheonly \
        "${CONTEXT}"; then
        echo ">>> ${platform}: OK"
        passed+=("${platform}")
    else
        echo ">>> ${platform}: FAILED"
        failed+=("${platform}")
    fi
    echo
done

echo "=============================================================="
echo "Summary"
echo "=============================================================="
for platform in "${passed[@]}"; do
    echo "  PASS  ${platform}"
done
for platform in "${failed[@]}"; do
    echo "  FAIL  ${platform}"
done

# Non-zero exit if any platform failed, so CI can pick it up.
if [ "${#failed[@]}" -gt 0 ]; then
    exit 1
fi

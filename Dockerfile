# syntax=docker/dockerfile:1

# Build the blocklist.
# Tag we pull generate-domains-blocklist.py from. Latest as of 2026-06-01.
ARG DNSCRYPT_VERSION=2.1.16

# Source the stock dnscrypt-proxy.toml straight from the base image, so we patch
# the exact config that ships with this dnscrypt-proxy version rather than
# vendoring (and forever re-syncing) our own copy. No --platform pin: this is the
# same image the final stage uses, so the layer is shared and nothing extra is pulled.
FROM klutchell/dnscrypt-proxy:${DNSCRYPT_VERSION} AS dnscrypt-base

# Pin the builder to the build host's native arch ($BUILDPLATFORM): the blocklist
# is a plain text file, identical on every target, so there's no reason to run the
# generator under slow QEMU emulation for arm targets.
FROM --platform=$BUILDPLATFORM python:3.13-slim AS build-tools
ARG DNSCRYPT_VERSION

# Drop the docker-clean hook so apt keeps downloaded debs in the cache mount.
RUN rm -f /etc/apt/apt.conf.d/docker-clean

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get -qq update \
    && apt-get install -qqy --no-install-recommends curl

WORKDIR /build
COPY blocklist/ ./

RUN curl -fLO https://raw.githubusercontent.com/DNSCrypt/dnscrypt-proxy/${DNSCRYPT_VERSION}/utils/generate-domains-blocklist/generate-domains-blocklist.py \
    && mkdir -p /config \
    && python3 generate-domains-blocklist.py \
        --progress \
        --config domains-blocklist.conf \
        --allowlist domains-allowlist.txt \
        --time-restricted '' \
        --output-file /config/blocked-names.txt

# Take the base image's stock config and enable our blocklist/cloaking directives.
COPY patch-config.sh ./
COPY --from=dnscrypt-base /config/dnscrypt-proxy.toml /config/dnscrypt-proxy.toml
RUN sh patch-config.sh /config/dnscrypt-proxy.toml

# Extend the existing dnscrypt-proxy image with our config + generated blocklist.
FROM klutchell/dnscrypt-proxy:${DNSCRYPT_VERSION}
COPY ./config /config
COPY --from=build-tools /config/blocked-names.txt /config/blocked-names.txt
COPY --from=build-tools /config/dnscrypt-proxy.toml /config/dnscrypt-proxy.toml

# Build the blocklist
# The tag we'll get our version of generate-domains-blocklist.py from. Latest as of 01/06/2026
ARG DNSCRYPT_VERSION=2.1.16
FROM python:3.9.18-slim-bullseye AS blocklist-builder
ARG DNSCRYPT_VERSION

RUN apt-get -qq update && apt-get install -qqy curl
RUN mkdir -p /build
COPY blocklist /build/
RUN mkdir -p /config

WORKDIR /build
RUN echo "Building blocklist against files for v${DNSCRYPT_VERSION}"
RUN curl -O https://raw.githubusercontent.com/DNSCrypt/dnscrypt-proxy/${DNSCRYPT_VERSION}/utils/generate-domains-blocklist/generate-domains-blocklist.py
RUN python3 generate-domains-blocklist.py --progress --config domains-blocklist.conf --allowlist domains-allowlist.txt --time-restricted '' --output-file /config/blocked-names.txt

# Extend the existing dnscrypt-proxy container with our config
FROM klutchell/dnscrypt-proxy:${DNSCRYPT_VERSION}
COPY ./config /config

# Copy over our blocklist
COPY --from=blocklist-builder /config /config
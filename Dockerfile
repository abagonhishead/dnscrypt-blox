# Build the blocklist
FROM python:3.9.18-slim-bullseye AS blocklist-builder
# The commit we'll get our version of generate-domains-blocklist.py from. Latest as of 21/10/2023
ARG DNSCRYPT_COMMIT=ed2c8806487f9eb6e5d8ec564002ae630a40b2e3

RUN apt-get update && apt-get install -y curl
RUN mkdir -p /build
COPY blocklist /build/
RUN mkdir -p /config

WORKDIR /build
RUN curl -O https://raw.githubusercontent.com/DNSCrypt/dnscrypt-proxy/${DNSCRYPT_COMMIT}/utils/generate-domains-blocklist/generate-domains-blocklist.py
RUN python3 generate-domains-blocklist.py -c domains-blocklist.conf -a domains-allowlist.txt -r '' -o /config/blocked-names.txt

# Extend the existing dnscrypt-proxy container with our config
FROM klutchell/dnscrypt-proxy:latest
COPY ./config /config

# Copy over our blocklist
COPY --from=blocklist-builder /config /config
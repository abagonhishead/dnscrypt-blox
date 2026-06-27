#!/usr/bin/env sh
#
# Patch a stock dnscrypt-proxy.toml in place to enable the blocklist and
# cloaking rule files this image ships.
#
# dnscrypt-proxy's default config ships these three directives commented out.
# Rather than vendor (and constantly re-sync) a whole config, we take the one
# baked into the base image and just uncomment the lines we care about. Every
# other setting stays at the base image's upstream default on purpose.
#
# Usage: patch-config.sh <path-to-dnscrypt-proxy.toml>

set -eu

config="${1:?usage: patch-config.sh <path-to-dnscrypt-proxy.toml>}"

# Directives to enable. Each ships commented out in the stock config; the file
# they point at is provided by this image (generated or vendored under /config).
KEYS="blocked_names_file blocked_ips_file cloaking_rules allowed_names_file"

for key in $KEYS; do
    active="^[[:space:]]*${key}[[:space:]]*="
    commented="^[[:space:]]*#[[:space:]]*${key}[[:space:]]*="

    if grep -qE "$active" "$config"; then
        # Already enabled (e.g. re-running the patch) -- nothing to do.
        :
    elif grep -qE "$commented" "$config"; then
        # Strip the leading '# ' so dnscrypt-proxy actually reads the directive.
        sed -i -E "s|^[[:space:]]*#[[:space:]]*(${key}[[:space:]]*=)|\1|" "$config"
    else
        # Neither form found: upstream likely renamed or removed the key. Fail
        # loudly rather than silently shipping an image that doesn't block.
        echo "patch-config: '${key}' not found in ${config} (did the upstream config change?)" >&2
        exit 1
    fi

    # Confirm the directive is now active; guards against a botched sed.
    if ! grep -qE "$active" "$config"; then
        echo "patch-config: failed to enable '${key}' in ${config}" >&2
        exit 1
    fi
done

echo "patch-config: enabled ${KEYS}"

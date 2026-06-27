# dnscrypt-blox
## A dnscrypt-proxy docker container with ad-blocking

## Introduction
[dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy/) is a flexible DNS proxy, with support for encrypted DNS protocols. It's super. Go buy them a beer.

[dnscrypt-proxy-docker](https://github.com/klutchell/dnscrypt-proxy-docker) is a multi-architecture docker image of dnscrypt-proxy by Kyle Harding. Go buy him a beer, too!

This is just a small extension of the above container to provide blocklist generation as part of the build process. It uses the `generate-domains-blocklist.py` Python script that comes with dnscrypt-proxy. Don't buy me a beer, because it didn't take me very long to do this -- I just wrote it for my home network and thought some people out there might find it useful.

## Using it

### The default image
You can see the blocklists that the pre-built image uses by [clicking here](blocklist/domains-blocklist.conf). The URLs without a `#` at the start of the line are included in the dnscrypt-proxy configuration.

If you're happy with those lists, you can just pull the image and run it:

```docker
docker run --restart unless-stopped -p 53:5053/tcp -p 53:5053/udp --name dnscrypt-proxy abagonhishead/dnscrypt-blox:latest
```

You can use your own configuration files if you like. Just make sure you always include the following directive in the `dnscrypt-proxy.toml` config file:
```toml
[blocked_names]

## Path to the file of blocking rules (absolute, or relative to the same directory as the config file)

  blocked_names_file = 'blocked-names.txt'
```

The image was intended to run on an arm64 box and a Raspberry Pi 4, so it continues to support the same platforms as dnscrypt-proxy-docker:
- linux/amd64
- linux/arm64
- linux/arm/v7
- linux/arm/v6

### Building it yourself
If you'd rather pick and choose your own lists or customise things a bit more, e.g. maybe you want to include an extra blocklist, then you'll need to build the image yourself:

The Dockerfile uses BuildKit cache mounts, so it needs to be built with BuildKit. Modern Docker enables BuildKit by default, but the examples below use `docker buildx build` to be explicit:

```bash
# Clone the repo
git clone https://github.com/abagonhishead/dnscrypt-blox.git
cd dnscrypt-blox

# ... change what you need to change ...

# Build the image
docker buildx build . --tag my-dnscrypt-proxy:latest

# Run the image
docker run --restart unless-stopped -p 53:5053/tcp -p 53:5053/udp --name dnscrypt-proxy my-dnscrypt-proxy:latest
```

You can pin a different version of the dnscrypt-proxy base image and its bundled blocklist generator via the `DNSCRYPT_VERSION` build arg:

```bash
docker buildx build . --build-arg DNSCRYPT_VERSION=2.1.16 --tag my-dnscrypt-proxy:latest
```

#### `allowed-names.txt` vs. `domains-allowlist.txt`

There are two files that can be used to 'allowlist' certain domains, so that dnscrypt-proxy returns their real-world records even if a blocklist would otherwise block them. They apply at different stages **and use different syntax**, so they are not interchangeable:

- `blocklist/domains-allowlist.txt` -- applied at **build time**, by `generate-domains-blocklist.py --allowlist`. Any matching entry is dropped from the generated `blocked-names.txt`. It uses the generator's *trusted-list* syntax: bare names with **no `=` prefix**, where a name matches itself **and all of its subdomains**. Allowlisting `example.com` here therefore removes `example.com` *and* everything under it. (Globs use the `ads.*` form; a leading `*.` is treated as a literal, not a wildcard.)
- `allowlist/allowed-names.txt` -- applied at **runtime** by dnscrypt-proxy, using its own pattern syntax (`=exact`, `*.subdomain`, etc.).

Use the build-time list to drop whole domains (and their subtrees) before the blocklist is even built. Use the runtime list for the exceptions it can't express -- chiefly, allowing a single name while its apex stays blocked. For example, if `example.com` is blocked then dnscrypt-proxy blocks every subdomain too; removing `foo.example.com` from the build-time list would not help, because the `example.com` apex entry still matches it at runtime. To let `foo.example.com` through while keeping the rest of the zone blocked, add `=foo.example.com` to `allowlist/allowed-names.txt`.

## Further information
Full documentation can be found on the project wiki here: https://github.com/DNSCrypt/dnscrypt-proxy/wiki

For documentation on the dnscrypt-proxy-docker container, including how to use readiness/liveness probes, see Kyle Harding's repo here: https://github.com/klutchell/dnscrypt-proxy-docker

### Gotchas
#### DNSSEC with allowlisted subdomains
If you're running this behind a DNSSEC validating forwarder (e.g. unbound with DNSSEC enabled,) be aware that any domains in `allowlist/allowed-names.txt` that are subdomains of a blocked apex will need a `domain-insecure: "..."` entry (or equivalent) in your configuration file.

One example of this is `packages.smallstep.com`, which has a `CNAME gateway.scarf.sh` record -- running behind a validating forwarder will cause the forwarder to query `DS` records for the apex (`scarf.sh`), but `scarf.sh` is blocked, so the `DS` record is 'forged' by dnscrypt-proxy. This will result in a `SERVFAIL` response from your forwarder.

## Acknowledgements
- The developers of [DNSCrypt](https://github.com/DNSCrypt/) and [dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy), which has been my DNS server of choice for 5 or 6 years now
- Kyle Harding's [dnscrypt-proxy-docker](https://github.com/klutchell/dnscrypt-proxy-docker) container
- The maintainers of ad blocklists everywhere, in particular [Peter Lowe](https://pgl.yoyo.org/adservers/), whose blocklists I have been using for many years.

## Contributing
If you'd like to contribute, feel free to raise a PR. See the section below for a couple of things I'd like to sort out.

## TODO
- Build automation
- It'd be useful if it updated the blocking lists once a day or something. Unfortunately I haven't figured out how to get a cron job to run on a Chainguard image yet, and using a background script or something feels messy. For now it'll just need a weekly rebuild or something.

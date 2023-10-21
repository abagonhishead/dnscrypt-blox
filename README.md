# dnscrypt-blox
## A dnscrypt-proxy docker container with ad-blocking

## Introduction
[dnscrypt-proxy](https://github.com/DNSCrypt/dnscrypt-proxy/) is a flexible DNS proxy, with support for encrypted DNS protocols. It's super. Go buy them a beer.

[dnscrypt-proxy-docker](https://github.com/klutchell/dnscrypt-proxy-docker) is a multi-architecture docker image of dnscrypt-proxy by Kyle Harding. Go buy him a beer, too!

This is just a small extension of the above container to provide blocklist generation as part of the build process. It uses the `generate-domain-blocklists.py` Python script that comes with dnscrypt-proxy. Don't buy me a beer, because it didn't take me very long to do this -- I just wrote it for my home network and thought some people out there might find it useful.

## Using it

### The default image
You can see the blocklists that the pre-built image uses by [clicking here](blocklist/domains-blocklist.conf). The URLs without a `#` at the start of the line are included in the dnscrypt-proxy configuration.

If you're happy with those lists, you can just pull the image for your platform and run it:

```docker
docker pull abagonhishead/dnscrypt-blox:latest
docker run --restart unless-stopped -p 53:5053/tcp -p 53:5053/udp --name dnscrypt-proxy abagonhishead/dnscrypt-blox
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

```bash
# Clone the repo
git clone https://github.com/klutchell/dnscrypt-proxy-docker.git
cd dnscrypt-proxy-docker

# ... change what you need to change ...

# Build the image
docker build . --tag my-dnscrypt-proxy:latest

# Run the image
docker run --restart unless-stopped -p 53:5053/tcp -p 53:5053/udp --name dnscrypt-proxy my-dnscrypt-proxy:latest
```

## Further information
Full documentation can be found on the project wiki here: https://github.com/DNSCrypt/dnscrypt-proxy/wiki

For documentation on the dnscrypt-proxy-docker container, including how to use readiness/liveness probes, see Kyle Harding's repo here: https://github.com/klutchell/dnscrypt-proxy-docker

## TODO
- It'd be useful if it updated the blocking lists once a day or something. Unfortunately I haven't figured out how to get a cron job to run on a Chainguard image yet, and using a background script or something feels messy. For now it'll just need a weekly rebuild or something.

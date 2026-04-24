# OpenCLI Chrome Container

This directory contains a Docker-based Chrome setup built on top of `lscr.io/linuxserver/chrome`.
It is intended for OpenCLI-style browser automation workflows and includes:

- a desktop-accessible Chrome session
- a published Chrome DevTools Protocol port
- optional Chrome proxy settings
- an in-image installation flow for the OpenCLI browser extension

## Files

- [Dockerfile](/home/lzq/Documents/OpenCLI.docker/Dockerfile:1)  
  Builds the custom image and installs Node.js, OpenCLI, and the browser extension.
- [docker-compose.yml](/home/lzq/Documents/OpenCLI.docker/docker-compose.yml:1)  
  Defines the local runtime configuration, published ports, and persistent mounts.
- [labwc-autostart.sh](/home/lzq/Documents/OpenCLI.docker/labwc-autostart.sh:1)  
  Starts Chrome with the flags we need instead of relying on the base image's default wrapper.
- [scripts/install-opencli-extension.sh](/home/lzq/Documents/OpenCLI.docker/scripts/install-opencli-extension.sh:1)  
  Downloads, packs, and registers the extension during image build.
- [.env.example](/home/lzq/Documents/OpenCLI.docker/.env.example:1)  
  Example runtime configuration.
- [.dockerignore](/home/lzq/Documents/OpenCLI.docker/.dockerignore:1)  
  Excludes the runtime `config/` directory from the Docker build context.

## Quick Start

1. Create a local environment file:

```bash
cp .env.example .env
```

2. Build the image:

```bash
docker compose build chrome
```

If you are using rootless Docker, use your user socket explicitly:

```bash
DOCKER_HOST=unix:///run/user/1000/docker.sock docker compose build chrome
```

3. Start the container:

```bash
docker compose up -d --force-recreate
```

## Endpoints

- Selkies HTTP: `http://localhost:3000`
- Selkies HTTPS: `https://localhost:3001`
- Chrome DevTools Protocol: `http://localhost:9222`

The container also uses `8082` internally for the Selkies data websocket, but it is not published by default.

## Common Environment Variables

The most commonly adjusted values are:

```dotenv
CHROME_PASSWORD=CHANGE_ME
CHROME_REMOTE_DEBUGGING_PORT=9222
CHROME_START_PAGE=about:blank
CHROME_EXTRA_FLAGS=
CHROME_PROXY_SERVER=
CHROME_PROXY_BYPASS_LIST=
```

Example HTTP proxy:

```dotenv
CHROME_PROXY_SERVER=http://host.docker.internal:7890
CHROME_PROXY_BYPASS_LIST=<-loopback>;localhost;127.0.0.1
```

Example SOCKS5 proxy:

```dotenv
CHROME_PROXY_SERVER=socks5://host.docker.internal:1080
```

See [.env.example](/home/lzq/Documents/OpenCLI.docker/.env.example:1) for the full list.

## Published Ports

By default, the compose setup publishes:

- `3000` for Selkies HTTP
- `3001` for Selkies HTTPS
- `9222` for Chrome DevTools Protocol

## How Chrome Starts

Chrome is launched through [labwc-autostart.sh](/home/lzq/Documents/OpenCLI.docker/labwc-autostart.sh:1), not the base image's default `wrapped-chrome` flow.

That script is responsible for:

- clearing stale profile lock files
- applying optional proxy arguments
- preserving the Wayland startup flags we need
- passing through the configured `CHROME_CLI` arguments

If Selkies opens to an empty desktop with only a cursor, check:

- `/config/chrome-autostart.log`
- stale `Singleton*` files under `/config/chrome-cdt-profile`

## Extension Installation

During image build, [scripts/install-opencli-extension.sh](/home/lzq/Documents/OpenCLI.docker/scripts/install-opencli-extension.sh:1) performs the extension installation flow:

1. Download the OpenCLI extension zip
2. Unpack it into a temporary directory
3. Copy the unpacked files into the image for inspection
4. Pack the extension into a `.crx` using Chrome's official command-line packaging support
5. Write the Linux external extension manifest into `/usr/share/google-chrome/extensions`

This is intended to avoid depending on the older runtime `--load-extension` approach.

When debugging extension installation, the most useful checkpoints are:

- Docker build logs
- `/opt/opencli-extension`
- `/opt/opencli-extension.crx`
- `/usr/share/google-chrome/extensions/*.json`

## Troubleshooting

### Rootless Docker

If you are using rootless Docker:

- prefer the published host ports over direct container bridge IPs
- use `DOCKER_HOST=unix:///run/user/1000/docker.sock` when needed

### Build Context Permission Errors

If `docker build` fails because files under `config/` are not readable, make sure `.dockerignore` still contains:

```text
config/
```

### Recreating the Container

After changing `.env`, `docker-compose.yml`, or `labwc-autostart.sh`, recreate the container:

```bash
docker compose up -d --force-recreate
```

After changing `Dockerfile` or the extension install script, rebuild first:

```bash
docker compose build chrome
docker compose up -d --force-recreate
```

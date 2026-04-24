ARG BASE_IMAGE=lscr.io/linuxserver/chrome:latest
FROM ${BASE_IMAGE}


ARG OPENCLI_EXTENSION_VERSION=v1.7.0
ARG OPENCLI_EXTENSION_URL=
ARG OPENCLI_EXTENSION_DIR=/opt/opencli-extension
ARG OPENCLI_EXTENSION_CRX=/opt/opencli-extension.crx
ARG OPENCLI_EXTENSION_PREFS_DIR=/usr/share/google-chrome/extensions
ARG OPENCLI_EXTENSION_KEY=/tmp/opencli-extension.pem
ARG NODEJS_VERSION="lts 24"
ARG N_PREFIX=/root/n
ARG OPENCLI_NPM_PACKAGE=@jackwener/opencli

ENV N_PREFIX=${N_PREFIX}
ENV PATH=${N_PREFIX}/bin:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates unzip curl openssl \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js and OpenCLI.
RUN curl -fsSL https://bit.ly/n-install | bash -s -- -y ${NODEJS_VERSION} \
    && node --version \
    && npm --version \
    && npm install -g "${OPENCLI_NPM_PACKAGE}"

COPY scripts/install-opencli-extension.sh /usr/local/bin/install-opencli-extension

RUN chmod +x /usr/local/bin/install-opencli-extension

# Install the browser extension as a Linux external CRX install.
RUN install-opencli-extension

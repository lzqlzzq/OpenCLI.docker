#!/bin/bash

# Bypass wrapped-chrome: its current argument handling conflicts with custom flags.
profile_dir="${CHROME_REMOTE_DEBUGGING_USER_DATA_DIR:-$HOME/.config/google-chrome}"
mkdir -p "${profile_dir}"
rm -f "${profile_dir}"/Singleton*

proxy_args=()
if [[ -n "${CHROME_PROXY_SERVER:-}" ]]; then
  proxy_args+=("--proxy-server=${CHROME_PROXY_SERVER}")
fi
if [[ -n "${CHROME_PROXY_BYPASS_LIST:-}" ]]; then
  proxy_args+=("--proxy-bypass-list=${CHROME_PROXY_BYPASS_LIST}")
fi

/usr/bin/google-chrome \
  --no-first-run \
  --no-sandbox \
  --password-store=basic \
  --simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT' \
  --start-maximized \
  --test-type \
  --enable-features=UseOzonePlatform \
  --ozone-platform=wayland \
  "${proxy_args[@]}" \
  ${CHROME_CLI} >> /config/chrome-autostart.log 2>&1 &

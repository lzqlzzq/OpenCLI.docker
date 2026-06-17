#!/bin/sh

# Bypass wrapped-chrome: its current argument handling conflicts with custom flags.
profile_dir="${CHROME_REMOTE_DEBUGGING_USER_DATA_DIR:-$HOME/.config/google-chrome}"
mkdir -p "${profile_dir}"
rm -f "${profile_dir}"/Singleton*

exec >> /config/chrome-autostart.log 2>&1

proxy_server_arg=""
proxy_bypass_arg=""
if [ -n "${CHROME_PROXY_SERVER:-}" ]; then
  proxy_server_arg="--proxy-server=${CHROME_PROXY_SERVER}"
fi
if [ -n "${CHROME_PROXY_BYPASS_LIST:-}" ]; then
  proxy_bypass_arg="--proxy-bypass-list=${CHROME_PROXY_BYPASS_LIST}"
fi

debug_port="${CHROME_REMOTE_DEBUGGING_PORT:-9222}"
debug_forward_port="${CHROME_DEBUG_FORWARD_PORT:-9223}"
if [ "${debug_forward_port}" != "${debug_port}" ]; then
  if ! ss -ltn 2>/dev/null | grep -q "[.:]${debug_forward_port}[[:space:]]"; then
    socat "TCP-LISTEN:${debug_forward_port},bind=0.0.0.0,reuseaddr,fork" "TCP:127.0.0.1:${debug_port}" &
  fi
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
  ${proxy_server_arg} \
  ${proxy_bypass_arg} \
  ${CHROME_CLI} &

#!/usr/bin/env bash
set -euo pipefail

extension_url="${OPENCLI_EXTENSION_URL:-https://github.com/jackwener/OpenCLI/releases/download/${OPENCLI_EXTENSION_VERSION}/opencli-extension.zip}"
extension_src_dir=/tmp/opencli-extension-src
extension_zip=/tmp/opencli-extension.zip

echo "[extension] download ${extension_url}"
mkdir -p "${extension_src_dir}" "${OPENCLI_EXTENSION_DIR}" "${OPENCLI_EXTENSION_PREFS_DIR}"
curl -fL -o "${extension_zip}" "${extension_url}"
unzip "${extension_zip}" -d "${extension_src_dir}"

echo "[extension] copy unpacked extension to ${OPENCLI_EXTENSION_DIR}"
cp -a "${extension_src_dir}/." "${OPENCLI_EXTENSION_DIR}/"

echo "[extension] generate signing key"
openssl genrsa -out "${OPENCLI_EXTENSION_KEY}" 2048 >/dev/null 2>&1

echo "[extension] pack CRX"
google-chrome --no-sandbox \
  --pack-extension="${extension_src_dir}" \
  --pack-extension-key="${OPENCLI_EXTENSION_KEY}"
mv "${extension_src_dir}.crx" "${OPENCLI_EXTENSION_CRX}"

echo "[extension] write external install manifest"
extension_version="$(sed -n 's/.*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "${OPENCLI_EXTENSION_DIR}/manifest.json" | head -n1)"
extension_id="$(openssl rsa -in "${OPENCLI_EXTENSION_KEY}" -pubout -outform DER 2>/dev/null | openssl dgst -sha256 -binary | head -c 16 | od -An -tx1 -v | tr -d ' \n' | tr '0-9a-f' 'a-p')"
cat > "${OPENCLI_EXTENSION_PREFS_DIR}/${extension_id}.json" <<EOF
{
  "external_crx": "${OPENCLI_EXTENSION_CRX}",
  "external_version": "${extension_version}"
}
EOF
chmod 644 "${OPENCLI_EXTENSION_CRX}" "${OPENCLI_EXTENSION_PREFS_DIR}/${extension_id}.json"

echo "[extension] cleanup"
rm -rf "${extension_zip}" "${extension_src_dir}" "${OPENCLI_EXTENSION_KEY}"

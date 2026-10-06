#!/usr/bin/env bash
# What every release of the default job image must pass, on each
# architecture, before it is published (DESIGN-V79 §5.2). Run inside the
# image: by the pipeline's probe jobs, and by the pull-request checks on the
# image they just built.
set -euo pipefail
. /etc/os-release
echo "[probe] $(uname -m), ${PRETTY_NAME}"

missing=()
for tool in bash git curl wget tar gzip unzip zip xz jq make ssh python3 pip3 node npm npx aws docker sudo; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "[probe] missing: ${missing[*]}" >&2
  exit 1
fi

git --version
jq --version
python3 --version
node --version
echo "npm $(npm --version)"
aws --version
docker --version
docker buildx version
docker compose version

# A script from GitHub Actions runs `sudo apt-get install`.
sudo -n true
# Python's usual way to install a tool without touching the system.
python3 -m venv /tmp/pipemesh-probe-venv
/tmp/pipemesh-probe-venv/bin/pip --version
# The bootstrap downloads and unpacks with these.
curl -fsSI https://pipemesh.io >/dev/null || curl -fsSI https://github.com >/dev/null

echo "[probe] ok"

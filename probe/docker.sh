#!/usr/bin/env bash
# The image's own Docker daemon, which a job with `dockerd: true` gets
# started by the Pipemesh bootstrap: it answers, builds, and runs a
# container of the machine's architecture.
set -euo pipefail
docker info --format '[probe] daemon {{.ServerVersion}} on {{.Architecture}}, storage {{.Driver}}'
printf 'FROM public.ecr.aws/docker/library/alpine:3.22\nRUN uname -m > /arch\n' | docker build -q -t probe-build - >/dev/null
docker run --rm probe-build cat /arch
docker buildx version
echo "[probe] docker ok"

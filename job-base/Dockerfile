# The image a Pipemesh hosted job runs in when it names no image:
# (DESIGN-V79). Ubuntu 24.04, like GitHub's runners, so a script brought
# from Actions keeps its `sudo apt-get install`. What the Pipemesh bootstrap
# needs (bash, git, curl, tar) and what most jobs reach for: jq, Python 3,
# Node LTS, the AWS CLI, and Docker (CLI, daemon, buildx, compose; a job with
# `dockerd: true` gets this image's daemon started for it). Other languages
# come from a job's own image:.
#
# Every base and tool is pinned (the base by digest, the rest by version,
# Node by checksum); Renovate-style bumps are commits here, and each one is
# a release once the probes pass on both architectures.
FROM public.ecr.aws/docker/library/ubuntu:24.04@sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55

ARG TARGETARCH
ARG NODE_VERSION=24.21.0
ARG NODE_SHA256_ARM64=6ad1325edbdb5649c379b75a237147a666c95d4f9ae8d340fef2d1575d289ad2
ARG NODE_SHA256_AMD64=fd8e59d5a511510f6a298afb548f18c7d2b1be404d8b4a27d94fbe49f56cb2d6
ARG AWSCLI_VERSION=2.37.9
ARG DOCKER_VERSION=5:29.8.2-1~ubuntu.24.04~noble

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PIP_ROOT_USER_ACTION=ignore

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
         bash ca-certificates curl git gnupg gzip jq less make openssh-client procps \
         python3 python3-pip python3-venv sudo tar tzdata unzip wget xz-utils zip \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /usr/lib/python3*/EXTERNALLY-MANAGED

# Ubuntu marks its Python externally managed (PEP 668), so `pip install`
# outside a venv fails. A job's container lives for one job, and scripts
# from other CI systems `pip install` tools system-wide, so it is allowed
# (the marker removed above); a venv works as well.

# Docker, from Docker's own repository (Ubuntu's docker.io lags it).
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
         > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         "docker-ce=${DOCKER_VERSION}" "docker-ce-cli=${DOCKER_VERSION}" containerd.io \
         docker-buildx-plugin docker-compose-plugin iptables \
    && rm -rf /var/lib/apt/lists/*

# Node LTS, from nodejs.org, checked against its published checksum.
RUN case "${TARGETARCH}" in \
         arm64) arch=arm64 sum="${NODE_SHA256_ARM64}" ;; \
         amd64) arch=x64 sum="${NODE_SHA256_AMD64}" ;; \
         *) echo "unsupported: ${TARGETARCH}" >&2; exit 1 ;; \
       esac \
    && curl -fsSLo /tmp/node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${arch}.tar.xz" \
    && echo "${sum}  /tmp/node.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 \
         --exclude CHANGELOG.md --exclude LICENSE --exclude README.md \
    && rm /tmp/node.tar.xz

# The AWS CLI v2, AWS's installer at a pinned version.
RUN case "${TARGETARCH}" in arm64) arch=aarch64 ;; amd64) arch=x86_64 ;; esac \
    && curl -fsSLo /tmp/awscli.zip "https://awscli.amazonaws.com/awscli-exe-linux-${arch}-${AWSCLI_VERSION}.zip" \
    && unzip -q /tmp/awscli.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/aws /tmp/awscli.zip

# Built natively per architecture (no emulation), so every tool runs here.
RUN git --version && jq --version && python3 --version && node --version && npm --version \
    && aws --version && docker --version && docker buildx version && docker compose version

LABEL org.opencontainers.image.source="https://github.com/pipemesh/runner-images" \
      org.opencontainers.image.description="The Pipemesh hosted job image (DESIGN-V79)"

WORKDIR /builds
CMD ["/bin/bash"]

# runner-images

The image a [Pipemesh](https://pipemesh.io) hosted job runs in when it
names no `image:`: `job-base`, for Linux arm64 and amd64.

## What it carries

Ubuntu 24.04, like GitHub's runners, so a script brought from Actions
keeps its `sudo apt-get install`, plus:

| | |
| --- | --- |
| Shell and VCS | bash, git, openssh-client |
| Archives and transfer | curl, wget, tar, gzip, xz, zip, unzip |
| Tools | jq, make, sudo |
| Python | Python 3.12, pip (system-wide installs allowed), venv |
| Node | Node 24 LTS, npm |
| Cloud | AWS CLI v2 |
| Docker | Docker Engine 29 (CLI, daemon, buildx, compose) |

A job with `dockerd: true` gets this image's Docker daemon started for it.
Other languages and toolchains come from the job's own `image:`, which
Pipemesh runs as it is.

## How it is released

`pipemesh.yaml` is a Pipemesh pipeline. Every revision of `main`:

1. **build**: builds the image natively on an arm64 and an amd64 runner,
   each with an SBOM and its build provenance, and joins them under one
   tag.
2. **probe**: runs `probe/probe.sh` (the tools are there and run) and
   `probe/docker.sh` (the daemon starts, builds and runs a container) in
   the image, on both architectures.
3. **publish**: tags the probed image `r<revision>` and `latest`. Hosted
   jobs without `image:` run in `latest` from their next pod.

An unchanged image is not built or published again. A pull request builds
and probes both architectures without publishing anything.

Base images and tools are pinned: the base by digest, Node by version and
checksum, Docker and the AWS CLI by version. A bump is a commit here.

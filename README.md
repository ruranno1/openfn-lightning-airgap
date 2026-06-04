# OpenFn Lightning Air-Gapped Deployment Package

This repository contains a Docker Compose based air-gapped deployment package for OpenFn Lightning.

I prepared it for the scenario where a Ministry of Health needs to run OpenFn Lightning on one Ubuntu server without internet access.

The package is designed so that the bundle is built on an internet-connected machine, transferred to the air-gapped server, verified, loaded, and started locally.

## Version

OpenFn Lightning version:

```text
v2.16.6
```

Images included in the generated bundle:

* `openfn/lightning:v2.16.6`
* `openfn/ws-worker:latest`
* `postgres:16-alpine`

## Repository layout

```text
bundle/
  build-bundle.sh
  docker-compose.yml
  env.example
  generate-env.sh
  install.sh
  verify.sh
  check-bundle.sh

RUNBOOK.md
DECISIONS.md
README.md
```

## Build the bundle

Run this on an internet-connected Linux machine:

```bash
cd bundle
./build-bundle.sh
```

Expected output:

```text
bundle/dist/openfn-lightning-airgap-v2.16.6.tar.gz
bundle/dist/openfn-lightning-airgap-v2.16.6.tar.gz.sha256
```

The generated tarball is not committed to Git. It is excluded using `.gitignore` so the repository stays small and readable.

## Test the bundle locally

I tested the bundle locally using the following flow:

```bash
rm -rf /tmp/openfn-airgap-final-test
mkdir -p /tmp/openfn-airgap-final-test

cp bundle/dist/openfn-lightning-airgap-v2.16.6.tar.gz /tmp/openfn-airgap-final-test/
cd /tmp/openfn-airgap-final-test

tar -xzf openfn-lightning-airgap-v2.16.6.tar.gz
cd openfn-lightning-airgap-v2.16.6

./check-bundle.sh
./generate-env.sh
./install.sh
./verify.sh
```

Expected final result:

```text
SUCCESS: Lightning is running and responding at http://localhost:4000
```

A manual HTTP check may return:

```text
HTTP/1.1 302 Found
location: /first_setup
```

This is valid and means Lightning is running.

## Assumptions

* Ubuntu 22.04 LTS
* Docker Engine installed
* Docker Compose v2 available
* No internet access on the target server
* Bundle is transferred using `scp` or USB
* TLS, SMTP, and OIDC are out of scope for this basic task

## Time spent

Approximate elapsed time spent: 3 hours.

This includes reading the task, preparing the bundle scripts, testing the air-gapped install flow locally, troubleshooting startup configuration, and writing the documentation.

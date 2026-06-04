# OpenFn Lightning Air-Gapped Installation Runbook

## Purpose

This runbook explains how to install OpenFn Lightning on an Ubuntu 22.04 server with no internet access.

I designed this runbook for a ministry IT focal point who is comfortable with Linux basics such as SSH, copying files, and editing text files, but may not have deep Docker experience.

The goal is that the installation can be completed without me being present on the call.

## Target server

The target server is assumed to have:

* Ubuntu 22.04 LTS
* Docker Engine already installed
* Docker Compose v2 available using `docker compose`
* 8 GB RAM
* 4 vCPUs
* 50 GB SSD
* No internet access

## Bundle file

The IT focal point should receive this file:

```text
openfn-lightning-airgap-v2.16.6.tar.gz
```

This bundle contains:

* OpenFn Lightning image
* OpenFn worker image
* PostgreSQL image
* Docker Compose file
* environment example file
* helper scripts
* checksum file

## Step 1: Copy the bundle to the server

Copy the bundle to the air-gapped server using `scp` or USB.

Example using `scp`:

```bash
scp openfn-lightning-airgap-v2.16.6.tar.gz user@SERVER_IP:/tmp/
```

Then connect to the server:

```bash
ssh user@SERVER_IP
```

## Step 2: Extract the bundle

Run:

```bash
cd /tmp
tar -xzf openfn-lightning-airgap-v2.16.6.tar.gz
cd openfn-lightning-airgap-v2.16.6
```

## Step 3: Verify the bundle integrity

Before installing, verify that the bundle was not corrupted during transfer.

Run:

```bash
./check-bundle.sh
```

Expected result:

```text
SUCCESS: Bundle integrity check passed.
```

If this check fails, stop the installation and transfer the bundle again.

## Step 4: Generate the environment file

Run:

```bash
./generate-env.sh
```

Expected result:

```text
SUCCESS: .env generated.
```

This script creates a `.env` file from `env.example`.

It generates:

* PostgreSQL password
* Lightning secret key
* primary encryption key
* worker private key
* worker public key
* worker shared secret

The `.env` file contains sensitive values. It must not be shared publicly or committed to Git.

## Step 5: Install and start OpenFn Lightning

Run:

```bash
./install.sh
```

This script will:

* check that Docker is available,
* check that Docker Compose v2 is available,
* load Docker images from the local bundle,
* start PostgreSQL,
* start OpenFn Lightning,
* start the worker.

Expected result:

```text
Install step completed. Run ./verify.sh to confirm Lightning is working.
```

## Step 6: Verify the installation

Run:

```bash
./verify.sh
```

Expected result:

```text
SUCCESS: Lightning is running and responding at http://localhost:4000
```

A manual test can also be done with:

```bash
curl -I http://localhost:4000
```

A valid response may show:

```text
HTTP/1.1 302 Found
location: /first_setup
```

This is a successful result. It means Lightning is running and redirecting to the first setup page.

## Basic service commands

Check service status:

```bash
docker compose ps
```

View Lightning logs:

```bash
docker compose logs --tail=100 lightning
```

View PostgreSQL logs:

```bash
docker compose logs --tail=100 postgres
```

View worker logs:

```bash
docker compose logs --tail=100 ws-worker
```

Stop all services:

```bash
docker compose down
```

Start services again:

```bash
docker compose up -d
```

Restart services:

```bash
docker compose restart
```

## Failure scenario: Lightning container keeps restarting

### Why I selected this scenario

I selected this scenario because it is realistic in this environment. Lightning depends on correctly generated secrets, especially the worker private key. If the key is missing, corrupted, or not in the expected format, the Lightning container will start and then immediately crash.

This is a likely issue for an air-gapped installation because the `.env` file is generated locally on the server.

### Symptom

When running:

```bash
docker compose ps
```

The IT focal point may see:

```text
openfn-lightning   Restarting
```

Lightning will not respond on port 4000.

Running:

```bash
curl -I http://localhost:4000
```

may return:

```text
Connection refused
```

### Diagnosis

Check the Lightning logs:

```bash
docker compose logs --tail=100 lightning
```

The logs may show:

```text
WORKER_RUNS_PRIVATE_KEY could not be parsed as a valid key
```

or:

```text
Could not decode PEM
```

This means the worker private key in `.env` is missing, corrupted, or not correctly formatted.

### Fix

Regenerate the `.env` file.

Run:

```bash
docker compose down
cp .env .env.backup
rm .env
./generate-env.sh
./install.sh
./verify.sh
```

Expected final result:

```text
SUCCESS: Lightning is running and responding at http://localhost:4000
```

### Why this fix works

The `generate-env.sh` script creates a new worker private key and public key, converts them to the expected format, and writes them into `.env`.

This avoids manually editing long key values and reduces the risk of formatting mistakes.

## Other checks

If Lightning still does not start, check the logs again:

```bash
docker compose logs --tail=100 lightning
```

### PostgreSQL SSL error

If the logs show:

```text
Postgrex.Error: ssl not available
```

then Lightning is trying to use SSL to connect to the local PostgreSQL container.

The generated database URL should end with:

```text
?ssl=false
```

Example expected format:

```text
postgresql://lightning:<password>@postgres:5432/lightning?ssl=false
```

### Invalid database URL

If the database password contains special characters such as `/`, the database URL can break.

This bundle avoids that by generating the PostgreSQL password using hexadecimal characters only.

## Success criteria

The installation is successful when:

```bash
./verify.sh
```

returns:

```text
SUCCESS: Lightning is running and responding at http://localhost:4000
```

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

`openfn-lightning-airgap-v2.16.6.tar.gz`

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

`scp openfn-lightning-airgap-v2.16.6.tar.gz user@SERVER_IP:/tmp/`

Then connect to the server:

`ssh user@SERVER_IP`

## Step 2: Extract the bundle

Run:

`cd /tmp`

`tar -xzf openfn-lightning-airgap-v2.16.6.tar.gz`

`cd openfn-lightning-airgap-v2.16.6`

## Step 3: Verify the bundle integrity

Before installing, verify that the bundle was not corrupted during transfer.

Run:

`./check-bundle.sh`

Expected result:

`SUCCESS: Bundle integrity check passed.`

If this check fails, stop the installation and transfer the bundle again.

## Step 4: Generate the environment file

Run:

`./generate-env.sh`

Expected result:

`SUCCESS: .env generated.`

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

`./install.sh`

This script will:

* check that Docker is available
* check that Docker Compose v2 is available
* load Docker images from the local bundle
* start PostgreSQL
* start OpenFn Lightning
* start the worker

Expected result:

`Install step completed. Run ./verify.sh to confirm Lightning is working.`

## Step 6: Verify the installation

Run:

`./verify.sh`

Expected result:

`SUCCESS: Lightning is running and responding at http://localhost:4000`

A manual test can also be done with:

`curl -I http://localhost:4000`

A valid response may show:

`HTTP/1.1 302 Found`

`location: /first_setup`

This is a successful result. It means Lightning is running and redirecting to the first setup page.

## Basic service commands

Check service status:

`docker compose ps`

View Lightning logs:

`docker compose logs --tail=100 lightning`

View PostgreSQL logs:

`docker compose logs --tail=100 postgres`

View worker logs:

`docker compose logs --tail=100 ws-worker`

Stop all services:

`docker compose down`

Start services again:

`docker compose up -d`

Restart services:

`docker compose restart`

## Failure scenario: Lightning container keeps restarting

### Symptom

When running:

`docker compose ps`

The IT focal point may see:

`openfn-lightning   Restarting`

### Diagnosis

Check the Lightning logs:

`docker compose logs --tail=100 lightning`

### Possible cause 1: Invalid worker key

The logs may show:

`WORKER_RUNS_PRIVATE_KEY could not be parsed as a valid key`

or:

`Could not decode PEM`

This means the worker private key in `.env` is missing, corrupted, or not correctly formatted.

### Fix

Regenerate the `.env` file.

Run:

`docker compose down`

`cp .env .env.backup`

`rm .env`

`./generate-env.sh`

`./install.sh`

`./verify.sh`

### Possible cause 2: PostgreSQL SSL error

The logs may show:

`Postgrex.Error: ssl not available`

This means Lightning tried to connect to PostgreSQL using SSL, but the local Docker PostgreSQL container does not provide SSL.

The generated database URL should end with:

`?ssl=false`

Example expected format:

`postgresql://lightning:<password>@postgres:5432/lightning?ssl=false`

### Possible cause 3: Invalid database URL

If the database password contains special characters such as `/`, the database URL can break.

This bundle avoids that by generating the PostgreSQL password using hexadecimal characters only.

## Success criteria

The installation is successful when:

`./verify.sh`

returns:

`SUCCESS: Lightning is running and responding at http://localhost:4000`

# OpenFn Lightning Air-Gapped Deployment Decisions

## Assumptions

For this task, I made the following assumptions:

* The target server is Ubuntu 22.04 LTS.
* Docker Engine is already installed.
* Docker Compose v2 is available using `docker compose`.
* The target server has no internet access.
* A separate internet-connected jump host is available to build the bundle.
* The ministry IT focal point has Linux access and permission to run Docker commands.
* TLS termination is out of scope for this 2–3 hour task.
* SMTP and OIDC are out of scope for this basic package.
* The first deployment is for one standalone server.

## 1. Image handling

I used a simple Docker air-gap approach:

* `docker pull` on the internet-connected machine
* `docker save` to package images into one archive
* `docker load` on the air-gapped server

The bundle script pulls these images:

* `openfn/lightning:v2.16.6`
* `openfn/ws-worker:latest`
* `postgres:16-alpine`

It saves them into:

`images/images.tar`

On the air-gapped server, `install.sh` loads the images using:

`docker load -i images/images.tar`

I chose this approach because it is simple and appropriate for one server. It does not require a private registry, and the ministry IT focal point only needs to follow a small number of commands.

For this task, simplicity is important. A local registry, Harbor, Kubernetes, Terraform, or Ansible would add complexity that is not needed for the given scenario.

For 20 deployments, I would consider an internal registry or registry mirror. I would also pin all images by digest after compatibility testing.

Lightning is pinned to `v2.16.6`. During testing, I found that `openfn/ws-worker:v2.16.6` was not available, so I used `openfn/ws-worker:latest` and captured the exact image inside the bundle using `docker save`. In a production process, I would pin the worker image by digest after testing compatibility with the selected Lightning version.

## 2. Secrets

The repository does not include real secrets.

It includes only:

`env.example`

The real `.env` file is generated on the target server using:

`./generate-env.sh`

The script generates:

* PostgreSQL password
* `SECRET_KEY_BASE`
* `PRIMARY_ENCRYPTION_KEY`
* `WORKER_RUNS_PRIVATE_KEY`
* `WORKER_LIGHTNING_PUBLIC_KEY`
* `WORKER_SECRET`

The worker keys are generated as PEM files, then base64 encoded before being written to `.env`.

The PostgreSQL password is generated using hexadecimal characters. I chose this because passwords containing characters such as `/` can break the `DATABASE_URL` if not encoded correctly.

For this single-server setup, secret rotation would be manual:

1. schedule downtime if required,
2. back up the current `.env`,
3. replace the secret,
4. restart the affected services,
5. run `./verify.sh`.

Some secrets, especially encryption keys, may protect existing data. I would not rotate those casually without checking OpenFn operational guidance and testing first.

For 20 deployments, I would not manage secrets only with local `.env` files. I would use an approved secrets management process, such as HashiCorp Vault, an internal password manager, or another government-approved secrets management tool. Each site should have unique secrets.

## 3. Updates

The air-gapped server should not pull images from the internet.

For an upgrade, I would follow this process:

1. Build a new bundle on the internet-connected machine.
2. Pin the new Lightning version.
3. Save the required images into `images.tar`.
4. Transfer the new bundle to the air-gapped server.
5. Verify the checksum.
6. Back up the database.
7. Load the new images.
8. Start the services.
9. Run `./verify.sh`.

For a patch update, for example `v2.16.3` to `v2.16.4`, the risk is normally lower. I would still read the release notes, back up the database, and keep the previous bundle for rollback.

For a minor update, for example `v2.16` to `v2.17`, the risk is higher. It may include database migrations, configuration changes, or worker compatibility changes. I would test a minor update in staging before production.

Rollback requires:

* the previous bundle,
* the previous Compose file,
* a database backup from before the upgrade.

If a database migration has changed the schema, rolling back the image alone may not be enough.

## 4. Observability

The server has no outbound network, and the ministry does not allow metrics to be shipped off-site.

For the minimum useful monitoring, I included:

* `docker compose ps` for container status,
* `docker compose logs` for local logs,
* `./verify.sh` for HTTP availability,
* PostgreSQL health check,
* Docker log rotation,
* container restart visibility.

The Compose file includes Docker log rotation:

`max-size: 10m`

`max-file: 5`

This reduces the risk of logs filling the 50 GB disk.

A simple local cron job could run `verify.sh` and write the result to a local log file. If the ministry has an internal SMTP server, the same check could send an internal email alert.

For a fuller production setup, I would add local Prometheus and Grafana if allowed, disk usage alerts, database backup monitoring, container restart alerting, and documented upgrade and rollback procedures.

For this 2–3 hour task, I kept the observability approach simple, local, and realistic for a single air-gapped server.

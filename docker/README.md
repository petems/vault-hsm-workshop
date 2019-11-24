# HSM Docker Setup

This is a set of Docker configurations to support local development of features
relating to HSM support.  This library uses softhsm2 and, in some configurations,
pkcs11-proxy to emulate the interaction with a HSM.

## Setup

All containers in this setup use a single base Docker image. This image must be
built before running the other configurations.

```sh
$ cd tools
$ docker-compose build
```

## Basic Configuration

This configuration is a single Vault node that connects to a local softhsm2 
instance.

```sh
$ docker-compose up
```

To rebuild the image with the local code changes.

```sh
$ docker-compose build
$ docker-compose up
```

## Basic Cluster Configuration

This configuration creates a single server three-node cluster setup that connects
to a local softhsm2 instance.

```sh
$ docker-compose -f docker-compose-three-node.yml up
```

To rebuild the image with the local code changes.

```sh
$ docker-compose -f docker-compose-three-node.yml build
$ docker-compose -f docker-compose-three-node.yml up
```

## Advanced Cluster Configuration

This configuration is assist in testing upgrades and where the data store needs
to be maintained between restarts.  This configuration uses Consul as a physical
store, an external HSM using pkcs11-proxy and softhsm2, and creates
two vault servers in a high-available configuration.

```sh
$ docker-compose -f docker-compose-ha.yml up

# Initialize vault
$ vault init -key-shares=1 -key-threshold=1 -stored-shares=1 -recovery-shares=1 -recovery-threshold=1

# Restart standby instance to unseal
$ docker-compose -f docker-compose-ha.yml restart vault2
```

Additionally, this configuration can be used to build images for older versions
of vault to do upgrade testing. To build an old version and generate an image.

```sh
# Set environment var for version and build
$ VERSION=0.8.3 GIT_COMMIT=0b925179fb82adb147b56c1b4407d4e9b288d910 docker-compose -f docker-compose-ha.yml build --no-cache vault
$ docker images hsm_vault
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hsm_vault           latest              9a64101cfa63        About an hour ago   1.3GB
hsm_vault           0.8.3               bb281bdb80a5        16 hours ago        1.28GB

# Launch with version environment variable set
$ VERSION=0.8.3 docker-compose -f docker-compose-ha.yml up
```

To perform upgrade testing.

```sh
# Assuming the 0.8.3 images has already been built.
$ VERSION=0.8.3 docker-compose -f docker-compose-ha.yml up

# Initialize vault
$ vault init -key-shares=1 -key-threshold=1 -stored-shares=1 -recovery-shares=1 -recovery-threshold=1

# Restart standby instance to unseal
$ docker-compose -f docker-compose-ha.yml restart vault2

# Stop and remove current container
$ docker-compose -f docker-compose-ha.yml stop vault2
$ docker-compose -f docker-compose-ha.yml rm -f vault2

# Assuming latest images has been built, replace vault2 container with updated image
$ docker-compose -f docker-compose-ha.yml up --no-recreate vault2

# Do same for remaining servers
```

## Upgrade testing with replication enabled

To perform upgrade testing between version, follow these steps (from hashicorp/vault directory):

1. Ensure that images for the two Vault versions are built (e.g. `hsm_vault:0.8.3` and `hsm_vault:latest`).

```sh
  $ VERSION=0.8.3 GIT_COMMIT=0b925179fb82adb147b56c1b4407d4e9b288d910 docker-compose -f scripts/dev/hsm/replication/docker-compose.yml build --no-cache vault
```

2. Execute `OLD_VERSION=0.8.3 NEW_VERION=latest scripts/testing/upgrade.sh`. Optionally provide `NO_CLEANUP` to preserve state after upgrade

If the upgrade script fails at any point and cleanup is require, you can run the cleanup command manually:

```sh
$ docker-compose -f scripts/dev/hsm/replication/docker-compose.yml down --remove-orphans
```
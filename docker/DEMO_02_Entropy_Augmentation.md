# Entropy augmentation

Pre-requisites:

* Docker
* docker-compose

## Background

We are going to setup SoftHSM and the HSM configuration for Vault.

Since HSM hardware is expensive and tricky to setup we're using SoftHSM for the purposes of a demo: It emulates the behaviour of a hardware HSM, including communication via PKCS 11 and slot assignment.

We'll then show the main usecase for HSM support: Auto-unsealing. This is the process where Vault protects its master key and transits it through the HSM for encryption rather than splitting into key shares.

## Pre-recorded

```
ttyplay DEMO_01_Vagrant_and_Setup.rec
ttyplay DEMO_01_Autounseal.rec
```

## 1 - Build the Docker image

Build the Docker image

```
$ docker-compose build
Building vault
Step 1/13 : FROM debian:9
 ---> bd753a4a335e
Step 2/13 : ARG VAULT_VERSION
 ---> Using cache
 ---> ad00c49af687
Step 3/13 : RUN apt-get update && apt-get install -y libltdl7 libsofthsm2 softhsm2 opensc libcap2-bin
 ---> Using cache
 ---> 1d190d3a0fde
Step 4/13 : RUN apt-get update && apt-get install -y unzip curl
 ---> Using cache
 ---> 6307343f1f02
Step 5/13 : COPY softhsm.conf /etc/softhsm/softhsm2.conf
 ---> Using cache
 ---> bfb4f7e6a9f9
Step 6/13 : RUN mkdir -p /var/lib/softhsm/tokens/
 ---> Using cache
 ---> e9eed4c13548
Step 7/13 : RUN softhsm2-util --init-token --slot 0 --label "vault_hsm" --pin 1234 --so-pin 5678
 ---> Using cache
 ---> 5dd351b616d6
Step 8/13 : RUN curl -o /tmp/vault-ent-hsm.zip https://releases.hashicorp.com/vault/1.3.0+ent.hsm/vault_1.3.0+ent.hsm_linux_amd64.zip
 ---> Using cache
 ---> b286409ec661
Step 9/13 : RUN unzip -o /tmp/vault-ent-hsm.zip -d /tmp
 ---> Using cache
 ---> 39d5f794a12f
Step 10/13 : RUN cp /tmp/vault /usr/local/bin/vault
 ---> Using cache
 ---> 527bd74d82c0
Step 11/13 : RUN chmod u+x /usr/local/bin/vault
 ---> Using cache
 ---> 92597501fc6b
Step 12/13 : EXPOSE 8200
 ---> Using cache
 ---> 4f8761567214
Step 13/13 : CMD ["vault version"]
 ---> Using cache
 ---> 590a16c51644
[Warning] One or more build-args [VAULT_VERSION:1.3.0] were not consumed
Successfully built 590a16c51644
Successfully tagged docker_vault:latest
```

## 2 - Start the docker-compose cluster

```
$ docker-compose up -d
```

## 3 - Export the environment variables

```
$ export VAULT_ADDR="http://127.0.0.1:8200"
$ export VAULT_SKIP_VERIFY=true
$ export VAULT_TOKEN=root
```

## 4 - Enable entropy augmentation on a secrets engine

```
$ vault secrets enable -external-entropy-access transit
$ vault secrets list -detailed
```

## 5 - Create a new encryption key

```
$ vault write -f transit/keys/orders
```

## 6 - Encrypt a value

```
$ vault write transit/encrypt/orders plaintext=$(base64 <<< "4111 1111 1111 1111")
```

## 7 - Decrypt that value

```
$ vault write transit/decrypt/orders ciphertext="vault:v1:AY3ZF2bwGfwZ9dJLSztCLdpPUHkfl/kwaQeRITvKgn74bGYyMI+n34w1CMO8aeg="
```

## 8 - Decode back to base64

```
$ base64 --decode <<< Y3JlZGl0LWNhcmQtbnVtYmVyCg==
```
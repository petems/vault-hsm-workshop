# Entropy augmentation

Pre-requisites:

* Docker
* docker-compose

## Background

Seal-wrapping is the ability to wrap secrets with an extra layer of encryption leveraging the HSM. This adds an extra layer of protection and is useful in some compliance and regulatory environments, including FIPS 140-2 environments.

## Pre-recorded

```
ttyplay DEMO_03_Seal_Wrap.rec
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

## 2 - Start the docker-compose file-based cluster

```
$ docker-compose -f docker-compose-file.yml up -d
```

## 3 - Export the environment variables

```
$ export VAULT_ADDR="http://127.0.0.1:8200"
$ export VAULT_SKIP_VERIFY=true
$ export VAULT_TOKEN=$(vault operator init -recovery-shares=1 -recovery-threshold=1 | grep "Initial Root Token" | sed 's/Initial Root Token: //')
```

## 4 - Enable two KV endpoints: One wrapped, one unwrapped

```
$ vault secrets enable -path=kv-unwrapped kv
$ vault secrets enable -path=kv-seal-wrapped -seal-wrap kv
$ vault secrets list -detailed
```

## 3 - Create new secrets on the two end-points

```
$ vault kv put kv-unwrapped/unwrapped password="my-long-password"
$ vault kv put kv-seal-wrapped/wrapped password="my-long-password"
$ vault kv get kv-unwrapped/unwrapped
$ vault kv get kv-seal-wrapped/wrapped
```

## 4 - Exec onto the docker container and observe the file paths for the secrets

```
$ bash -c "clear && docker exec -it docker_vault_1 bash"
$ cd /vault/file/logical
$ apt install tree
$ tree
.
|-- 3407f07d-7cfc-e9f5-7346-625894316c65
|   `-- _casesensitivity
|-- 79e096e0-d5e9-f154-c5b8-6dc97fa1ff31
|   `-- _unwrapped
`-- 99a2319a-0c98-ef9c-9d4d-fb8f28e426ab
    `-- _wrapped

3 directories, 3 files
```

## 5 - View the secret wrapped

```
$ cat 79e096e0-d5e9-f154-c5b8-6dc97fa1ff31/_unwrapped
{"Value":"AAAAAQIgQzumZHoK9+buC1rSMGL7zVY+Yq+Ycx799IlS1CTrq9HvefFVQH/pR6XsxLc4gcYzUiHJAGq7mLWR6g=="}
cat 99a2319a-0c98-ef9c-9d4d-fb8f28e426ab/_wrapped
{"Value":"ClDHkr/MtUCW96PAS08Xn5YIKz13e18TRA2tkSw0LXxd3tzUcaDZbTNPu9ECWcvL7L5/ax1x0vFsZglWzevWAWc375j5T+TV+MgiIqTJOZvEXxIQq2Ius85J9gZz8SpYsZr5eRogqfL4RyvQFcFJ7n12otYoE/FRUPMUfIn5T6gBIiWc4/QgASoVCIUhENEEGgNrZXkiCGhtYWMta2V5cw=="}
```

You'll notice that even though the length of the original secret is the same, the wrapped secret has additional length as it's seal-wrapped and has been encrypted a second time.
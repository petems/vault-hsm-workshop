# Entropy Augmentatation

Pre-requisites:

* Vagrant
* Virtualbox

## Background

We're going to configure Vault to pull entropy from the HSM rather than use the system entropy. 

While the system entropy used by Vault is more than capable of operating in most threat models, there are some situations where additional entropy from hardware-based random number generators is desirable. For example, NIST SP800-90B is required or when augmented entropy from external sources such as hardware true random number generators (TRNGs) or quantum computing TRNGs are desirable.

We're going to use a Vault setup that already has the HSM configured and installed from the Vagrant provison.

## Pre-recorded

```
ttyplay DEMO_02_Entropy_Augmentation.rec
```

## 1 - Bring up Vagrant with a Vault configured to use SoftHSM

```
$ vagrant up
$ vagrant ssh
```

## 2 - Initialize Vault and setup root token

```
$ export VAULT_ADDR="http://127.0.0.1:8200"
$ export VAULT_SKIP_VERIFY=true
$ systemctl start vault 
$ vault operator init -recovery-shares=1 -recovery-threshold=1 > /root/init.txt 2>&1
$ export VAULT_TOKEN=`cat /root/init.txt | sed -n -e '/^Initial Root Token/ s/.*\: *//p'` 
```

**Note: You would never keep the root token in a file on disk in a real environment, this is for the purposes of the demo!**

## 3 - Enable entropy augmentation on a secrets engine

```
$ vault secrets enable -external-entropy-access transit
$ vault secrets list -detailed
```

## 4 - Create a new encryption key

```
$ vault write -f transit/keys/orders
```

## Encrypt a value

```
$ vault write transit/encrypt/orders plaintext=$(base64 <<< "4111 1111 1111 1111")
```

## Decrypt that value

```
$ vault write transit/decrypt/orders ciphertext="vault:v1:AY3ZF2bwGfwZ9dJLSztCLdpPUHkfl/kwaQeRITvKgn74bGYyMI+n34w1CMO8aeg="
```

## Decode back to base64

```
$ base64 --decode <<< Y3JlZGl0LWNhcmQtbnVtYmVyCg==
```
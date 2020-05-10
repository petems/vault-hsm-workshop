# Seal Wrapping

Pre-requisites:

* Vagrant
* Virtualbox

## Background

Seal-wrapping is the ability to wrap secrets with an extra layer of encryption leveraging the HSM. This adds an extra layer of protection and is useful in some compliance and regulatory environments, including FIPS 140-2 environments.

## Pre-recorded

```
ttyplay DEMO_03_Seal_Wrap.rec
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

## 2 - Enable two KV endpoints: One wrapped, one unwrapped

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

## 4 - Observe the file paths for the secrets

```
$ cd /home/vault/data
$ cd logical
$ tree
tree
.
├── 3933ee17-c247-6d69-92e6-740b43fe26a1
│   └── _wrapped
├── 7eea82d5-57f6-6256-006e-2933e3af00cd
│   └── _unwrapped
├── 9fa29516-9004-7743-a6a0-6434ec9371a1
│   └── _casesensitivity
└── ef1c80ff-605f-ec25-9894-c75c92f3480a
    ├── archive
    │   └── _orders
    └── policy
        └── _orders
```

## 5 - View the secret wrapped

```
$ cd 7eea82d5-57f6-6256-006e-2933e3af00cd
$ cat _unwrapped
$ cd ..
$ cd 3933ee17-c247-6d69-92e6-740b43fe26a1
$ cat _wrapped
```

You'll notice that even though the length of the original secret is the same, the wrapped secret has additional length as it's seal-wrapped and has been encrypted a second time.
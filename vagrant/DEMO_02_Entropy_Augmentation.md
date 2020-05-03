## Entropy Augmentatation

Note: This is all done behind the scenes, so there's not much to see.

## Add the entropy augmentation configuration block

Add the block to the config file: `/etc/vault/config.hcl`

```
# Add the entropy stanza
entropy "seal" {
  mode = "augmentation"
}
```

## Enable entropy augmentation on a secrets engine

```
vault secrets enable -external-entropy-access transit
```

```
vault secrets list -detailed
```

## Create a new encryption key

```
vault write -f transit/keys/orders
```

## Encrypt a value

```
vault write transit/encrypt/orders plaintext=$(base64 <<< "4111 1111 1111 1111")
```

## Decrypt that value

```
vault write transit/decrypt/orders ciphertext="vault:v1:AY3ZF2bwGfwZ9dJLSztCLdpPUHkfl/kwaQeRITvKgn74bGYyMI+n34w1CMO8aeg="
```

## Decode back to base64

```
base64 --decode <<< Y3JlZGl0LWNhcmQtbnVtYmVyCg==
```
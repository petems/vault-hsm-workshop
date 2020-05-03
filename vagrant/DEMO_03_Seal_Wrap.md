## Seal Wrapping



## Add an unwrapped KV secrets engine


```
vault secrets enable -path=kv-unwrapped kv
```

```
vault secrets enable -path=kv-seal-wrapped -seal-wrap kv
```

## Enable entropy augmentation on a secrets engine

```
vault secrets list -detailed
```

```
vault secrets list -detailed
```

```
vault kv put kv-unwrapped/unwrapped password="my-long-password"
```

```
vault kv put kv-seal-wrapped/wrapped password="my-long-password"
```

## View the secret unwrapped

## View the secret wrapped
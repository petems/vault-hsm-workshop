listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}

storage "file" {
  path    = "/vault/file"
}

seal "pkcs11" {

}

log_level = "trace"
ui = true

api_addr = "http://0.0.0.0:8200"
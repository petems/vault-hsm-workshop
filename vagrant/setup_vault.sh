#!/usr/bin/env bash

sudo apt-get update
sudo apt-get install -y unzip libcap2-bin

curl -o /tmp/vault-ent-hsm.zip https://releases.hashicorp.com/vault/1.3.0+ent.hsm/vault_1.3.0+ent.hsm_linux_amd64.zip

unzip -o /tmp/vault-ent-hsm.zip -d /tmp

cp /tmp/vault /usr/local/bin/vault

chmod u+x /usr/local/bin/vault

sudo /usr/sbin/groupadd --force --system vault
if ! getent passwd vault >/dev/null ; then
        sudo /usr/sbin/adduser \
          --system \
          --no-create-home \
          --shell /bin/false \
          vault  >/dev/null
fi

sudo cat << EOF > /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true
EOF

mkdir -p /etc/vault/

# Fetch slot that we created earlier
VAULT_HSM_SLOT=$(softhsm2-util --show-slots | grep "^Slot " | head -1 | cut -d " " -f 2)

sudo cat << EOF > /etc/vault/config.hcl
ui = true

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = "true"
}

storage "file" {
  path = "/home/vault/data"
}

seal "pkcs11" {
  lib            = "/usr/lib/softhsm/libsofthsm2.so"
  slot           = "${VAULT_HSM_SLOT}"
  key_label      = "hsm_demo"
  hmac_key_label = "hmac-key"
  generate_key   = "true"
}
EOF

mkdir -p /etc/systemd/system/vault.service.d/

sudo cat << EOF > /etc/systemd/system/vault.service.d/10-hsm.conf
[Unit]
[Service]
Environment=VAULT_HSM_PIN=1234
EOF


sudo cat << EOF > /etc/systemd/system/vault.service
[Unit]
Description=vault agent
Requires=network-online.target
After=network-online.target
[Service]
Restart=on-failure
User=root
Group=root
PermissionsStartOnly=true
ExecStart=/usr/local/bin/vault server -config /etc/vault/config.hcl
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0644 /etc/systemd/system/vault.service

sudo systemctl --now enable vault
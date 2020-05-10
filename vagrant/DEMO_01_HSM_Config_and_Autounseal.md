# HSM configuration and Autounseal

Pre-requisites:

* Vagrant
* Virtualbox

## Background

We are going to setup SoftHSM and the HSM configuration for Vault.

Since HSM hardware is expensive and tricky to setup we're using SoftHSM for the purposes of a demo: It emulates the behaviour of a hardware HSM, including communication via PKCS 11 and slot assignment.

We'll then show the main usecase for HSM support: Auto-unsealing. This is the process where Vault protects its master key and transits it through the HSM for encryption rather than splitting into key shares.

## Pre-recorded

```
ttyplay DEMO_01_Vagrant_and_Setup.rec
ttyplay DEMO_01_Autounseal.rec
```

## 1 - Bring the VM online

Start the vagrant box without provisioning it:

```
$ vagrant up --no-provision
```

## 2 - Setup SoftHSM to an assigned slot

```
$ sudo apt-get update
$ sudo apt-get install -y libltdl7 libsofthsm2 softhsm2 opensc unzip unzip libcap2-bin
$ sudo mkdir -p /var/lib/softhsm/tokens/
$ sudo tee /etc/softhsm/softhsm2.conf <<EOF
# SoftHSM v2 configuration file
directories.tokendir = /var/lib/softhsm/tokens/
objectstore.backend = file
# ERROR, WARNING, INFO, DEBUG
log.level = DEBUG
EOF
$ sudo softhsm2-util --init-token --slot 0 --label "hsm_demo" --pin 1234 --so-pin asdf
```

## 3 - Install Vault

```
$ sudo apt-get update
$ sudo apt-get install -y unzip libcap2-bin
$ curl -o /tmp/vault-ent-hsm.zip https://releases.hashicorp.com/vault/1.4.0+ent.hsm/vault_1.4.0+ent.hsm_linux_amd64.zip
$ unzip -o /tmp/vault-ent-hsm.zip -d /tmp
$ cp /tmp/vault /usr/local/bin/vault
$ chmod u+x /usr/local/bin/vault
$ sudo /usr/sbin/groupadd --force --system vault
$ if ! getent passwd vault >/dev/null ; then
        sudo /usr/sbin/adduser \
          --system \
          --no-create-home \
          --shell /bin/false \
          vault  >/dev/null
fi
$ sudo cat << EOF > /etc/profile.d/vault.sh
export VAULT_ADDR="http://127.0.0.1:8200"
export VAULT_SKIP_VERIFY=true
EOF
$ mkdir -p /etc/vault/
```

## 4 - Configure Vault to the HSM settings

```
$ VAULT_HSM_SLOT=$(softhsm2-util --show-slots | grep "^Slot " | head -1 | cut -d " " -f 2)
$ sudo cat << EOF > /etc/vault/config.hcl
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
$ mkdir -p /etc/systemd/system/vault.service.d/
$ sudo cat << EOF > /etc/systemd/system/vault.service.d/10-hsm.conf
[Unit]
[Service]
Environment=VAULT_HSM_PIN=1234
EOF
$ sudo cat << EOF > /etc/systemd/system/vault.service
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
$ sudo chmod 0644 /etc/systemd/system/vault.service
$ sudo systemctl --now enable vault
```
 
## 5 - Start Vault and initialize

```
$ export VAULT_ADDR="http://127.0.0.1:8200"
$ export VAULT_SKIP_VERIFY=true
$ systemctl start vault 
$ vault operator init -recovery-shares=1 -recovery-threshold=1 > /root/init.txt 2>&1
$ export VAULT_TOKEN=`cat /root/init.txt | sed -n -e '/^Initial Root Token/ s/.*\: *//p'` 
```

## 6 - Check the logs to see that HSM is being used

```
$ journalctl -u vault.service
```

## 7 - Restart Vault to see auto-unseal in action

```
$ systemctl restart vault
$ journalctl -u vault.service
```

## Automated Script

All of these steps can be done automatically with the `setup_softhsm.sh` and `setup_vault.sh` scripts. These would be run automatically if vagrant was brought up without `--no-provision`, and will be used for the next demos if the VM is destroyed in between setups.
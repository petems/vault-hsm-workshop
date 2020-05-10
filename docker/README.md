# Docker based demos

These demo's will be run using Docker with docker-compose

## Pre-requisites

* Docker
* docker-compose
* Basic command line knowledge

## Demos

Each demo is specified in it's own readme file, such as (./DEMO_01_HSM_Config_and_Autounseal.md)[./DEMO_01_HSM_Config_and_Autounseal.md]

## Pre-recorded Demo

These demos are avaliable as ttyrec recorded sessions. This can be useful if you're in an environment without internet or if a Vagrant setup wont work on a customer network.

To play them back, run the following: 

```
ttyplay DEMO_01_Vagrant_and_Setup.rec
```

You can change the speed of the playback with `-` and `+` keys, and pause with `0` and play again with `1`

## Further Reading

* https://www.vagrantup.com/docs/
* https://www.vaultproject.io/docs/enterprise/hsm/index.html
* https://www.vaultproject.io/docs/enterprise/hsm/configuration.html
* https://www.opendnssec.org/softhsm/
* https://github.com/opendnssec/SoftHSMv2
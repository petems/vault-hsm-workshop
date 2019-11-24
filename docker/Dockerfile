FROM debian:9

ARG VAULT_VERSION="1.3.0"

ENV VAULT_VERSION=${VAULT_VERSION}

RUN apt-get update && apt-get install -y libltdl7 libsofthsm2 softhsm2 opensc libcap2-bin

RUN apt-get update && apt-get install -y unzip curl

COPY softhsm.conf /etc/softhsm/softhsm2.conf

RUN mkdir -p /var/lib/softhsm/tokens/

RUN softhsm2-util --init-token --slot 0 --label "vault_hsm" --pin 1234 --so-pin 5678

RUN curl -o /tmp/vault-ent-hsm.zip https://releases.hashicorp.com/vault/${VAULT_VERSION}+ent.hsm/vault_${VAULT_VERSION}+ent.hsm_linux_amd64.zip

RUN unzip -o /tmp/vault-ent-hsm.zip -d /tmp

RUN cp /tmp/vault /usr/local/bin/vault

RUN chmod u+x /usr/local/bin/vault

EXPOSE 8200

CMD ["vault version"]

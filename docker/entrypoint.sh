#!/bin/bash

set -e -u

export VAULT_HSM_SLOT=$(softhsm2-util --show-slots | grep "^Slot " | head -1 | cut -d " " -f 2)

exec $@

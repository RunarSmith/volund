#!/bin/bash

BootScript=/opt/resources/boot/bin/entrypoint.sh

if [ -f $BootScript ]; then
    bash $BootScript
else
    echo "!!! Boot script $BootScript not found !!!"
    bash -i
fi

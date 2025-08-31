#!/bin/zsh

BootScript=/opt/resources/boot/bin/entrypoint.sh

if [ -f $BootScript ]; then
    zsh $BootScript
else
    echo "!!! Boot script $BootScript not found !!!"
    zsh -i -l
fi

#!/bin/bash

# Do stuff on container creation here

# FIXME: test volumes in /opt/*
# FIXME: search and execute /opt/*/bin/on_container_create.sh


# finally get a user shel

ovpn_file=/opt/openvpn-config.ovpn
if [ -f $ovpn_file ]; then
  openvpn --log-append /var/log/openvpn/vpn.log --config $ovpn_file &
fi

bash -i -l

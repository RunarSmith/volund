#!/bin/bash

local ovpn_file=/opt/openvpn-config.ovpn
if [ -f $ovpn_file ]; then
  openvpn --log-append /var/log/openvpn/vpn.log --config $ovpn_file &
fi

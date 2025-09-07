#!/bin/bash

# Do stuff on container creation here

ovpn_file=/opt/openvpn-config.ovpn
if [ -f $ovpn_file ]; then
  openvpn --log-append /var/log/openvpn/vpn.log --config $ovpn_file &
fi

if [ -d /opt/my-resources/setup/user/ ]; then
  cp -av  /opt/my-resources/res/home_volund/. ~/

  if [ -d /home/volund/.ssh/ ]; then
    # fix access rights
    chmod 700 ~/.ssh
    chmod 400 ~/.ssh/*
    chmod 600 ~/.ssh/known_hosts
  fi

fi

zsh -i -l

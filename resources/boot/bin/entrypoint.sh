#!/bin/bash

# Do stuff on container creation here

ovpn_file=/opt/openvpn-config.ovpn
if [ -f $ovpn_file ]; then
  openvpn --log-append /var/log/openvpn/vpn.log --config $ovpn_file &
fi

if [ -d /opt/my-resources/setup/user/ ]; then
  if [ -d /opt/my-resources/setup/user/.ssh/ ]; then
    # Copy SSH keys to the container
    [ ! -d ~/.ssh ] && mkdir ~/.ssh
    chmod -R 700 ~/.ssh
    cp --force /opt/my-resources/setup/user/.ssh/* ~/.ssh/
    chmod 700 ~/.ssh
    chmod 400 ~/.ssh/*
    chmod 600 ~/.ssh/known_hosts
  fi

  if [ -f /opt/my-resources/setup/user/.gitconfig ]; then
    cat /opt/my-resources/setup/user/.gitconfig | tee -a ~/.gitconfig
  fi
fi

bash -i -l

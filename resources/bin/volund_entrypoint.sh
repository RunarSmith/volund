#!/bin/bash

StartMode=$1

if [ -n "$StartMode" ]; then
  # default start mode = Full
  # We will do complete setup and start
  StartMode="Full"
fi

# Do stuff on container creation here

ovpn_file=/opt/openvpn-config.ovpn
if [[ -f $ovpn_file && "$StartMode" == "Full" ]]; then
  # only start VPN if config file is present, and in full start mode
  openvpn --log-append /var/log/openvpn/vpn.log --config $ovpn_file &
fi

if [ -d /opt/my-resources/res/home_volund/ ]; then
  if [ -d /home/volund/.ssh/ ]; then
    # allow these files to be replaced
    chmod 600 ~/.ssh/*
  fi
  cp -a /opt/my-resources/res/home_volund/. ~/

  if [ -d /home/volund/.ssh/ ]; then
    # fix access rights
    chmod 700 ~/.ssh
    chmod 400 ~/.ssh/*
    chmod 600 ~/.ssh/known_hosts
  fi

fi

if [ -n "$VOLUND_SESSION_RECORD" ]; then
  # session recording
  # record
  # -t <title>
  # -q: quiet
  # -i <seconds> : idle time
  # -c <command to run>
  # <file>
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  /usr/bin/asciinema rec -t "volund - ${TIMESTAMP}" -q -i 2 -c "zsh -i -l" ${VOLUND_SESSION_RECORD_PATH}/volund_session_${TIMESTAMP}.cast
else
  # direct shell
  zsh -i -l
fi

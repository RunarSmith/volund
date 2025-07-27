#!/bin/bash

# grep for 'active_profiles' in Ansible roles main task file :
#     - "'offensivesec' in active_profiles"

grep -r --no-filename active_profiles /opt/resources/ansible/roles/* | \
  cut -d "'" -f2 | \
  sort --unique

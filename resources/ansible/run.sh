#!/bin/bash

playbook="$1"

pipx ensurepath >/dev/null 2>&1 || python3 -m pipx ensurepath
export PATH=$PATH:$HOME/.local/bin:$HOME/.local/pipx/venvs/ansible/bin/:$HOME/.local/share/pipx/venvs/ansible/bin


which ansible-playbook 2>/dev/null || pipx install ansible

pushd /opt/resources/ansible >/dev/null || exit 1

export ANSIBLE_FORCE_COLOR=True
export ACTIVE_ACTIONS=install,config,check,data,hardening
export ANSIBLE_ROLES_PATH="/opt/my-resources/ansible/roles:/opt/resources/ansible/roles"

ansible-playbook -i ./inventory.yaml "$playbook" 

popd >/dev/null || exit 1

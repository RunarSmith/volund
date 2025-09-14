#!/bin/bash

set -e

role=$1

if [ -z "$role" ]; then
  echo "Usage: $0 <role>"
  exit 1
fi

if [ -d "$role" ]; then
  echo "Role '$role' already exist."
  exit 1
fi

if [ -d "roles/$role" ]; then
  echo "Role '$role' already exist in 'roles'."
  exit 1
fi

#if [ ! -d /opt/ansible-venv ]; then
#    python3 -m venv /opt/ansible-venv 
#fi

# source /opt/ansible-venv/bin/activate 

#if [ ! -f /opt/ansible-venv/bin/ansible-galaxy ]; then
#    pip install --no-cache-dir --upgrade pip

#    pip install ansible
#fi

# ---------------------------------------------------------

pipx install ansible
#/home/volund/.local/bin/ansible-galaxy init "$role"
/home/volund/.local/share/pipx/venvs/ansible/bin/ansible-galaxy init "$role"

# ---------------------------------------------------------

unlink $role/defaults/main.yml
cat <<EOF > $role/defaults/main.yaml
---
# default vars for $role

EOF

# ---------------------------------------------------------

unlink $role/handlers/main.yml
cat <<EOF > $role/handlers/main.yaml
---
# handlers file for $role
EOF

# ---------------------------------------------------------

cat <<EOF > $role/tasks/config.yaml
---
# tasks file for $role
EOF

cat <<EOF > $role/tasks/data.yaml
---
# tasks file for $role
EOF

cat <<EOF > $role/tasks/hardening.yaml
---
# tasks file for $role
EOF

cat <<EOF > $role/tasks/install.yaml
---
# tasks file for $role

- name: Install required packages (common for all OS)
  package:
    name: "{{ install_packages | flatten }}"
    state: present
  become: true

- name: install pipx tools
  community.general.pipx:
    name: "{{ item }}"
    state: present
  with_items: "{{ install_pipx_tools | default([]) }}"
  when: install_pipx_tools is defined and install_pipx_tools | length > 0
  become: true
  become_user: "{{ default_username }}"

EOF

unlink $role/tasks/main.yml
cat <<EOF > $role/tasks/main.yaml
---
# tasks file for $role

- name: "Standard Role Main"
  ansible.builtin.include_tasks: "{{ role_path }}/../../custom_steps/role_main_standard.yaml"
EOF

cat <<EOF > $role/tasks/precheck.yaml
---
# tasks file for $role
EOF

cat <<EOF > $role/tasks/test_exec.yaml
---
# tasks file for $role

- name: execute test commands
  include_tasks: "{{ role_path }}/../../custom_steps/test_applications_exec.yaml"
  vars:
    commands_list: "{{ test_commands }}"
    username: "{{ default_username }}"
  when: test_commands is defined and test_commands | length > 0
EOF

# ---------------------------------------------------------

cat <<EOF > $role/tests/test.yml
---
# tests file for $role
EOF

# ---------------------------------------------------------

cat <<EOF > $role/vars/archlinux.yaml
---
# vars file for $role

install_packages: []
EOF

cat <<EOF > $role/vars/debian.yaml
---
# vars file for $role

install_packages: []
EOF

unlink $role/vars/main.yml
cat <<EOF > $role/vars/main.yaml
---
# vars file for $role

# list of commands to execute after install step, to ensure that applications are running properly
test_commands: []

# list of python packages to install with pipx, in user home directory
install_pipx_tools: []
EOF

cat <<EOF > $role/vars/redhat.yaml
---
# vars file for $role

install_packages: []
EOF

# ---------------------------------------------------------

# deactivate

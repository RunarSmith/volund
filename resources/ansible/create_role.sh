#!/bin/bash

set -e

role=$1
profile=$2

if [ -z "$role" ] || [ -z "$profile" ]; then
  echo "Usage: $0 <role> <profile>"
  exit 1
fi


if [ -d "roles/$role" ]; then
  echo "Role '$role' already exist."
  exit 1
fi

if [ ! -d /opt/ansible-venv ]; then
    python3 -m venv /opt/ansible-venv 
fi

source /opt/ansible-venv/bin/activate 

if [ ! -f /opt/ansible-venv/bin/ansible-galaxy ]; then
    pip install --no-cache-dir --upgrade pip

    pip install ansible
fi

# ---------------------------------------------------------

ansible-galaxy init "$role"

# ---------------------------------------------------------

cat <<EOF > $role/defaults/main.yml
---
# default vars for $role
EOF

# ---------------------------------------------------------

cat <<EOF > $role/handlers/main.yml
---
# handlers file for $role
EOF

# ---------------------------------------------------------

cat <<EOF > $role/tasks/config.yaml
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
    name: "{{ install_packages_os_common | flatten }}"
    state: present

- name: Install required packages (OS specific)
  package:
    name: "{{ install_packages | flatten }}"
    state: present
EOF

cat <<EOF > $role/tasks/main.yml
---
# tasks file for $role

- name: "{{ ansible_role_name }} :: check requirements"
  block:
    - name: Include OS-specific variables.
      ansible.builtin.include_vars: "{{ ansible_os_family | lower }}.yaml"

- name: "{{ ansible_role_name }} :: check requirements"
  block:
    - name: Precheck
      ansible.builtin.include_tasks: precheck.yaml
  when:
    - "'$profile' in active_profiles"
    - "'check' in active_actions"

- name: "{{ ansible_role_name }} :: Installation"
  block:
    - name: "Install"
      ansible.builtin.include_tasks: install.yaml
  when:
    - "'$profile' in active_profiles"
    - "'install' in active_actions"

- name: "{{ ansible_role_name }} :: Configuration"
  block:
    - name: "Configuration"
      ansible.builtin.include_tasks: config.yaml
  when:
    - "'$profile' in active_profiles"
    - "'config' in active_actions"

- name: "{{ ansible_role_name }} :: Hardening"
  block:
    - name: "Hardening"
      ansible.builtin.include_tasks: hardening.yaml
  when:
    - "'$profile' in active_profiles"
    - "'hardening' in active_actions"

- name: "{{ ansible_role_name }} :: Installation tests"
  block:
    - name: "Testing"
      ansible.builtin.include_tasks: test_exec.yaml
  when:
    - "'$profile' in active_profiles"
    - "'check' in active_actions"
EOF

cat <<EOF > $role/tasks/precheck.yaml
---
# tasks file for $role
EOF

cat <<EOF > $role/tasks/test_exec.yaml
---
# tasks file for $role
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

install_packages:
EOF

cat <<EOF > $role/vars/debian.yaml
---
# vars file for $role

install_packages:
EOF

cat <<EOF > $role/vars/main.yml
---
# vars file for $role

install_packages_os_common:
EOF

cat <<EOF > $role/vars/redhat.yaml
---
# vars file for $role

install_packages:
EOF

# ---------------------------------------------------------

deactivate

#!/bin/bash

set -e

if [ ! -d /opt/ansible-venv ]; then
    python3 -m venv /opt/ansible-venv 
fi

source /opt/ansible-venv/bin/activate 

if [ ! -f /opt/ansible-venv/bin/yamllint ]; then
    pip install --no-cache-dir --upgrade pip

    pip install ansible ansible-lint yamllint
fi

cd /opt/resources/ansible


yamllint .

# Warning: the project is on a read/only volume, ans ansible-lint cannont create its cache folder:
#
# WARNING  Project directory /opt/resources/ansible/.ansible cannot be used for caching as it is not writable.
# /opt/ansible-venv/lib/python3.13/site-packages/ansible_compat/runtime.py:215: UserWarning: Project directory /opt/resources/ansible/.ansible cannot be used for caching as it is not writable.
#   self.cache_dir = get_cache_dir(self.project_dir, isolated=self.isolated)
#
# Biut that's OK =^.^=
ansible-lint .

deactivate

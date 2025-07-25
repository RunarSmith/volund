#!/bin/bash

set -e


python3 -m venv /opt/ansible-venv 
source /opt/ansible-venv/bin/activate 
pip install --no-cache-dir --upgrade pip

pip install ansible ansible-lint yamllint

cd /opt/resources/ansible

yamllint .

ansible-lint .

deactivate

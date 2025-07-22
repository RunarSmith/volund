#!/bin/bash
set -e

echo "Custom Image build script !!"

if [ "x$IMAGE_NAME" != "x" ]; then
    echo "Image : ${IMAGE_NAME}"

    export IMAGE_ROLE=$(echo ${IMAGE_NAME} | cut -d "-" -f 1)
    export IMAGE_DISTRIBUTION=$(echo ${IMAGE_NAME} | cut -d "-" -f 2)

    echo "role:    $IMAGE_ROLE"
    echo "distrib: $IMAGE_DISTRIBUTION"

    source /opt/ansible-venv/bin/activate 
    
else
    echo "Replaying from a container"
    CONTAINER_NAME=$(cat /etc/hostname)

    export IMAGE_ROLE=$(echo ${CONTAINER_NAME} | cut -d "-" -f 2)
    export IMAGE_DISTRIBUTION=$(echo ${CONTAINER_NAME} | cut -d "-" -f 3)

    echo "role:    $IMAGE_ROLE"
    echo "distrib: $IMAGE_DISTRIBUTION"

    python3 -m venv /opt/ansible-venv

    source /opt/ansible-venv/bin/activate 
    pip install --no-cache-dir --upgrade pip
    pip install ansible
fi


cd /opt/resources/ansible

export ANSIBLE_FORCE_COLOR=True
export ANSIBLE_ROLES_PATH="/opt/my-resources/ansible/roles:/opt/resources/ansible/roles"

ansible-playbook -i ./inventory.yaml /opt/my-resources/ansible/playbook-${IMAGE_ROLE}.yaml || exit 1

deactivate

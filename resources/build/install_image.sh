#!/bin/bash
set -e

export TERM=xterm-256color

buildSourcePath=/opt/resources/build

echo "---------------------------------------------------------"
echo " STATS / INFOS "
echo "---------------------------------------------------------"
echo "User:"
whoami
id
echo "---------------------------------------------------------"
echo "env variables:"
env
echo "---------------------------------------------------------"
echo "cat /etc/*ease"
cat /etc/*ease
echo "---------------------------------------------------------"
echo "df -h"
df -h
echo "---------------------------------------------------------"
echo "ls -l /opt"
ls -l /opt
echo "---------------------------------------------------------"
echo "ls -l /opt/resources"
ls -l /opt/resources
echo "---------------------------------------------------------"
echo "ls -l /opt/my-resources"
ls -l /opt/my-resources
echo "---------------------------------------------------------"

function die() { 
    rc=$?
    msg="${1:-"Unknown error"}"
    echo "❌ $msg (Error code: $rc)"
    exit 1
}

echo "--- OS detection ----------------------------------------"

export OS_FAMILLY_NAME="undefined"

[ -f /etc/os-release ] || die "OS not detected, /etc/os-release file is missing."

. /etc/os-release
OS_FAMILLY_NAME=${ID}

case "${ID}" in
    "blackarch" )   OS_FAMILLY_NAME="arch"      ;;
    "kali")         OS_FAMILLY_NAME="debian"    ;;
    *)              OS_FAMILLY_NAME=${ID}       ;;
esac

echo "Detected OS: ${OS_FAMILLY_NAME} (${VERSION_ID})"

echo "--- Install packages -----------------------------------"

case "${OS_FAMILLY_NAME}" in
    "fedora")
        dnf upgrade --refresh  --assumeyes || die "Failed to update dnf database"
        ;;
    "debian")
        apt update -o "Apt::Cmd::Disable-Script-Warning=1" -qq  || die "Failed to update apt database"
        apt upgrade -o "Apt::Cmd::Disable-Script-Warning=1" -qqy  || die "Failed to update apt packages"
        ;;
    "arch")
        pacman -Syu --noconfirm --quiet --noprogressbar || die "Failed to update pacman database"
        ;;
    *)
        die "Unsupported OS: ${OS_FAMILLY_NAME}"
        ;;
esac

case "${OS_FAMILLY_NAME}" in
    "fedora")
        cp /opt/my-resources/setup/certs/*.pem /etc/pki/ca-trust/source/anchors/ || die "Failed to copy certificates to /etc/pki/ca-trust/source/anchors/"
        update-ca-trust || die "Failed to update CA trust"
        ;;
    "debian")
        cp /opt/my-resources/setup/certs/*.pem /usr/local/share/ca-certificates/ || die "Failed to copy certificates to /usr/local/share/ca-certificates/"
        update-ca-certificates || die "Failed to update CA certificates"
        ;;
    "arch")
        cp /opt/my-resources/setup/certs/*.pem /etc/ca-certificates/trust-source/anchors/ || die "Failed to copy certificates to /etc/ca-certificates/trust-source/anchors/"
        trust extract-compat || die "Failed to extract CA certificates"
        ;;
    *)
        die "Unsupported OS: ${OS_FAMILLY_NAME}"
        ;;
esac

case "${OS_FAMILLY_NAME}" in
    "fedora")
        packagesList="python3 python3-libdnf5"
        dnf install --quiet --assumeyes $packagesList || die "Failed to install packages: $packagesList"
        ;;
    "debian")
        packagesList="python3 python3-pip python3-venv"
        apt install -o "Apt::Cmd::Disable-Script-Warning=1" -qq --yes $packagesList || die "Failed to install packages: $packagesList"
        ;;
    "arch")
        packagesList="python3 python-pip python-virtualenv"
        pacman -S --noconfirm --quiet --noprogressbar $packagesList || die "Failed to install packages: $packagesList"
        ;;
    *)
        die "Unsupported OS: ${OS_FAMILLY_NAME}"
        ;;
esac

# Installer Ansible dans un venv pour éviter les conflits dans un container minimal
python3 -m venv /opt/ansible-venv || die "Failed to create Python virtual environment"
source /opt/ansible-venv/bin/activate 
pip install --no-cache-dir --upgrade pip || die "Failed to upgrade pip"
pip install ansible || die "Failed to install Ansible"

cd /opt/resources/ansible

echo "=== Starting Ansible playbook =============================="
# Lancer le playbook (supposé nommé "site.yml") en local
export ANSIBLE_FORCE_COLOR=True
ansible-playbook -i ./inventory.yaml ./playbook-container-config.yaml || die "Failed to execute Ansible playbook"


[ -f /opt/my-resources/setup/bin/build_image.sh ] && {
    echo "--- Custom build script found, executing it ----------------"
    chmod +x /opt/my-resources/setup/bin/build_image.sh
    bash /opt/my-resources/setup/bin/build_image.sh || die "Failed to execute custom build script"
} || {
    echo "--- No custom build script found, skipping execution -------"
}

# Nettoyage de l'environnement virtuel
deactivate
rm -rf /opt/ansible-venv

#!/bin/bash
set -e

export TERM=xterm-256color

buildSourcePath=/opt/resources/build

function die() { 
    rc=$?
    msg="${1:-"Unknown error"}"
    echo "❌ $msg (Error code: $rc)"
    exit 1
}

function print_header() {
    # Blue color: \033[34m, Reset: \033[0m
    echo -e "\033[34m#==========================================================#\033[0m"
    printf "\033[34m| %-56s |\033[0m\n" "$1"
    echo -e "\033[34m#==========================================================#\033[0m"
}

function print_step() {
    # Green color: \033[32m, Reset: \033[0m
    local text="$1"
    local width=60
    local pad_char="="
    local text_len=${#text}
    local pad_len=$(( (width - text_len - 2) / 2 ))
    local left_pad=$(printf "%*s" $pad_len | tr ' ' "$pad_char")
    local right_pad=$(printf "%*s" $((width - text_len - 2 - pad_len)) | tr ' ' "$pad_char")
    printf "\033[32m%s %s %s\033[0m\n" "$left_pad" "$text" "$right_pad"
}

# =========================================================

print_header "Initialisation"

print_step "STATS / INFOS"
echo "User:"
whoami
id

print_step "env variables"
env

print_step "/etc/*ease"
cat /etc/*ease

print_step "df -h"
df -h

print_step "ls -l /opt"
ls -l /opt

print_step "ls -l /opt/resources"
ls -l /opt/resources

print_step "ls -l /opt/my-resources"
ls -l /opt/my-resources

print_step "OS detection"

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



if [ "x$IMAGE_NAME" != "x" ]; then
    echo "Image : ${IMAGE_NAME}"
else 
    echo "Replaying from a container"
    CONTAINER_NAME=$(cat /etc/hostname)
    export IMAGE_ROLE=$(echo ${CONTAINER_NAME} | cut -d "-" -f 2)
    export IMAGE_DISTRIBUTION=$(echo ${CONTAINER_NAME} | cut -d "-" -f 3)

    echo "role:    $IMAGE_ROLE"
    echo "distrib: $IMAGE_DISTRIBUTION"
fi


# =========================================================

print_header "Environment Setup"

print_step "Install HTTPS certificates"

if compgen -G "/opt/my-resources/setup/certs/*.pem" > /dev/null; then
    echo "Found custom certificates to install."

    case "${OS_FAMILLY_NAME}" in
        "fedora")
            cp /opt/my-resources/setup/certs/*.pem /etc/pki/ca-trust/source/anchors/ || die "Failed to copy certificates to /etc/pki/ca-trust/source/anchors/"
            update-ca-trust || die "Failed to update CA trust"
            ;;
        "debian")
            apt update -qqy
            apt install -qqy --no-install-recommends ca-certificates || die "Failed to install ca-certificates package"

            pushd /opt/my-resources/setup/certs
            for cert in *.pem; do
                if [ -f "$cert" ]; then
                    echo "Installing certificate: $cert"
                    cp "$cert" /usr/local/share/ca-certificates/ || die "Failed to copy certificate $cert to /usr/local/share/ca-certificates/"
                else
                    echo "No certificates found in /opt/my-resources/setup/certs/"
                fi
            done
            popd
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
fi

print_step "Install packages"

case "${OS_FAMILLY_NAME}" in
    "fedora")
        dnf upgrade --refresh  --assumeyes || die "Failed to update dnf database"

        packagesList="python3 python3-libdnf5"
        dnf install --quiet --assumeyes $packagesList || die "Failed to install packages: $packagesList"
        ;;
    "debian")
        apt update -o "Apt::Cmd::Disable-Script-Warning=1" -qq  || die "Failed to update apt database"
        apt upgrade -o "Apt::Cmd::Disable-Script-Warning=1" -qqy  || die "Failed to update apt packages"

        packagesList="python3 python3-pip python3-venv"
        apt install -o "Apt::Cmd::Disable-Script-Warning=1" -qq --yes $packagesList || die "Failed to install packages: $packagesList"
        ;;
    "arch")
        pacman -Syu --noconfirm --quiet --noprogressbar || die "Failed to update pacman database"

        packagesList="python3 python-pip python-virtualenv"
        pacman -S --noconfirm --quiet --noprogressbar $packagesList || die "Failed to install packages: $packagesList"
        ;;
    *)
        die "Unsupported OS: ${OS_FAMILLY_NAME}"
        ;;
esac

print_step "Install Ansible in a virtual env"

python3 -m venv /opt/ansible-venv || die "Failed to create Python virtual environment"
source /opt/ansible-venv/bin/activate 
pip install --no-cache-dir --upgrade pip || die "Failed to upgrade pip"
pip install ansible || die "Failed to install Ansible"

cd /opt/resources/ansible

# =========================================================

print_header "Ansible Playbook Execution : Container Configuration"

echo "Image : ${IMAGE_NAME}"

export IMAGE_ROLE=$(echo ${IMAGE_NAME} | cut -d "-" -f 1)
export IMAGE_DISTRIBUTION=$(echo ${IMAGE_NAME} | cut -d "-" -f 2)

echo "role:    $IMAGE_ROLE"
echo "distrib: $IMAGE_DISTRIBUTION"

export ANSIBLE_FORCE_COLOR=True
export ACTIVE_PROFILES=${IMAGE_ROLE}
export ACTIVE_ACTIONS=install,config,check,hardening
ansible-playbook -i ./inventory.yaml ./playbook.yaml || die "Failed to execute Ansible playbook"

# =========================================================

print_header "Execute Custom Build Script (my-resources)"

[ -f /opt/my-resources/setup/bin/build_image.sh ] && {
    echo "--- Custom build script found, executing it ----------------"
    chmod +x /opt/my-resources/setup/bin/build_image.sh
    bash /opt/my-resources/setup/bin/build_image.sh || die "Failed to execute custom build script"
} || {
    echo "--- No custom build script found, skipping execution -------"
}

# =========================================================

print_header "Cleaning"

deactivate
rm -rf /opt/ansible-venv

# =========================================================

print_header "Done"

#!/bin/bash

# BASH_SOURCE[0] donne le chemin du fichier actuellement sourcé.
SOURCE="${BASH_SOURCE[0]}"
# Gère le cas où le fichier est un lien symbolique.
while [ -h "$SOURCE" ]; do
  DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
# obtient le chemin absolut du répertoire
VOLUND_PATH="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
VOLUND_PATH=$( realpath "$VOLUND_PATH/../")

# include libs
. ${VOLUND_PATH}/lib/term.sh
. ${VOLUND_PATH}/lib/helpers.sh

# Actions
function handle_cmd() {
    if [[ $# -le 0 ]]; then
        # no command provided
        _ERROR "Command is missing"
        . ${VOLUND_PATH}/lib/cmd-help.sh
        aide
        exit -1
    fi

    cmd="$1"
    shift

    case "$cmd" in
        help)
            . ${VOLUND_PATH}/lib/cmd-help.sh
            aide $@
        ;;
        
        *)
            echo "❌ Commande inconnue: $cmd"
            ;;
    esac
}


handle_cmd $@

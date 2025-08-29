
# ---------------------------------------------------------

# PUBLIC help help: donne l'aide sur une commande, ou liste les commandes
# Usage      : aide list
#              aide <command>
#
# Options    : 
#    list      list toutes les commandes disponibles
#    <command> affiche l'aide de <command>
#
# Exemple    :
#   aide list
#   aide aide   # affiche l'aide de la comande aide :)
function aide() {
    local func="$1"
    [ "x${func}" = "x" ] && func='list'

    case $func in

      "list")
        printHeader "Commandes disponibles"
        echo
        _help_list_all | _display_as_table_3cols "Domain" "Cmd" "Description"
        ;;

      *)
        _help_get_cmd $func
        ;;
    esac
}

# on extrait la premiere ligne du commentaire, avec le tag PUBLIC
function _help_list_all() {
    
    for file in ${VOLUND_PATH}/lib/*.sh; do
        grep -E "^# PUBLIC [[:alpha:]]* ?" "$file" | \
            sed 's/^# PUBLIC //' | \
            sed -E 's/^([^:[:space:]]+)([[:space:]]+)/\1:\2/'
    done | sort
}

function _help_get_cmd() {
    local func="$1"
    local found=0

    for file in ${VOLUND_PATH}/lib/*.sh; do
        if grep -qE "^# PUBLIC [[:alpha:]]* ?$func[[:space:]]*:" "$file"; then

            grep -qE "^# PUBLIC [[:alpha:]]* ?$func[[:space:]]*:" "$file"

            echo "==================== Aide pour '$func' ===================="
            echo 

            # -n : empêche sed d’imprimer toutes les lignes par défaut.
            # '/^# [] mafonction/,/^[^#]*$func[[:space:]]*()/p' : imprime uniquement les lignes entre :
            #    une ligne qui commence par # mafonction
            #    et la ligne qui contient mafonction() (la déclaration de la fonction).
            #       convient à : 
            #       mafonction() {
            #       function mafonction() {
            # Puis, on supprime cette derniere ligne (declaration de fonction) car inclue par sed
            # Puis, on supprime le tag PUBLIC du debut
            # On supprime finale le '#' de commentaire en début de chaque ligne
            sed -n "/^# PUBLIC [[:alpha:]]* *$func:/,/^[^#]*$func[[:space:]]*()/p" "$file" \
                | sed '/^[^#]*'"$func"'[[:space:]]*()/d' \
                | sed 's/^# PUBLIC [[:alpha:]]* //' \
                | sed 's/^# PUBLIC //' \
                | sed 's/^# //' \
                | sed 's/^#$//' \
                && found=1
            break
        elif grep -q "^# PUBLIC alias $func[[:space:]]*:" "$file"; then
            echo "==================== Aide pour '$func' (alias) ===================="
            echo

            # Extraction de la documentation pour un alias
            sed -n "/^# PUBLIC alias $func:/,/^alias[[:space:]]\+$func=/p" "$file" \
                | sed '/^alias[[:space:]]\+'"$func"'=/d' \
                | sed 's/^# PUBLIC alias //' \
                | sed 's/^# //' \
                | sed 's/^#$//' \
                && found=1
            break
        fi

    done

    if [[ $found -eq 0 ]]; then
        _ERROR "Aucune documentation trouvée pour '$func'."
    fi
}

# ---------------------------------------------------------

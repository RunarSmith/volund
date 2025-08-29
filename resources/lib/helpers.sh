
# convert string to lowercase
function _toLowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# convert string to lowercase
function _toUppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

function _display_as_table_2cols() {
    local title_1="$1"
    local title_2="$2"
    printf "| %-20s | %s\n" "${title_1}" "${title_2}"
    printf "+ %-20s-+-%s\n" "--------------------" "------------------------------"

    while IFS=: read -r alias description; do
        printf "| %-20s | %s\n" "$alias" "$description"
    done
}

function _display_as_table_3cols() {
    local title_1="$1"
    local title_2="$2"
    local title_3="$3"
    printf "| %-12s | %-20s | %s\n" "${title_1}" "${title_2}" "${title_3}"
    printf "+ %-12s-+-%-20s-+-%s\n" "------------" "--------------------"  "------------------------------"

    while IFS=: read -r domain alias description; do
        printf "| %-12s | %-20s | %s\n" "$domain" "$alias" "$description"
    done
}

function _encode_http() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('$*'))"
}

# ---------------------------------------------------------
# Path conversion Windos / Unix
# ---------------------------------------------------------

function _path_escape_slash() {
    echo "$( echo "$1" | sed 's/\\/\\\\/g' )"
}

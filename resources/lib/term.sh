
# terminal / colors / prompt

#    tput bold – Bold effect
#    tput rev – Display inverse colors
#    tput sgr0 – Reset everything
#    tput setaf {CODE}– Set foreground color, see color {CODE} table below for more information.
#    tput setab {CODE}– Set background color, see color {CODE} table below for more information.

# https://www.ditig.com/256-colors-cheat-sheet

_RESET=$(tput sgr0)
_BOLD=$(tput bold)

# Couleurs de base (0–15)
_Black=$(tput setaf 0)
_Maroon=$(tput setaf 1)
_Green=$(tput setaf 2)
_Olive=$(tput setaf 3)
_Navy=$(tput setaf 4)
_Purple=$(tput setaf 5)
_Teal=$(tput setaf 6)
_Silver=$(tput setaf 7)

_Grey=$(tput setaf 8)
_Red=$(tput setaf 9)
_Lime=$(tput setaf 10)
_Yellow=$(tput setaf 11)
_Blue=$(tput setaf 12)
_Fuchsia=$(tput setaf 13)
_Aqua=$(tput setaf 14)
_White=$(tput setaf 15)

# _Grey0=$(tput setaf 16)
# _NavyBlue=$(tput setaf 17)
# _DarkBlue=$(tput setaf 18)
# _Blue3=$(tput setaf 19)
# _Blue3Bis=$(tput setaf 20)
# _Blue1=$(tput setaf 21)
# _DarkGreen=$(tput setaf 22)
# _DeepSkyBlue4=$(tput setaf 23)

#_DeepSkyBlue4Bis=$(tput setaf 24)
# _DeepSkyBlue4Ter=$(tput setaf 25)
# _DodgerBlue3=$(tput setaf 26)
_DodgerBlue2=$(tput setaf 27)
# _Green4=$(tput setaf 28)
# _SpringGreen4=$(tput setaf 29)
# _Turquoise4=$(tput setaf 30)
# _DeepSkyBlue3=$(tput setaf 31)

# _DeepSkyBlue3Bis=$(tput setaf 32)
# _DodgerBlue1=$(tput setaf 33)
#_Green3=$(tput setaf 34)
# _SpringGreen3=$(tput setaf 35)
# _DarkCyan=$(tput setaf 36)
# _LightSeaGreen=$(tput setaf 37)
# _DeepSkyBlue2=$(tput setaf 38)
# _DeepSkyBlue1=$(tput setaf 39)

_Green3Bis=$(tput setaf 40)
# _SpringGreen3Bis=$(tput setaf 41)
# _SpringGreen2=$(tput setaf 42)
# _Cyan3=$(tput setaf 43)
# _DarkTurquoise=$(tput setaf 44)
# _Turquoise2=$(tput setaf 45)
# _Green1=$(tput setaf 46)
# _SpringGreen2Bis=$(tput setaf 47)

# _SpringGreen1=$(tput setaf 48)
# _MediumSpringGreen=$(tput setaf 49)
# _Cyan2=$(tput setaf 50)
# _Cyan1=$(tput setaf 51)
# _DarkRed=$(tput setaf 52)
# _DeepPink4=$(tput setaf 53)
# _Purple4=$(tput setaf 54)
# _Purple4Bis=$(tput setaf 55)

# _Purple3=$(tput setaf 56)
# _BlueViolet=$(tput setaf 57)
# _Orange4=$(tput setaf 58)
# _Grey37=$(tput setaf 59)
# _MediumPurple4=$(tput setaf 60)
# _SlateBlue3=$(tput setaf 61)
# _SlateBlue3Bis=$(tput setaf 62)
# _RoyalBlue1=$(tput setaf 63)

# _Chartreuse4=$(tput setaf 64)
# _DarkSeaGreen4=$(tput setaf 65)
# _PaleTurquoise4=$(tput setaf 66)
# _SteelBlue=$(tput setaf 67)
# _SteelBlue3=$(tput setaf 68)
# _CornflowerBlue=$(tput setaf 69)
# _Chartreuse3=$(tput setaf 70)
# _DarkSeaGreen4Bis=$(tput setaf 71)

# _CadetBlue=$(tput setaf 72)
# _CadetBlueBis=$(tput setaf 73)
# _SkyBlue3=$(tput setaf 74)
# _SteelBlue1=$(tput setaf 75)
# _Chartreuse3Bis=$(tput setaf 76)
# _PaleGreen3=$(tput setaf 77)
# _SeaGreen3=$(tput setaf 78)
# _Aquamarine3=$(tput setaf 79)

# _MediumTurquoise=$(tput setaf 80)
# _SteelBlue1Bis=$(tput setaf 81)
# _Chartreuse2=$(tput setaf 82)
# _SeaGreen2=$(tput setaf 83)
# _SeaGreen1=$(tput setaf 84)
# _SeaGreen1Bis=$(tput setaf 85)
# _Aquamarine1=$(tput setaf 86)
# _DarkSlateGray2=$(tput setaf 87)

# _DarkRedBis=$(tput setaf 88)
# _DeepPink4Bis=$(tput setaf 89)
# _DarkMagenta=$(tput setaf 90)
# _DarkMagentaBis=$(tput setaf 91)
# _DarkViolet=$(tput setaf 92)
# _PurpleBis=$(tput setaf 93)
# _Orange4Bis=$(tput setaf 94)
# _LightPink4=$(tput setaf 95)

# _Plum4=$(tput setaf 96)
# _MediumPurple3=$(tput setaf 97)
# _MediumPurple3Bis=$(tput setaf 98)
_SlateBlue1=$(tput setaf 99)
#_Yellow4=$(tput setaf 100)
# _Wheat4=$(tput setaf 101)
# _Grey53=$(tput setaf 102)
# _LightSlateGrey=$(tput setaf 103)

# _MediumPurple=$(tput setaf 104)
# _LightSlateBlue=$(tput setaf 105)
# _Yellow4Bis=$(tput setaf 106)
# _DarkOliveGreen3=$(tput setaf 107)
# _DarkSeaGreen=$(tput setaf 108)
# _LightSkyBlue3=$(tput setaf 109)
# _LightSkyBlue3Bis=$(tput setaf 110)
# _SkyBlue2=$(tput setaf 111)

# _Chartreuse2Bis=$(tput setaf 112)
# _DarkOliveGreen3Bis=$(tput setaf 113)
# _PaleGreen3Bis=$(tput setaf 114)
# _DarkSeaGreen3=$(tput setaf 115)
# _DarkSlateGray3=$(tput setaf 116)
# _SkyBlue1=$(tput setaf 117)
# _Chartreuse1=$(tput setaf 118)
# _LightGreen=$(tput setaf 119)

# _LightGreenBis=$(tput setaf 120)
# _PaleGreen1=$(tput setaf 121)
# _Aquamarine1Bis=$(tput setaf 122)
# _DarkSlateGray1=$(tput setaf 123)
# _Red3=$(tput setaf 124)
# _DeepPink4Ter=$(tput setaf 125)
# _MediumVioletRed=$(tput setaf 126)
# _Magenta3=$(tput setaf 127)



# ---------------------------------------------------------

# convert string to lowercase
function _toLowercase() {
    echo "$1" | tr '[:upper:]' '[:lower:]'
}

# convert string to lowercase
function _toUppercase() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

function _encode_http() {
    python3 -c "import urllib.parse; print(urllib.parse.quote('$*'))"
}

# ---------------------------------------------------------
# Logging
# ---------------------------------------------------------

function _DEBUG() {
    local msg="$1"
    echo -e "${_Purple}🪳 ${msg}${_RESET}"
}

function _INFO() {
    local msg="$1"
    echo -e "${_Aqua}${msg}${_RESET}"
}

function _SUCCESS() {
    local msg="$1"
    echo -e "${_Green}✅ ${msg}${_RESET}"
}

function _WARN() {
    local msg="$1"
    echo -e "${_Yellow}🚨 WARN: ${msg}${_RESET}"
}

function _ERROR() {
    local msg="$1"
    echo -e "${_Red}❌ ERROR: ${msg}${_RESET}"
}

function printHeader() {
    _INFO ">---------- $1 --------------------<"
}

# ---------------------------------------------------------

# PUBLIC user set_user_pwd: store user password in a ciphered vault
function set_user_pwd() {

    local userToSet="$1"
    [ "x${userToSet}" = "x" ] && userToSet=$USER

    userToSet=$(_toLowercase "${userToSet}" )

    echo -n "Password for $userToSet: "
    read -s UserPassword
    echo

    # creatre directory if not yet created
    [ ! -d "${WORKSPACE_PATH}/vault/" ] && mkdir -p "${WORKSPACE_PATH}/vault/"
    #[ ! -d "/opt/my-resources/vault/" ] && mkdir -p "/opt/my-resources/vault/"

    # on stock le mot de passe chiffré
    echo "$UserPassword" > ${WORKSPACE_PATH}/vault//pwd-${userToSet}.txt
    #echo "$UserPassword" > /opt/my-resources/vault//pwd-${userToSet}.txt
    openssl enc -aes-256-cbc -in "${WORKSPACE_PATH}/vault/pwd-${userToSet}.txt" -out "${WORKSPACE_PATH}/vault//pwd-${userToSet}.bin"
    #openssl enc -aes-256-cbc -in "/opt/my-resources/vault/pwd-${userToSet}.txt" -out "/opt/my-resources/vault//pwd-${userToSet}.bin"
    unlink ${WORKSPACE_PATH}/vault/pwd-${userToSet}.txt
    #unlink /opt/my-resources/vault/pwd-${userToSet}.txt
}

# PUBLIC user get_user_pwd: get user password
function get_user_pwd() {

    local userToSet="$1"
    [ "x${userToSet}" = "x" ] && userToSet=$USER

    userToSet=$(_toLowercase "${userToSet}" )

    # return the password in a specified format
    local returnFormat=$( _toLowercase "$2" )
    # default value
    [[ "x$returnFormat" = 'x' ]] && returnFormat='raw'
  
    if [ ! -d ${WORKSPACE_PATH}/vault/ ]; then
    #if [ ! -d /opt/my-resources/vault/ ]; then
        _ERROR "vault folder does not exists, cannot get password for user ${userToSet}"
        return -1
    fi

    if [ ! -f "${WORKSPACE_PATH}/vault//pwd-${userToSet}.bin" ]; then
    #if [ ! -f "/opt/my-resources/vault//pwd-${userToSet}.bin" ]; then
        _ERROR "vault file does not exists user ${userToSet}"
        return -1
    fi

    PWDRaw=`openssl aes-256-cbc -d -in ${WORKSPACE_PATH}/vault//pwd-${userToSet}.bin`
    #PWDRaw=`openssl aes-256-cbc -d -in /opt/my-resources/vault/pwd-${userToSet}.bin`
    
    case $returnFormat in

      "raw")
        # return in raw format
        echo "$PWDRaw"
        ;;
    
      "http")
        # encode for HTTP
        #python3 -c "import urllib.parse; print(urllib.parse.quote('$PWDRaw'))"
        _encode_http "$PWDRaw"
        ;;

      *)
        _ERROR "Unknown '$returnFormat' format"
        return -1
        ;;
    esac
}

# ---------------------------------------------------------

# PUBLIC user shell_logging: start a new shell and record it
# example :
# co_shell_logging y
function shell_logging() {

    # enable compression at the end of the session
    local compress=$( _toLowercase "$1" )
    # default value
    [[ "x$compress" = 'x' ]] && compress='yes'

    # the method to use for shell logging (default to script)
    local method="script"
    # shell command to use for the user
    local user_shell="bash"

    # Logging shell using $method and spawn a $user_shell shell

    umask 007
    mkdir -p ${WORKSPACE_PATH}/logs/
    local filelog
    filelog="${WORKSPACE_PATH}/logs/$(date +%d-%m-%Y_%H-%M-%S)_shell.${method}"
    fileTiming="${WORKSPACE_PATH}/logs/$(date +%d-%m-%Y_%H-%M-%S)_timing.${method}"

    echo "====== Starting session recording ======"
    echo "Log file: ${filelog}"

    case $method in

      "script")
        # echo "Run using script"
        script --quiet --return --flush --append --command "$user_shell"  --log-timing "$fileTiming" "$filelog"
        ;;

      *)
        echo "Unknown '$method' shell logging method"
        return -1
        ;;
    esac

    echo "====== End of session recording ======"
    echo "Log file:"
    ls -ohg $filelog
    ls -ogh $fileTiming
    echo "replay with:  scriptreplay --timing <timing file> <shell file>"

    if [[ "$compress" = 'true' || "$compress" = 'yes' || "$compress" = 'y' ]]; then
      echo 'Compressing logs, please wait...'
      gzip "$filelog"
    fi
}

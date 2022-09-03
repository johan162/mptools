#!/usr/bin/env bash
# Create one or more multipass nodes based on the node naming convention
#
# Written by: Johan Persson <johan162@gmail.com>
# All tools released under MIT License. See LICENSE file.
# ==============================================================================================

# Detect in some common error conditions.
set -o nounset
set -o pipefail

# Cache result ito temp file since it is a slow operation
declare tmpfilename=$(mktemp /tmp/mplist.XXXXXXXXXXXXX)
multipass list >$tmpfilename

# Exit handler
function cleanup {
    rm -f "$tmpfilename"
}

trap cleanup EXIT

# Print error messages in red
red="\033[31m"
default="\033[39m"

# Format error message
errlog() {
    printf "$red*** ERROR *** "
    printf "$@"
    printf "$default\n"
}

# Format info message
infolog() {
    [[ ${quiet_flag} -eq 0 ]] && printf "$@"
}

# Get version from the one true source - the makefile
printversion() {
    declare vers
    if vers=$(grep DIST_VERSION Makefile | head -1 | awk '{printf "v" $3 }'); then
        errlog "Internal error. Failed to extract version from Makefile. Please report!"
        exit 1
    fi
    declare name
    name=$(basename "$0")
    infolog "Name: ${name}\n"
    infolog "Version: ${vers}\n"
}

# arg1 word to find
# arg2 list to check from. Should be passed as "${list[@]}"
exist_in_list() {
    local -i found=0
    local find="$1"
    shift
    local list=("$@")
    for v in "${list[@]}"; do
        if [[ $v == "$find" ]]; then
            found=1
            break
        fi
    done
    return $found
}


usage() {
    declare name=$(basename $0)
    cat <<EOT
NAME
   $name
USAGE
   $name [-h] [-v] [-s] NODE_NAME [NODE_NAME [NODE_NAME ... ]]
SYNOPSIS
      -h        : Print help and exit
      -s        : Silent
      -v        : Print version and exit
EOT
}

# Check we are executing from the mptools directory
if [[ ! -d ../mptools || ! -f ../mptools/Makefile ]]; then
    errlog "Must be executed from the mptools directory."
    exit 1
fi

declare -i quiet_flag=0
declare nodes=""
declare nodeList=("")

while [[ $OPTIND -le "$#" ]]; do
    if getopts svh o; then
        case "$o" in
            v)
                printversion "$0"
                exit 0
                ;;
            h)
                usage "$0"
                exit 0
                ;;
            s)
                quiet_flag=1
                ;;
            [?])
                usage "$(basename "$0")"
                exit 1
                ;;
        esac
    elif [[ $OPTIND -le "$#" ]]; then
        nodeName="${!OPTIND}"
        if [[ ! "$nodeName" =~ ^ub(22|18|20)[bmf][smlexh][0-9]{2}$ ]]; then
            errlog "Node name \"$nodeName\" not in recognised format ub<18|20|22><b|m|f|><s|m|l|x|h><NODENUMBER>"
            exit 1
        fi

        # Check if this node already exist
        if grep $nodeName < "$tmpfilename" >/dev/null; then
            errlog "Node $nodeName already exists, skipping."
        else
            if ! exist_in_list ${nodeName} "${nodeList[@]}"; then
                errlog "Same node name specified more than once \"${nodeName}\""
                exit 1
            fi
            nodeList+=("$nodeName")
            nodes+="$nodeName "
        fi
        ((OPTIND++))
    fi
done
if [[ -z $nodes ]]; then
    infolog "No nodes to create.\n"
    exit 1
fi

if [[ $quiet_flag -eq 1 ]]; then
   echo make -s NODES="${nodes}" node
else
   echo make NODES="${nodes}" node
fi

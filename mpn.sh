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
declare nodecachefile=$(mktemp /tmp/mplist.XXXXXXXXXXXXX)
multipass list >$nodecachefile

# Exit handler
function cleanup {
    rm -f "$nodecachefile"
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
    if ! vers=$(grep DIST_VERSION Makefile | head -1 | awk '{printf "v" $3 }'); then
        echo $vers
        errlog "Internal error. Failed to extract version from Makefile. Please report!"
        exit 1
    fi
    declare name
    name=$(basename "$0")
    infolog "${name} ${vers}\n"
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
      -n        : No execute (dryrun)
      -s        : Silent
      -v        : Print version and exit
EOT
}

declare MKMPNODE="./mkmpnode.sh"
declare MPTOOL_DIR="."
# Find out where mkmpnode.sh is
if [[ ! -f ${MKMPNODE} ]]; then
    if [[ -f "/usr/local/bin/mkmpnode" ]]; then
        MKMPNODE=$(readlink /usr/local/bin/mkmpnode)
        MPTOOL_DIR=$(dirname ${MKMPNODE})
    else
        errlog "Cannot find mkmpnode.sh"
        exit 1
    fi
fi


declare -i quiet_flag=0
declare nodes=""
declare nodeList=("")
declare -i noexec=0

# Predefined cloud configs based on the infix in the node name
declare CLOUD_CONFIG_F="cloud/fulldev-config.yaml"
declare CLOUD_CONFIG_B="cloud/mini-config.yaml"
declare CLOUD_CONFIG_M="cloud/minidev-config.yaml"

# Predefined sizes based on the infix in the node name
declare MACHINE_CONFIG_S="-m 500MB -d 5GB"
declare MACHINE_CONFIG_M="-m 1GB -d 5GB"
declare MACHINE_CONFIG_E="-m 3GB -d 5GB"
declare MACHINE_CONFIG_L="-m 2GB -d 10GB"
declare MACHINE_CONFIG_X="-m 4GB -d 15GB"
declare MACHINE_CONFIG_H="-m 8GB -d 20GB"

# Predefined image names corresponding to the major Ubuntu releases as specified in the node name
declare IMAGE_UB22=jammy
declare IMAGE_UB20=focal
declare IMAGE_UB18=bionic


while [[ $OPTIND -le "$#" ]]; do
    if getopts svhn o; then
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
            n)
                infolog ":: DRYRUN ::\n"
                noexec=1
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
        if grep $nodeName <"$nodecachefile" >/dev/null; then
            errlog "Node $nodeName already exists, skipping."
        else
            if ! exist_in_list ${nodeName} "${nodeList[@]}"; then
                errlog "Same node name specified more than once \"${nodeName}\""
                exit 1
            fi
            nodeList+=("$nodeName")
            nodes+="$nodeName "

            CLOUD_CONF=CLOUD_CONFIG_$(echo $nodeName|cut -c 5|tr  '[:lower:]' '[:upper:]')
            MACHINE_SIZE=MACHINE_CONFIG_$(echo $nodeName|cut -c 6|tr  '[:lower:]' '[:upper:]')
            IMAGE=IMAGE_UB$(echo $nodeName|cut -c 3-4|tr  '[:lower:]' '[:upper:]')
            if [[ ${noexec} -eq 1 ]]; then
                ${MKMPNODE} -n -r ${!IMAGE} -c ${MPTOOL_DIR}/${!CLOUD_CONF} ${!MACHINE_SIZE} $nodeName &
            else
                ${MKMPNODE} -r ${!IMAGE} -c ${MPTOOL_DIR}/${!CLOUD_CONF} ${!MACHINE_SIZE} $nodeName &
            fi
        fi
        ((OPTIND++))
    fi
done
if [[ -z $nodes ]]; then
    errlog "No node names specified."
    exit 1
fi

# Wait for all subprocesses to finish
wait


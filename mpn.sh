#!/usr/bin/env bash
## \file
## \brief mpn.sh - Setup nodes using naming convention
## \details
## ```
## NAME
##    mpn - Create multipass node by naming convention
## USAGE
##    mpn [-h] [-v] [-s] NODE_NAME [NODE_NAME [NODE_NAME ... ]]
## SYNOPSIS
##       -h        : Print help and exit
##       -n        : No execution. Only display actions.
##       -s        : Silent
##       -v        : Print version and exit
## ```
## \author Johan Persson <johan162@gmail.com>
## \copyright MIT License. See LICENSE file.

# Detect in some common error conditions.
set -o nounset
set -o pipefail

## \brief Cache result to temp file during one runt of the script since `multipass list` it is a slow operation
declare nodecachefile=$(mktemp /tmp/mplist.XXXXXXXXXXXXX)
multipass list >$nodecachefile

## \brief Default installation path
declare INSTALL_PREFIX="/usr/local"

## \brief Default installation path for executables
declare INSTALL_BIN_DIR="${INSTALL_PREFIX}/bin"

## \brief Name of the `mkmpnode` script we call
declare MKMPNODE_SCRIPT="./mkmpnode.sh"

## \brief Directory where to find the user specific `*.yaml` files
declare INSTALL_USERCLOUDINIT_DIR=${HOME}/.mptools

## \brief This will hold the name of the directory from where this script is executed
declare SCRIPT_DIR=""
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

## \brief Suppress output
declare -i quiet_flag=0

## \brief String of nodes names to create
declare nodes=""

## \brief The string of nodes converted to a list
declare nodeList=("")

## \brief Flag for dryrun
declare -i noexec=0

## @brief Terminal color for error messages
declare red="\033[31m"

## @brief Restore default terminal color
declare default="\033[39m"

# Predefined cloud configs based on the infix in the node name

## \brief Cloud file for full development environment
declare -r CLOUD_CONFIG_F="fulldev-config.yaml"

## \brief Cloud file for minimal node config
declare -r CLOUD_CONFIG_B="mini-config.yaml"

## \brief Cloud file for minimal development environment
declare -r CLOUD_CONFIG_M="minidev-config.yaml"

# Predefined sizes based on the infix in the node name

## \brief Size configuration for a small node
declare -r MACHINE_CONFIG_S="-m 500MB -d 5GB"

## \brief Size configuration for a medium node
declare -r MACHINE_CONFIG_M="-m 1.5GB -d 8GB"

## \brief Size configuration for an expanded node
declare -r MACHINE_CONFIG_E="-m 3GB -d 8GB"

## \brief Size configuration for a large node
declare -r MACHINE_CONFIG_L="-m 2GB -d 10GB"

## \brief Size configuration for a x-large node
declare -r MACHINE_CONFIG_X="-m 4GB -d 10GB"

## \brief Size configuration for a humongous node
declare -r MACHINE_CONFIG_H="-m 8GB -d 15GB"

## \brief Size configuration for a zuper humongous node
declare -r MACHINE_CONFIG_Z="-m 12GB -d 20GB"

# Predefined image names corresponding to the major Ubuntu releases as specified in the node name
## \brief Image to use for a `24` node
declare -r IMAGE_UB24=noble

## \brief Image to use for a `22` node
declare -r IMAGE_UB22=jammy

## \brief Image to use for a `20` node
declare -r IMAGE_UB20=focal

## \brief Image to use for `18` node
declare -r IMAGE_UB18=bionic

## \brief Setup the node for bridged network (or not) defaults to "not"
declare bridged=

## \brief Exit handler
function cleanup {
    rm -f "$nodecachefile"
}

trap cleanup EXIT

# Find out where mkmpnode.sh is
if [[ ! -f ${MKMPNODE_SCRIPT} ]]; then
    if [[ -L "${INSTALL_BIN_DIR}/mkmpnode" ]]; then
        MKMPNODE_SCRIPT=$(readlink ${INSTALL_BIN_DIR}/mkmpnode)
    else
        MKMPNODE_SCRIPT="${SCRIPT_DIR}/mkmpnode.sh"
        if [[ ! -f "$MKMPNODE_SCRIPT" ]]; then
            errlog "Cannot find mkmpnode.sh"
            exit 1
        fi
    fi
fi

# Find out where the cloud-init files are
if [[ ! -d $INSTALL_USERCLOUDINIT_DIR ]]; then
    INSTALL_USERCLOUDINIT_DIR="./cloud"
    if [[ ! -d $INSTALL_USERCLOUDINIT_DIR ]]; then
        INSTALL_USERCLOUDINIT_DIR="${SCRIPT_DIR}/cloud"
        if [[ ! -d $INSTALL_USERCLOUDINIT_DIR ]]; then
            errlog "Cannot locate cloud files"
            exit 1
        fi
    fi
fi


## \brief Format error message
## \param `$*` Error string to display
errlog() {
    printf "$red*** ERROR *** "
    printf "$@"
    printf "$default\n"
}


## \brief Format info message
## \param `$*` Info string to display
infolog() {
    [[ ${quiet_flag} -eq 0 ]] && printf "$@"
}


## \brief Get version from the one true source - the makefile
printversion() {
    declare vers
    declare MAKEFILE_DIR

    MAKEFILE_DIR=$(dirname "$MKMPNODE_SCRIPT")
    if ! vers=$(grep DIST_VERSION "$MAKEFILE_DIR/Makefile" | head -1 | awk '{printf "v" $3 }'); then
        echo $vers
        errlog "Internal error. Failed to extract version from Makefile. Please report!"
        exit 1
    fi
    declare name
    name=$(basename "$0")
    infolog "${name} ${vers}\n"
}


## \brief Utility function to verify that a value exists in a list
## \param arg1 word to find
## \param arg2 list to check from. Should be passed as "`${list[@]}`"
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


## \brief Print usage
## \param `$0`  Script name
usage() {
    declare name=$(basename $0)
    cat <<EOT
NAME
   $name - Create multipass node by naming convention
USAGE
   $name [-h] [-v] [-s] NODE_NAME [NODE_NAME [NODE_NAME ... ]]
SYNOPSIS
      -h        : Print help and exit
      -b        : Bridge the nodes (make them available on the local network)
      -n        : No execution. Only display actions.
      -s        : Silent
      -v        : Print version and exit

The node name will control the size and capacity of the node.
ub<MAJOR_RELEASE><CONFIG><SIZE><NODE_NUMBER>
MAJOR_RELEASE=[18|20|22|24]
CONFIG=[f=Full dev|m=Minimal dev|b=Basic none-dev node]
SIZE=[s=small|m=medium|l=large|x=x-larg|h=humungous|z=zuper humungus]
NODE_NUMBER=[0-9]{2}
EOT
}



while [[ $OPTIND -le "$#" ]]; do
    if getopts svhnb o; then
        case "$o" in
            v)
                printversion "$0"
                exit 0
                ;;
            b)
                nw=$(multipass get local.bridged-network)
                if [[  $nw = "<empty>" ]]; then
                    errlog "You must set 'local.bridged-network' to use bridged nodes."
                    errlog "For example: 'multipass set local.bridged-network=en0' to first adapter (often WiFi on laptop)"
                    errlog "You can check your available networks with 'multipass networks'"
                    exit 1
                fi
                bridged="-b "
                ;;
            h)
                usage "$0"
                exit 0
                ;;
            s)
                quiet_flag=1
                ;;
            n)
                infolog ":: DRYRUN mpn ::\n"
                noexec=1
                ;;
            [?])
                usage "$(basename "$0")"
                exit 1
                ;;
        esac
    elif [[ $OPTIND -le "$#" ]]; then
        nodeName="${!OPTIND}"
        if [[ ! "$nodeName" =~ ^ub(24|22|18|20)[bmf][smlexhz][0-9]{2}$ ]]; then
            errlog "Node name \"$nodeName\" not in recognised format ub<18|20|22|24><b|m|f|><s|m|l|x|h|z><NODENUMBER>"
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

            CLOUD_CONF=CLOUD_CONFIG_$(echo $nodeName | cut -c 5 | tr '[:lower:]' '[:upper:]')
            MACHINE_SIZE=MACHINE_CONFIG_$(echo $nodeName | cut -c 6 | tr '[:lower:]' '[:upper:]')
            IMAGE=IMAGE_UB$(echo $nodeName | cut -c 3-4 | tr '[:lower:]' '[:upper:]')

            if [[ ${noexec} -eq 1 ]]; then
                ${MKMPNODE_SCRIPT} -n -r ${!IMAGE} -c ${INSTALL_USERCLOUDINIT_DIR}/${!CLOUD_CONF} ${!MACHINE_SIZE} ${bridged} $nodeName &
            else
                ${MKMPNODE_SCRIPT} -r ${!IMAGE} -c ${INSTALL_USERCLOUDINIT_DIR}/${!CLOUD_CONF} ${!MACHINE_SIZE} ${bridged} $nodeName &
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

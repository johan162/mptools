#!/usr/bin/env bash
## \file
## \brief mkmpnode - Create multipass nodes with a specified (or default) cloud-init file
## \details
## ```
## NAME
##   mkmpnode
## USAGE
##   mkmpnode [-r RELEASE] [-c FILE] [-d SIZE] [-p CPUS] [-m SIZE] [-q] [-v] [-h] NODE_NAME
## SYNOPSIS
##      -r RELEASE: Valid ubuntu release [bionic focal impish jammy docker] ($ubuntuVer)
##      -c FILE   : Cloud config file (${defaultCloudInit})
##      -m SIZE   : Memory size, defaults (500MB)
##      -d SIZE   : Disk size, defaults (5GB)
##      -p NUM    : Number of CPUs (2)
##      -M        : Mount ${HOME}/Devel inside node
##      -n        : No execution. Only display actions.
##      -q        : Quiet  (no output to stdout)
##      -v        : Print version and exit
##      -h        : Print help and exit
## ```
## \author Johan Persson <johan162@gmail.com>
## \copyright MIT License. See LICENSE file.

# Detect in some common error conditions.
set -o nounset
set -o pipefail

## @brief Which base image to use. Can be overridden by ned user.
declare ubuntuVer=jammy

## @brief Node name. Specified by user
declare nodeName=

## @brief Node memory size.
declare memory="500M"

## @brief Node disk size.
declare disk="5G"

## @brief Number of virtual CPUs available for node
declare -i cpus=2

## @brief Determine if we should mount `~/Devel` in the users home directory in the node
declare mountDev=0

## @brief Valid options for ubuntuVer
declare -r vlist=("bionic" "focal" "impish" "jammy" "docker")

## @brief Flag for doing a dryrun
declare -i noexecute=0

## @brief Which cloud-init file to use
declare cloudInit=""

## @brief Default cloud-init file if none specified by user
declare defaultCloudInit="minidev-config.yaml"

# Don't edit below this line
# --------------------------

## @brief Suppress output
declare -i quiet_flag=0

## @brief Terminal color for error messages
declare red="\033[31m"

## @brief Restore default terminal color
declare default="\033[39m"

## \brief Default installation path
declare -r INSTALL_PREFIX="/usr/local"

## \brief Default installation path for executables
declare -r INSTALL_BIN_DIR="${INSTALL_PREFIX}/bin"

## \brief Name of the `mkmpnode` script we call
declare MKMPNODE_SCRIPT="./mkmpnode.sh"

## \brief This will hold the name of the directory from where this script is executed
declare -r SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

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

## @brief Format error message
errlog() {
    printf "$red*** ERROR *** "
    printf "$@"
    printf "$default\n"
}

## @brief Format info message
infolog() {
    [[ ${quiet_flag} -eq 0 ]] && printf "$@"
}

# Check we are executing from the mptools directory
#if [[ ! -d ../mptools || ! -f ../mptools/Makefile ]]; then
#    errlog "Must be executed from the mptools directory."
#    exit 1
#fi

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

## @brief Utility function to verify that a value exists in a list
## @param arg1 word to find
## @param arg2 list to check from. Should be passed as "${list[@]}"
exist_in_list() {
    local found=0
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

## @brief Print usage
## @param `$0`  Script name
usage() {
    declare name
    name=$(basename "$0")
    cat <<EOT
NAME
   $name - Create multipass nodes with a specified (or default) cloud-init file
USAGE
   $name [-r RELEASE] [-c FILE] [-d SIZE] [-p CPUS] [-m SIZE] [-q] [-v] [-h] NODE_NAME
SYNOPSIS
      -r RELEASE: Valid ubuntu release [bionic focal impish jammy docker] ($ubuntuVer)
      -c FILE   : Cloud config file (${defaultCloudInit})
      -m SIZE   : Memory size, defaults (${memory})
      -d SIZE   : Disk size, defaults (${disk}GB)
      -p NUM    : Number of CPUs (${cpus})
      -M        : Mount ${HOME}/Devel inside node
      -n        : No execution. Only display actions.
      -q        : Quiet  (no output to stdout)
      -v        : Print version and exit
      -h        : Print help and exit
EOT

}

while [[ $OPTIND -le "$#" ]]; do
    if getopts r:c:m:d:p:hMvn o; then
        case "$o" in
            h)
                usage "$0"
                exit 0
                ;;
            r)
                if exist_in_list "$OPTARG" "${vlist[@]}"; then
                    errlog "Unknown Ubuntu release: \"${OPTARG}\", must be one of: \"${vlist[*]}\""
                    exit 1
                fi
                ubuntuVer="$OPTARG"
                ;;
            c)
                cloudInit="$OPTARG"
                ;;
            m)
                memory="$OPTARG"
                ;;
            d)
                disk="$OPTARG"
                ;;
            p)
                cpus="$OPTARG"
                if [[ $cpus -lt 1 || $cpus -gt 8 ]]; then
                    errlog "Number of CPUs must be between 1-8"
                    exit 1
                fi
                ;;
            M)
                mountDev=1
                ;;
            v)
                printversion "$0"
                exit 0
                ;;
            n)
                infolog ":: DRYRUN mkmpnode ::\n"
                noexecute=1
                ;;
            [?])
                usage "$(basename "$0")"
                exit 1
                ;;
        esac
    elif [[ $OPTIND -le "$#" ]]; then
        nodeName="${!OPTIND}"
        ((OPTIND++))
    fi
done

if [[ -z $nodeName ]]; then
    errlog "Nodename not specified"
    usage "$1"
    exit 1
fi

if multipass list | grep $nodeName >/dev/null; then
    VM_STATE=$(multipass info $nodeName | grep -i State)
    case "${VM_STATE}" in
        *Stopped)
            multipass start $nodeName
            ;;
        *Running)
            echo "$nodeName is already running"
            ;;
        *)
            echo "VM is $VM_STATE, wait and run again"
            exit 1
            ;;
    esac
else
    declare homeDir=$HOME
    declare mountopt=""
    if [[ $mountDev -eq 1 && -d "${HOME}/Devel" ]]; then
        mountopt="--mount $homeDir/Devel:/home/ubuntu/Devel"
    fi

    declare cinitopt=""
    SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)

    # We must have a cloud-init file
    if [[ -z $cloudInit ]]; then
        infolog "Note: No cloud file specified. Using ${defaultCloudInit}.\n"
        cloudInit=${defaultCloudInit}
    fi

    if [[ -f ${cloudInit} ]]; then
        cinitopt="--cloud-init ${cloudInit}"
    elif [[ ${cloudInit} == $(basename ${cloudInit}) ]]; then
        # o path provided so check if cloud-init file exists in current directory
        # under "./cloud" or in the home directory under "~/.mptools"
        if [[ -f "./cloud/${cloudInit}" ]]; then
            cinitopt="--cloud-init ./cloud/${cloudInit}"
        elif [[ -f "${SCRIPT_DIR}/cloud/${cloudInit}" ]]; then
            cinitopt="--cloud-init ${SCRIPT_DIR}/cloud/${cloudInit}"
        elif [[ -f "${HOME}/.mptools/${cloudInit}" ]]; then
            cinitopt="--cloud-init ${HOME}/.mptools/${cloudInit}"
        fi
    fi

    if [[ -z ${cinitopt} ]]; then
        errlog "Can not find location for cloud init file '${cloudInit}'."
        exit 1
    fi

    if [[ ${noexecute} -eq 0 ]]; then
        infolog "Executing: multipass launch ${cinitopt} --name $nodeName --mem $memory --disk $disk --cpus $cpus ${mountopt} $ubuntuVer\n"
        if ! multipass launch --timeout 600 ${cinitopt} --name $nodeName --mem $memory --disk $disk --cpus $cpus ${mountopt} $ubuntuVer >/dev/null; then
            errlog "Failed to create node!"
            exit 1
        fi

        if ! multipass restart $nodeName >/dev/null; then
            errlog "Failed to restart $nodeName.\n"
            exit 1
        fi

        # Finally, give some information of the successfully newly created node
        echo "==================================================="
        echo "Created" \"$nodeName\" $(date "+%Y-%m-%d %H:%M:%S")
        echo "==================================================="

        multipass info $nodeName
    else
        echo multipass launch --timeout 600 ${cinitopt} --name $nodeName --mem $memory --disk $disk --cpus $cpus ${mountopt} $ubuntuVer
        echo multipass restart $nodeName
        echo multipass info $nodeName
    fi

fi

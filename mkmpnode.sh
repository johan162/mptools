#!/usr/bin/env bash
# Setup a multipass node
#
# Written by: Johan Persson <johan162@gmail.com>
# All tools released under MIT License. See LICENSE file
# ==========================================================================

# Detect in some common error conditions.
set -o nounset
set -o pipefail

declare ubuntuVer=jammy
declare nodeName=
declare memory="500M"
declare disk="5G"
declare -i cpus=2
declare cloudInit=
declare mountDev=0
declare vlist=("bionic" "focal" "impish" "jammy" "docker")
declare -i noexecute=0

# Don't edit below this line
# --------------------------
declare -i quiet_flag=0

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


# Check we are executing from the mptools directory
#if [[ ! -d ../mptools || ! -f ../mptools/Makefile ]]; then
#    errlog "Must be executed from the mptools directory."
#    exit 1
#fi

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

# Print usage
usage() {
    declare name
    name=$(basename "$0")
    cat <<EOT
NAME
   $name
USAGE
   $name [-r RELEASE] [-c FILE] [-d SIZE] [-p CPUS] [-m SIZE] [-q] [-v] [-h] NODE_NAME
SYNOPSIS
      -r RELEASE: Valid ubuntu release [bionic focal impish jammy docker] ($ubuntuVer)
      -c FILE   : Cloud config file (${cloudInit})
      -m SIZE   : Memory size, defaults (${memory})
      -d SIZE   : Disk size, defaults (${disk}GB)
      -p NUM    : Number of CPUs (${cpus})
      -M        : Mount ${HOME}/Devel inside node
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

    declare cinitopt

    # No cloud init file given. Use the default and see if it either
    # is in ~/.mptools or in the current directory under cloud/
    if [[ -z $cloudInit ]]; then
        infolog "Note: No cloud file specified. Using minidev config.\n"
        cloudInit="minidev-config.yaml"
        SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
#        declare MPTOOL_INSTALL_DIR

        # Find out where we can find the cloud files
#        if [[ ! -d ${HOME}/.mptools ]]; then
#            if [[ -f "/usr/local/bin/mkmpnode" ]]; then
#                MKMPNODE=$(readlink /usr/local/bin/mkmpnode)
#                MPTOOL_INSTALL_DIR=$(dirname ${MKMPNODE})
#            else
#                errlog "mptools not installed"
#                exit 1
#            fi
#        else
#            MPTOOL_INSTALL_DIR=${SCRIPT_DIR}
#        fi

        # We check for the default cloud file in three possible location
        # In a directory named "cloud" in current working directory
        # In a directory named "cloud" from where this script is run
        # In the persons ~/.mptools where the cloud-init files are stored after installation
        echo "SCRIPT_DIR=${SCRIPT_DIR}"
        if [[ -f "cloud/${cloudInit}" ]]; then
            cinitopt="--cloud-init cloud/${cloudInit}"
        elif [[ -f "${SCRIPT_DIR}/cloud/${cloudInit}" ]]; then
            cinitopt="--cloud-init ${SCRIPT_DIR}/cloud/${cloudInit}"
        elif [[ -f "${HOME}/.mptools/${cloudInit}" ]]; then
            cinitopt="--cloud-init  ${HOME}/.mptools/${cloudInit}"
        else
            errlog "Internal error .Cannot locate default cloud-init file: ${cloudInit}."
            exit 1
        fi
    elif [[ -f ${cloudInit} ]]; then
        cinitopt="--cloud-init ${cloudInit}"
    else
        errlog "Specified cloud init file '${cloudInit}' does not exist."
        exit 1
    fi

    if [[ ${noexecute} -eq 0 ]]; then
        infolog "Executing: multipass launch ${cinitopt} --name $nodeName --mem $memory --disk $disk --cpus $cpus ${mountopt} $ubuntuVer\n"
        if ! multipass launch --timeout 600 ${cinitopt} --name $nodeName --mem $memory --disk $disk --cpus $cpus ${mountopt} $ubuntuVer > /dev/null; then
            errlog "Failed to create node!"
            exit 1
        fi

        if ! multipass restart $nodeName > /dev/null; then
            errlog "Failed to restart $nodeName.\n"
            exit 1
        fi

        # Finally, give some information of the successfully newly created node
        echo "==================================================="
        echo "Created" \"$nodeName\" $(date "+%Y-%m-%d %H:%M:%S")
        echo "==================================================="

        multipass info $nodeName
    else
        echo multipass launch --timeout 600 ${cinitopt} --name $nodeName --mem $memory --disk $disk --cpus $cpus ${mountopt} $ubuntuVer;
        echo multipass restart $nodeName
        echo multipass info $nodeName
    fi

fi

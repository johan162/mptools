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
    if getopts r:n:c:m:d:p:hMv o; then
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

    if [[ -z $cloudInit ]]; then
        infolog "Note: No cloud file specified. Using minidev config.\n"
        declare cinitopt="--cloud-init cloud/minidev-config.yaml"
    elif [[ -f $cloudInit ]]; then
        declare cinitopt="--cloud-init $cloudInit"
    else
        errlog "Specified cloud init file '$cloudInit' does not exist."
        exit 1
    fi

    infolog "Executing: multipass launch ${cinitopt} --name $nodeName --mem $memory --disk $disk --cpus $cpus ${mountopt} $ubuntuVer\n"
    if multipass launch --timeout 600 ${cinitopt} --name $nodeName --mem $memory --disk $disk --cpus $cpus ${mountopt} $ubuntuVer; then
        errlog "Failed to create node!"
        exit 1
    fi

    if multipass restart $nodeName; then
        errlog "Failed to restart $nodeName.\n"
        exit 1
    fi

    # Finally, give some information of the newly created node
    multipass info $nodeName

fi

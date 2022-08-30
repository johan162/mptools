#!/usr/bin/env bash
# Create one or more multipass nodes based on the node naming convention
#
# Written by: Johan Persson <johan162@gmail.com>
# All tools released under MIT License. See LICENSE file.
# ==============================================================================================

set -u

declare tmpfilename=$(mktemp /tmp/mplist.XXXXXXXXXXXXX)
multipass list > $tmpfilename

function cleanup {
  rm -f $tmpfilename
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
  declare vers=$(grep DIST_VERSION Makefile | head -1 | awk '{printf "v" $3 }')
  declare name=$(basename $0)
  infolog "Name: ${name}\n"
  infolog "Version: ${vers}\n"
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

while [[ $OPTIND -le "$#" ]]; do
    if getopts svh o; then
        case "$o" in
        v)
            printversion $0
            exit 0
            ;;
        h)
            usage $0
            exit 0
            ;;
        s)
            quiet_flag=1
            ;;
        [?])
            usage "$(basename $0)"
            exit 1
            ;;
        esac
    elif [[ $OPTIND -le "$#" ]]; then
        nodeName="${!OPTIND}"
        if [[ ! "$nodeName" =~ ^ub(22|18|20)[bmf][smlexh][0-9]{2}$ ]] ; then
            errlog "Node name not in recognised format ub<18|20|22><b|m|f|><s|m|l|x|h><NODENUMBER>: \"$i\""
            exit 1
        fi

        # Check if this node already exist
        if cat $tmpfilename | grep $nodeName >/dev/null; then
          errlog "Node $nodeName already exists."
          exit 1
        fi
        nodes+="$nodeName "
        ((OPTIND++))
    fi
done

if [[ $quiet_flag -eq 1 ]]; then
  make -s NODES="$nodes" node
else
  make NODES="${nodes}" node
fi



#!/usr/bin/env bash
#
# Install multipass and set up some useful aliases
#
# Written by: Johan Persson <johan162@gmail.com>
# All tools released under MIT License. See LICENSE file.
# ==========================================================================
# Print error messages in red
red="\033[31m"
default="\033[39m"

declare quiet_flag=0

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

# Check if multipass is already installed
hash multipass > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  errlog "multipass is already installed."
  exit 0
else
  echo "multipass not found. Will start installation."
fi

# Check if brew is installed
hash brew  > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
  errlog "homebrew not installed. Please visit https://brew.sh/"
  exit 0
fi

# Add some aliases to .zshenv for ease of use
if [[ -f ${HOME}/.zshenv ]]; then
  grep 'alias mp="multipass"' ${HOME}/.zshenv > /dev/null
  if [[ $? -eq 0 ]]; then
    infolog "Aliases will not be added to .zshenv as they have already been added."
  else
    cat << EOF >> ${HOME}/.zshenv
# ===========================================
# Automatically added by mpinstall.sh
# multipass conveniences aliases
# ===========================================
alias mp="multipass"
alias mpl="multipass list"
alias mps="multipass shell"
alias mpe="multipass exec"
alias mpd="multipass delete -p"
alias mpp="multipass purge"
alias mpi="multipass info"
alias mpstoa="multipass stop --all"
alias mpsta="multipass start --all"
alias mpia="multipass info --all"
alias mpsu="multipass suspend"
alias mpsua="multipass suspend --all"
EOF
  fi
  grep 'export SSH_PUBLIC_KEY"' ${HOME}/.zshenv > /dev/null
  if [[ $? -eq 0 ]]; then
      infolog "SSH_PUBLIC_KEY will not be added to .zshenv as it has already been added."
    else
      cat << EOF >> ${HOME}/.zshenv
# ===========================================
# Automatically added by mpinstall.sh
# User SSH key
# ===========================================
export SSH_PUBLIC_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
EOF
fi

# Now do the install through homebrew
# Find out if we are running on Intel or M1
if [[ $(uname -m) == 'x86_64' ]]; then
  # Switch from hyperkit to qemu in order for efficiency and be able
  # to get/set more parameters if we are on Intel
  brew install libvirt
  brew install --cask multipass
  mp set local.driver=qemu
else
  # On M1 qemu is already used so we just install it
  brew install --cask multipass
fi

infolog "=========================="
infolog "multipass setup completed."
infolog "=========================="


#!/usr/bin/env bash
#
# Install multipass and set up some useful aliases
#
# Written by: Johan Persson <johan162@gmail.com>
# All tools released under MIT License. See LICENSE file.
# ==========================================================================

# Check if multipass is already installed
hash multipass > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo "multipass is already installed"
  exit 0
else
  echo "multipass not found. Will start installation"
fi

# Add some aliases to .zshenv for ease of use
if [[ -f ${HOME}/.zshenv ]]; then
  grep 'alias mp="multipass"' ${HOME}/.zshenv > /dev/null
  if [[ $? -eq 0 ]]; then
    echo "Aliases will not be added to .zshenv as they have already been added."
    exit 0
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
alias mpia="multipass info --all"
EOF
  fi
fi

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


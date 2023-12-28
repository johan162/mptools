# Aliases {#aliases}


After installation the set of aliases below are available in `mpaliases.inc`. 
The file stored in the user cloud directory (usually `${HOME}/.mptools/`)
user and the following line should be added to `.zshenv` to have the
alias file included.

```
source ${HOME}/.mptools/mpaliases.inc
```

The aliases included currently are:

```shell
alias mp="multipass"
alias mpl="multipass list"
alias mps="multipass shell"
alias mpe="multipass exec"
alias mpd="multipass delete -p"
alias mpp="multipass purge"
alias mpi="multipass info"
alias mpia="multipass info --all"
alias mpstoa="multipass stop --all"
alias mpsta="multipass start --all"
alias mpsu="multipass suspend"
alias mpsua="multipass suspend --all"
```

As an example, this will make it easy to connect to a node as so:

```shell
% mps ub18fs01
```

or get information on the node

```shell
% mpi ub22ml01
Name:           ub22ml01
State:          Running
IPv4:           192.168.64.15
Release:        Ubuntu 22.04.1 LTS
Image hash:     465254c8a247 (Ubuntu 22.04 LTS)
Load:           0.00 0.00 0.00
Disk usage:     3.0G out of 4.7G
Memory usage:   423.8M out of 963.3M
Mounts:         --
```


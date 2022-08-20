# mptools

A set of utility script for MacOS to both install `multipass` and create `multipass` 
nodes initialized from a cloud config file. 

## Current version
v1.0.0

# <TL/DR>

***Note: Make sure you have [homebrew](https://brew.sh/)  installed.*** 

1. If you do do not already have `multipass` then Install `multipass` by running
    ```shell
   ./mpinstall.sh
   ```   
     
2. Add the following to your `.zshenv` 
    ```shell
    export SSH_PUBLIC_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
    ```
   and source your `.zshenv` file.    
    
3. Create and start the three default nodes `ub18n01`, `ub20n01`, and `ub22n01` by
   running the makefile as 
    ```shell
    make nodes
    ```


## Installing multipass
The first step is to install `multipass`. This can be done by using the first
included script:

```shell
./mpinstall.sh
```

This will install `multipass` on a MacOS (both M1 and Intel). On Intel it will also
replace the default *hyperkit* virtualization with *qemu*. In addition, it will add 
a number of aliases (in your `~/.zshenv` file) to make it easier to manage and start
nodes.

## Creating basic nodes with the help of Makefile
By using a basic naming convention for the nodes they can be easily created from
different base images that are configured with selected cloud-init files.

node Naming convention:  **ub**<MAJOR_RELEASE>**n**<NODE_NUMBER>

In order to create nodes a [Cloud-Init file](https://cloudinit.readthedocs.io/en/latest/) is needed to specify how the node 
should be setup. The tool set includes three variants

1. `cloud-fulldev-config.in`, A full C/C++ dev environment
2. `cloud-minidev-config.in`, A minimal c/C++ dev environment
3. `cloud-mini-config.in`, A minimal node with only user and SSH keys

The cloud init files are created from a template `*.ini` 
with the help of a makefile
to produce the corresponding `*.yaml` files that in turn aer used to configure the nodes. 

In order to make
it easier to use SSH to access the nodes the current users public SSH key will be included
in the produced `*.yaml` file. 

It is assumed that the environment variable `${SSH_PUBLIC_KEY}` exists. It can for example
be added in `~/.zshenv` as

```shell
export SSH_PUBLIC_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
```

The processed `*.yaml` is created by calling

```shell
$>  make
```

If you also want to create nodes you can call


```shell
$>  make nodes
```

By default, the following three nodes are then prepared

 - ub18n01 (Based on "bionic", a.k.a Ubuntu 18 LTS )
 - ub20n01 (Based on "focal", a.k.a Ubuntu 20 LTS )
 - ub22n01 (Based on "jammy", a.k.a Ubuntu 22 LTS )

These nodes are created with a full development environment based on the
cloud init template `cloud-fulldev-config.in` which installs a complete C/C++ development environment
with some commonly used libraries. 

If more nodes are needed they can be created easily by using the makefile with some 
environment variables as 

```shell
make -n ALL_NODES="ub22n02 ub22n03" nodes
```

Which will create two more "jammy" (Ubuntu 22 LTS) nodes. **Please note that the naming convention 
must be followed**


## Creating customized nodes

The previous described method using the makefile is easy but lacks ability to adjust node "hw" configuration
such as memory, disc etc. 

To create completely customized images the underlying tool that is used by the makefile can be used 
directly, i.e. `mkmpnode.sh`

```shell
NAME
   mkmpnode.sh
USAGE
   mkmpnode.sh [-r RELEASE] [-c FILE] [-d SIZE] [-p CPUS] [-m SIZE] [-q] [-v] [-h] NODE_NAME
SYNOPSIS
      -r RELEASE: Valid ubuntu release [bionic focal impish jammy docker]  (jammy)
      -c FILE   : Cloud config file 
      -m SIZE   : Memory size, defaults (500MB)
      -d SIZE   : Disk size, defaults (5GB)
      -p NUM    : Number of CPUs (2)
      -M        : Mount ~/Devel inside node
      -q        : Quiet  (no output to stdout)
      -v        : Print version and exit
      -h        : Print help and exit
```

For example.To create a slightly bigger node (with a custom name) to run a Jenkins instance can be created with

```shell
./mkmpnode.sh -m 1GB -jenkins
```

This will create (and start) a new node with 1GB memory named "jenkins" 

## Aliases

After the install-script has been run the following shell aliases will be available
to save some typing.

```shell
alias mp="multipass"
alias mpl="multipass list"
alias mps="multipass shell"
alias mpe="multipass exec"
alias mpd="multipass delete -p"
alias mpp="multipass purge"
alias mpi="multipass info"
alias mpia="multipass info --all"
```

These can of course e also be added manually.
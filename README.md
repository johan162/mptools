# mptools

A set of utility script for MacOS to both install `multipass` and create `multipass` 
nodes initialized from a cloud config file. 

# <TL/DR>

Do the following to install `multipass` and create the default nodes.

>***Pre-requisite: Make sure you have [homebrew](https://brew.sh/)  installed and 
that the current user have a set of SSH keys.*** 

1. If `multipass` is not already installed then Install `multipass` by running
    ```shell
   ./mpinstall.sh
   ```    
   **Note:** If `multipass` is already installed a warning will be printed.   
   **Note:** The installation script will also add SSH_PUBLIC_KEY environment variable
   needed for proper cloud init file configuration.   


2. Create and start the default three default nodes `ub18n01`, `ub20n01`, and `ub22n01` by
   running the makefile as 
    ```shell
    make nodes
    ```
   It is possible to customize the nodes created by either editing the `$ALL_NODES` variable
   in the makefile or override it on the command line. So, for example to only create two
   Ubuntu 22 LTS nodes use:

   ```shell
    make ALL_NODES="ub22n01 ub22n02" nodes
    ```

   The equivalent to create, for example, three Ubuntu 20 LTS nodes would be
   ```shell
    make ALL_NODES="ub20n01 ub20n02 ub20n03" nodes
    ```

    **Note:** Please observe the naming convention so the script can figure out
    the type of node to create. 

# Installing multipass
The first step is to install `multipass`. This can be done by using the first
included script:

```shell
./mpinstall.sh
```

This will install `multipass` on a MacOS (both M1 and Intel). On Intel architecture it will also
replace the default *hyperkit* virtualization with *qemu*. In addition, it will add 
a number of aliases (in the `~/.zshenv` file) to make it easier to manage and start
nodes. See the section *Aliases*

The script will automatically detect if `multipass` have already been installed, and 
hence can be considered idempotent.

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
to produce the corresponding `*.yaml` files that in turn are used to configure the nodes. 

   > Note: Customized nodes is most easily created with the `mkmpnode.sh` as described below.

In order to make
it easier to use SSH to access the nodes the current users public SSH key will be included
in the produced `*.yaml` file. 

It is assumed that the environment variable `${SSH_PUBLIC_KEY}` exists. It can for example
be added in `~/.zshenv` as

```shell
export SSH_PUBLIC_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
```

> Note: If the `mpinstall.sh` install script have been used this will be automatically added

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
make ALL_NODES="ub22n02 ub22n03" nodes
```

Which will create two more "jammy" (Ubuntu 22 LTS) nodes. **Please note that the naming convention 
must be followed**


# Creating customized nodes with `mkmpnode.sh`

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

Most options should be self-explanatory but the `-M` deserves a comment. If the users
home catalogue have a directory `~/Devel` it will be mounted automatically in the node.

> **Note:** The dev nodes created with the supplied dev Cloud-Init templates will also have
a directory `/var/jenkins_home` in order for the nodes to be used as Jenkin agents.

Let's illustrate the usage with a basic example. We are going to create a node with a 
custom name and more memory than default in order to run a Jenkins instance in the node

```shell
./mkmpnode.sh -m 1GB jenkins
```

This will create (and start) a new node with 1GB memory named "jenkins" .

# Aliases

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

As an example, this will make it easy to connect to a node:

```shell
$> mps ub18n01
```

or get information on the node

```shell
$> mpi jenkins
Name:           jenkins
State:          Running
IPv4:           192.168.64.15
Release:        Ubuntu 22.04.1 LTS
Image hash:     465254c8a247 (Ubuntu 22.04 LTS)
Load:           0.00 0.00 0.00
Disk usage:     3.0G out of 4.7G
Memory usage:   423.8M out of 963.3M
Mounts:         --
```



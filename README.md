# mptools

A set of utility script for MacOS to both install `multipass` and create `multipass` 
nodes initialized from a cloud config file. The nodes can be created with the 
included Makefile based on a simple naming convention that controls both how they
are instantiated and the size of the virtual machine. 


# <TL;DR>

Do the following to install `multipass` with the help of one of the utility scripts included
and create the default (pre-defined) nodes.

>***Pre-requisite: Make sure you have [homebrew](https://brew.sh/)  installed and 
that the current user have a set of SSH keys.*** 

&nbsp;

1. If `multipass` is not already installed then Install `multipass` by running
    ```shell
   ./mpinstall.sh
   ```    
   **Note:** If `multipass` is already installed a warning will be printed.   
   **Note:** The installation script will also add SSH_PUBLIC_KEY environment variable
   needed for proper cloud init file configuration.   


2. Create and start the default three default nodes `ub18fs01`, `ub20fs01`, and `ub22fs01` by
   running the provided makefile as so
    
    ```shell
    make node
    ```
   See section [Naming convention for automatic node creation](#naming-convention-for-automatic-node-creation)
for explanation on how to interpret the node names.

# Content
- ### [Installing multipass](#installing-multipass)
- ### [Creating customized nodes](#creating-customized-nodes)
- ### [Creating nodes using naming convention](#creating-nodes-using-naming-convention)
- ### [Aliases](#aliases)
- ### [Tips and Tricks](#tips-and-tricks)



# Installing multipass
| [back to content table](#content) |

The first step is to install `multipass`. This can be done by using the first
included script:

```shell
./mpinstall.sh
```

This will install `multipass` on a MacOS (both M1 and Intel). On Intel architecture it will also
replace the default *hyperkit* virtualization with *qemu*. In addition, it will add 
a number of aliases to the `~/.zshenv` file to make it easier to manage and start
nodes. See the section *Aliases* for a detailed description.

The script will automatically detect if `multipass` have already been installed, and 
hence can be considered idempotent.


# Creating customized nodes
| [back to content table](#content) |

The core script of `mptool` is the script ample called `mkmpnode.sh` which can be seen as a
wrapper around the core `multipass launch` command to make creating and launching nodes with
the help of pre-defined cloud init files easier by using a set of predefined cloud-init 
template files.

```text
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
home catalogue have a directory `~/Devel` it will be mounted automatically in the node directly
under the default users (`ubuntu`) home directory.

> **Note:** The dev nodes created with the supplied dev Cloud-Init templates will also have
a directory `/var/jenkins_home` created in order for the nodes to be used as Jenkins agents.


## Cloud init files
As mentioned in the previous section `mkmpnode.sh` uses cloud-init files to configure
the created nodes. Cloud init files are written as human-readable YAML files.

> *It is out of the scope of this readme to fully describe he full syntax
> of cloud-init files.   
> Instead, we refer to the official 
> home of the cloud-init project [cloud-init.io](https://cloud-init.io/) 
> and the description of [Cloud-Init files](https://cloudinit.readthedocs.io/en/latest/).*

This toolset includes a few cloud-init templates, they are all stored in the `cloud/` folder.
As of this writing the following templates are provided

1. `cloud/fulldev-config.in`, A full C/C++ dev environment
2. `cloud/minidev-config.in`, A minimal c/C++ dev environment
3. `cloud/mini-config.in`, A minimal node with only user and SSH keys
4. `cloud/jenkins-config.in`, A basic Jenkins node

In order to instantiate these templates to usable yaml-files it is assumed that 
the environment variable `${SSH_PUBLIC_KEY}` exists and 
contains the current users public ssh key. It can for example
be added in `~/.zshenv` as

```shell
export SSH_PUBLIC_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
```

> Note: If the `mpinstall.sh` install script have been used this has been automatically added

In order to expand the provided templates to their corresponding  `*.yaml` yaml files a
provided makefile exists. 
Move into the `mptools` directory. Then instantiate the cloud-init files as so:

```shell
$>  make
```

This will create all the `*.yaml` files from the corresponding `*.in` files . The
created files will have the current users public SSH keys and user-name inserted.

The installed SSH keys will make it easier for tools and "manual" access to the 
created nodes by simple ssh:ing into the nodes.

>**Note:** New cloud file templates can be easily added by for example
> copying an existing file to a new name and making modifications. 
> The makefile will automatically
> pick up any new template files in the cloud directory and include them
> when instantiating cloud-init YAML files.


## Examples of creating custom nodes 
We will start by illustrating how new nodes can be easily created with the help
of the supplied `mkmpnode.sh` script and later on we will show how the same
process can be simplified and automated with the supplied makefile by using a strict 
schema on how ti name the nodes.

To execute these examples it is assumed that the cloud-init YAML files have been 
instantiated with a call to `make`.

First we are going to create a node with a  custom name and more memory than default 

```shell
./mkmpnode.sh -m 1GB mynode
```

This will create (and start) a new node with 1GB memory named "mynode" and initialized 
by the default cloud-init configuration which is set to `minidev-config.yaml` in the script.

By default, the created nodes will be based on the latest Ubuntu image (i.e. Ubuntu 22 a.k.a. "jammy"
at the time of writing)
but if we instead wanted to create an even larger node, based on Ubuntu18 with a full development 
configuration we would instead need to call

```shell
./mkmpnode.sh -r bionic -m 4GB -c cloud/fulldev-config.yaml -d 10GB mynode
```

This will create a node with 4GB RAM and a 10GB disk based on Ubuntu 18 (i.e. "bionic")


# Creating nodes using naming convention
| [back to content table ](#content)|

The previous section showed how nodes could be manually created by giving a few
parameters to the `mkmpnode.sh` script. However, there is an easier way. By using the
supplied makefile it is possible to create nodes without giving all the parameters
but instead just give the node a very specific name.

This is based on a simple node naming schema where the node name itself
specify what base image and what cloud init configuration and 
machine size should be used as explained below.

## Naming convention for automatic node creation 

**ub**&lt;MAJOR_RELEASE>&lt;CONFIG>&lt;SIZE>&lt;NODE_NUMBER>

* **&lt;MAJOR_RELEASE>**   
One of :
    * 18 (="bionic") 
    * 20 (="focal")
    * 22 (="jammy")  
&nbsp;
* **&lt;CONFIG>**  
One of :
    * **b** (=Basic node, no dev tools)  
      Based on: `cloud/mini-config.yaml` 
    * **f** (=Full dev node)  
      Based on: `cloud/fulldev-config.yaml`
    * **m** (=Minimal dev node)  
      Based on: `cloud/minidev-config.yaml`  
&nbsp;
* **&lt;SIZE>**  
One of :
    * **s** (Small=500MB RAM/5GB Disk)
    * **m** (Medium=1GB RAM/5GB Disk)
    * **l** (Large=2GB RAM/10GB Disk)
    * **x** (X-Large=4GB RAM/15GB Disk)
    * **h** (Humungous=8GB RAM/20GB Disk)  
&nbsp;
* **&lt;NODE_NUMBER>**   
This can be arbitrarily chosen to avoid name conflicts since  all node names must be unique. 

Examples of valid names is then
- ub20bl01 - A Ubuntu 20 image, basic cloud config, large machine size
- ub18fm01 - A Ubunto 18 image, full development setup, medium machine size

In the following section we will show ho to practically use this naming convention with
the supplied makefile.

## Examples of creating nodes using name convention

The make file is used as the driver to create these nodes. By default,
the makefile have three nodes predefined which are created as so

```shell
$>  make node
```

the following three nodes are then prepared

 - ub18fs01 (Based on "bionic", a.k.a Ubuntu 18 LTS )
 - ub2fs01 (Based on "focal", a.k.a Ubuntu 20 LTS )
 - ub22fs01 (Based on "jammy", a.k.a Ubuntu 22 LTS )

As their names suggest these nodes are created with a full development environment based on the
cloud init template `cloud/fulldev-config.in` 
which installs a complete C/C++ development environment
with some of the most commonly used libraries. All the created machines are small.

In order to create a custom set of nodes then the node names can be supplied
as argument (recommended) or one can of course update the default target 
in the makefile.

Assume that we instead wanted to create two large Ubuntu 22 nodes with full
development configuration and one
X-Large Ubuntu 18 node with just the minimal dev environment. We can then
override the `$(NODES)` makefile variable on the command line as so

```shell
make NODES="ub22fl11 ub22fl12 ub18mx13" node
```
The makefile will in the background make th following three calls to the 
actual node creating script

```shell
./mkmpnode.sh -r jammy -c cloud/fulldev-config.yaml -m 2GB -d 10GB ub22fl11
./mkmpnode.sh -r jammy -c cloud/fulldev-config.yaml -m 2GB -d 10GB ub22fl12
./mkmpnode.sh -r bionic -c cloud/minidev-config.yaml -m 4GB -d 15GB ub18mx13
```

Which will create two more large "jammy" (Ubuntu 22 LTS) nodes and 
one x-large "bionic" (Ubuntu 18 LTS) node. 

It should now be obvious how to create custom nodes using the node-naming method
together with the makefile.

## Additional makefile targets

- **clean** - Delete all generated files
- **distclean** - In addition to **clean** also remove any created distribution tar-ball
- **dist** - Create a distribution tar ball

# Aliases
| [back to content table ](#content)|

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
alias mpstoa="multipass stop --all"
alias mpsta="multipass start --all"
alias mpsu="multipass suspend"
alias mpsua="multipass suspend --all"
```

These can of course also be added manually. 

As an example, this will make it easy to connect to a node as so:

```shell
$> mps ub18fs01
```

or get information on the node

```shell
$> mpi ub22ml01
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

# Tips and Tricks
| [back to content table ](#content)|


* The logfile when creating and starting nodes are stored at  
  `/Library/Logs/Multipass/multipassd.log` and is helpful when debugging why a node
  will for example not start.  
  &nbsp;
* When you create many nodes the assign dynamic ip (192.168.64.xxx) can sometimes need to
  be reset. This is most easily done byt first stopping all instances and then delete the
  file `/var/db/dhcpd_leases`  
  &nbsp;
* Never ever use a `systemctl daemon-reload` in a cloud-init file. This will kill the SSH daemon
  and the multipass connection to the starting node will be lost.




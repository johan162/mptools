# mptools

A set of utility scripts for macOS to both install `multipass` (with adaptations) and create `multipass` 
nodes initialized with the help of cloud config files. The scripts allow for several
levels of usage depending on needs.

In its simplest form (after installing) nodes can be created using a naming convention
that specifies how to initialize the node as well as (some of) the specification for
the virtual machine such as RAM and disk.

So, for example to create two medium-sized nodes with a full C/C++ development environment
with common libraries and a GNU C/C++ toolchain based on Ubuntu 22 LTS one would do as so:

```shell
% ./mpn.sh ub22fm01 ub22fm02
```

If we instead had wanted small nodes based on Ubuntu 18 LTS
with a minimal C/C++ development environment we would do as so:


```shell
% ./mpn.sh ub18ms01 ub18ms02
```

The naming convention used is thoroughly documented below in section [Node naming convention](#node-naming-convention).


# <TL;DR>

Do the following to install `multipass` with the help of one of the utility scripts included
and create the default (pre-defined) nodes.

>***Pre-requisite: Make sure you have [homebrew](https://brew.sh/)  installed and 
that the current user have a set of SSH keys.*** 

&nbsp;

1. If `multipass` is not already installed then Install `multipass` by running

    ```shell
   % ./mpinstall.sh
   ```    
   **Note:** If `multipass` is already installed a warning will be printed.   
   **Note:** The installation script will also add `SSH_PUBLIC_KEY` environment variable
   since that is needed for proper cloud init file configuration.   
   &nbsp;

2. To create customized nodes use the wrapper script `mpn.sh` ("**M**ultipass-**N**ode") 
with specified node names according to the node-naming specifications. 
See section [Node naming convention](#node-naming-convention)
for a detailed explanation on how to define the node names.   
&nbsp;  
    An example will illustrate the simple convention used:
    
    ```shell
    % ./mpn.sh ub20fl01 u18ms01
    ```  
   This will after roughly 2-3 minutes create two nodes named `ub20fl01` and `ub20ms01`.  
   &nbsp;  
   - The name `ub20fl01` itself specifies how the node should be created.  
   This will create an Ubuntu 20 LTS 'large' node (the middle `l` )  
   configured as a full development nodes (the middle `f`). The ending `01` is just a sequence number
   to make the node names unique.  
   &nbsp;  
   - The second node `ub18ml01` will be created as an Ubuntu 18 LTS 'small' node (the middle `s` )
   configured as a minimum development node (the middle `m`).
   &nbsp;

The rest of this README will discuss all scrips and option more in detail.


# Content
- [Installing multipass](#installing-multipass)
- [Creating customized nodes](#creating-customized-nodes)
  - [Cloud init files](#cloud-init-files) 
  - [Examples of creating custom nodes](#examples-of-creating-custom-nodes)
- [Creating nodes using make](#creating-nodes-using-make)
  - [Node naming convention](#node-naming-convention)
  - [Examples of using the Makefile directly](#examples-of-using-the-makefile-directly)
  - [All makefile targets](#all-makefile-targets)
- [Using wrapper script to create nodes](#using-wrapper-script-to-create-nodes)
- [Aliases](#aliases)
- [Tips and Tricks](#tips-and-tricks)



# Installing multipass
| [back to content table](#content) |

The first step is to install `multipass`. This can be done by using the first
included script:

```shell
% ./mpinstall.sh
```

This will install `multipass` on a macOS (both M1 and Intel). On Intel architecture it will also
replace the default *hyperkit* virtualization with *qemu* since this driver will more allow
the modification of existing machine to, say, adjust the memory size. 

In addition, the script will add 
a number of aliases to the `~/.zshenv` file to make it easier to manage and start
nodes. See the section *Aliases* for a detailed description. As a final step it will also
add an environment variable to hold the current users public SSH key to make it possible
to use SSH to log in to the created nodes as the environment variable `SSH_PUBLIC_KEY`.

The script will automatically detect if `multipass` have already been installed, and 
hence can be considered idempotent.


# Creating customized nodes
| [back to content table](#content) |

One of the scripts of the `mptool` package  is the script ample called `mkmpnode.sh` which can 
be seen as a
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
5. `cloud/pg-config.in`, A basic Postgresql node

In order to instantiate these templates to usable yaml-files it is assumed that 
the environment variable `${SSH_PUBLIC_KEY}` exists and 
contains the current users public ssh key. It can for example
be added in `~/.zshenv` as

```shell
export SSH_PUBLIC_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
```

> Note: If the `mpinstall.sh` install script have been used this has been automatically added

In order to expand the provided templates to their corresponding  `*.yaml` yaml file a
provided makefile exists. 
To use this first move into the `mptools` directory. 
Then, instantiate the cloud-init files as so:

```shell
%  make
```

This will create all the `*.yaml` files from the corresponding `*.in` files . The
created files will have the current users public SSH keys and user-name inserted.

The installed SSH keys will make it easier for tools and "manual" access to the 
created nodes by simple ssh:ing into the nodes.

>**Note:** New cloud file templates can be easily added by, for example,
> copying an existing file to a new name and making modifications. 
> The makefile will automatically
> pick up any new template files in the cloud directory and include them
> when instantiating cloud-init YAML files.


## Examples of creating custom nodes 
| [back to content table ](#content)|

We will start by illustrating how new nodes can be easily created with the help
of the supplied `mkmpnode.sh` script and later on we will show how the same
process can be simplified and automated with the supplied makefile by using a strict 
schema on how ti name the nodes.

To execute these examples it is assumed that the cloud-init YAML files have been 
instantiated with a call to `make`.

First we are going to create a node with a  custom name and more memory than default 

```shell
% ./mkmpnode.sh -m 1GB mynode
```

This will create (and start) a new node with 1GB memory named "mynode" and initialized 
by the default cloud-init configuration which is set to `minidev-config.yaml` in the script.

By default, the created nodes will be based on the latest Ubuntu image (i.e. Ubuntu 22 a.k.a. "jammy"
at the time of writing)
but if we instead wanted to create an even larger node, based on Ubuntu18 with a full development 
configuration we would instead need to call

```shell
% ./mkmpnode.sh -r bionic -m 4GB -c cloud/fulldev-config.yaml -d 10GB mynode
```

This will create a node with 4GB RAM and a 10GB disk based on Ubuntu 18 (i.e. "bionic")

### Setting up a Postgresql DB-server
One of the cloud-init files allow for easy setup of a postgresql server.
This server needs to be created by the `mkmpnode.sh` script since the node naming convention
has no concept of a DB server.

The cloud init file will set up a basic postgres server with some password as specified in the
cloud init file os it is most definitely only for experiments and tests. See table below.


| User/DB Owner | Password | DB        |
|---------------|----------|:----------|
| postgres      | postgres | postgres  |
| ubuntu        | ubuntu   | ubuntu_db |
Table: Default roles/users created by pg-config.in

To create a Postgresql server (assuming the cloud yaml file have previously been instantiated with a call to `% make` ) where we assume we need 2GB of RAM we would call

```shell
 % ./mkmpnode.sh -c cloud/pg-config.yaml -m 2GB db-server
```

The default postresql cloud file will set up the access permission to the server
so it is accessible from the outside
and also create a new user "ubuntu" with default password "ubuntu" and a new DB `ubuntu_db` (for experiments)
The TCP/IP access restriction is set to `"samenet"` any access must be from the same 
subnetwork that we are currently on (e.g. from another MP node or from the host).


# Creating nodes using make
| [back to content table ](#content)|

The previous section showed how nodes could be manually created by giving a few
parameters to the `mkmpnode.sh` script. However, there is an easier way. By using the
supplied makefile it is possible to create nodes without giving all the parameters
but instead just give the node a very specific name.

> There is also a wrapper script `mpn.sh` described in the next section that slightly 
> simplifies the calling to `make`

This is based on a simple node naming schema where the node name itself
specify what base image and what cloud init configuration and 
machine size should be used as explained below.

## Node naming convention 
| [back to content table ](#content)|

```text
ub&lt;MAJOR_RELEASE>&lt;CONFIG>&lt;SIZE>&lt;NODE_NUMBER>
```

<table>
    <caption>Designators in node naming</caption>
    <thead>
        <tr>
            <th>&lt;MAJOR_RELEASE></th>
            <th>&lt;CONFIG></th>
            <th>&lt;SIZE></th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td valign="top"><ul><li>18 (="bionic")</li><li>20 (="focal")</li><li>22 (="jammy")</li></ul></td>
            <td valign="top"><ul><li>b &nbsp;(=Basic node, no dev tools),<br/>`cloud/mini-config.yaml`<br/>&nbsp;</li><li>f  &nbsp;(=Full dev node), <br/>`cloud/fulldev-config.yaml`<br/>&nbsp;</li><li>m  &nbsp;(=Minimal dev node),<br/>`cloud/minidev-config.yaml`<br/>&nbsp;</li></ul></td>
            <td valign="top"><ul><li>s &nbsp;(Small=500MB RAM/5GB Disk)</li><li> m &nbsp; (Medium=1GB RAM/5GB Disk)</li><li>l &nbsp; (Large=2GB RAM/10GB Disk)</li><li>x &nbsp; (X-Large=4GB RAM/15GB Disk)</li><li>h &nbsp; (Humungous=8GB RAM/20GB Disk)</li></ul></td>
        </tr>
    </tbody>
</table>


**&lt;NODE_NUMBER>**   
Arbitrarily chosen to avoid name conflicts since  all node names must be unique. 

Some examples of valid names are:

- ub20bl01 - A Ubuntu 20 image, basic cloud config, large machine size
- ub18fm01 - A Ubuntu 18 image, full development setup, medium machine size
- ub22mx12 - A Ubuntu 22 image, minimal development setup, x-large machine size

In the following section we will show ho to practically use this naming convention with
the supplied makefile.

>***Note:***   
> *All nodes will have 2 CPUs. If more CPUSs are needed then the nodes must be
created with the `mkmpnode.sh` directly using the `-p` option.*

## Examples of using the Makefile directly
| [back to content table ](#content)|

>**Note:** The easier way is to use the  wrapper script `mpn.sh` as
> described in section [Using wrapper script to create nodes](#using-wrapper-script-to-create-nodes)
> that uses this `Makefile` "under the hood".

The makefile is used as the driver to create these named nodes. By default,
the makefile have three nodes predefined which are created as so

```shell
% make node
```

the following three default nodes are then prepared:

 - ub18fs01 (Based on "bionic", a.k.a Ubuntu 18 LTS )
 - ub20fs01 (Based on "focal", a.k.a Ubuntu 20 LTS )
 - ub22fs01 (Based on "jammy", a.k.a Ubuntu 22 LTS )

In order to build all nodes in parallel use the usual `-j` option to make. 
So for example to build up to four nodes in parallel call

```shell
% make -j4 node
```


As their names suggest these nodes are created with a full development environment based on the
cloud init template `cloud/fulldev-config.in` which installs a complete C/C++ development 
environment with some of the most commonly used libraries. All created machines are small.

In order to create a custom set of nodes the node names can either:

1. be supplied  as overridden makefile variables  (recommended) or
2. be setup by changing the $(NODES) makefile variable in the makefile 

An example will clarify this.

Assume that we instead wanted to create two large Ubuntu 22 nodes with full
development configuration and one X-Large Ubuntu 18 node with just the 
minimal dev environment. We can then  override the `$(NODES)` makefile 
variable on the command line as so

```shell
% make NODES="ub22fl11 ub22fl12 ub18mx13" node
```

The makefile will "under the hood" then make the following three calls to the 
actual node creating script

```shell
./mkmpnode.sh -r jammy -c cloud/fulldev-config.yaml -m 2GB -d 10GB ub22fl11
./mkmpnode.sh -r jammy -c cloud/fulldev-config.yaml -m 2GB -d 10GB ub22fl12
./mkmpnode.sh -r bionic -c cloud/minidev-config.yaml -m 4GB -d 15GB ub18mx13
```

Which will create two more large "jammy" (Ubuntu 22 LTS) nodes and 
one x-large "bionic" (Ubuntu 18 LTS) node exactly as the node names 
specified.

Again, use `-j` to build nodes in parallel.

It should now be obvious how to create custom nodes using the node-naming method
together with the makefile.

## All makefile targets
| [back to content table ](#content)|

- **all** - The default target that will instantiate all `*.yaml` files from the 
corresponding `*.in` templates.
- **node** - Create the nodes specified by the `$(NODES)` makefile variable 
(which can as usual be overridden on the command line)
- **clean** - Delete all generated files
- **distclean** - In addition to **clean** also remove any created distribution tar-ball. 
Restores the `mptools` directory as distributed and should be called before a release
is built.
- **dist** - Create a distribution tar ball

# Using wrapper script to create nodes
| [back to content table ](#content)|

In the section above we showed how to create nodes "manually" calling the makefile
directly. To further simplify this a small wrapper script `mpn.sh`
("**M**ultipass-**N**ode") exists. 

```text
NAME
   mpn.sh
USAGE
   mpn.sh [-h] [-v] [-s] NODE_NAME [NODE_NAME [NODE_NAME ... ]]
SYNOPSIS
      -h        : Print help and exit
      -s        : Silent
      -v        : Print version and exit
```

To create nodes one simply specifies one or more nodes using the previous discussed naming
format as arguments as so:

```shell
% ./mpn.sh ub18fs01 ub20ml01 ub22fl01
```

The wrapper script makes use of make's parallel options and will cut down the time to create multiple
nodes by starting up to four parallel node creations.

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

These aliases can of course also be added manually. 

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

# Tips and Tricks
| [back to content table](#content) |


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
  &nbsp;
* The cloud instantiation is recorded under `/var/lib/cloud` in the node. If a customized
node is not working this is a good place to start troubleshooting. For example, in
`/var/lib/cloud/instance/scripts/runcmd` is the run commands specified in the `RunCmd` extracted
as shell commands.




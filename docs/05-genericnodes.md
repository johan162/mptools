
# Creating generic nodes

The one reason for this package existence is to make it easy to create nodes with
cloud-init files. The main workhorse script to do so is `mkmpnode`.

```text
NAME
   mkmpnode - Create multipass nodes with a specified (or default) cloud-init file
USAGE
   mkmpnode [-r RELEASE] [-c FILE] [-d SIZE] [-p CPUS] [-m SIZE] [-q] [-v] [-h] NODE_NAME
SYNOPSIS
      -r RELEASE: Valid ubuntu release [bionic focal impish jammy docker] ($ubuntuVer)
      -c FILE   : Cloud config file (${defaultCloudInit})
      -m SIZE   : Memory size, defaults (${memory})
      -d SIZE   : Disk size, defaults (${disk}GB)
      -p NUM    : Number of CPUs (${cpus})
      -M        : Mount ${HOME}/Devel inside node
      -n        : No execution. Only display actions.
      -q        : Quiet  (no output to stdout)
      -v        : Print version and exit
      -h        : Print help and exit
```

@warning Multipass does not allow a literal underscore in node names!

Most options should be self-explanatory but the `-M` deserves a comment. If the users
home catalogue have a directory `~/Devel` it will be mounted automatically in the node directly
under the default users (`ubuntu`) home directory.

@note Use the `-n` flag to do a dryrun and see how the underlying call to `multipass`
is made without actually executing it.

## Cloud init files
As mentioned in the previous section `mkmpnode` uses cloud-init files to configure
the created nodes. Cloud init files are written as human-readable YAML files.

> *It is out of the scope of this readme to fully describe he full syntax
> of cloud-init files.   
> Instead, we refer to the official
> home of the cloud-init project [cloud-init.io](https://cloud-init.io/)
> and the description of [Cloud-Init files](https://cloudinit.readthedocs.io/en/latest/).*

This toolset includes a few cloud-init templates, they are all stored in the `cloud/` folder
in the distributed package.
As of this writing the following templates are provided:

1. `cloud/fulldev-config.in`, A full C/C++ dev environment
2. `cloud/minidev-config.in`, A minimal c/C++ dev environment
3. `cloud/mini-config.in`, A minimal node with only user and SSH keys
4. `cloud/jenkins-config.in`, A basic Jenkins node
5. `cloud/pg-config.in`, A basic Postgresql node
6. `cloud/sq-config.in`, A basic SonarQube (Static Code Analysis) node

These template cloud-init files will be used in the installation process to create
customized versions based on the current user. The generated `*.yaml` files are
stored in the user home directory under `~/.mptools`.

This instantiation will be done as part of the `make install` target.

## Manually trigger creation of cloud-init files

For experiments, it can be handy to re-generate the cloud-init file even after
they have been initially created.

Change back to the `mptools` package directory where the `Makefile` exists.
Then run the default makefile target as:

```text
%  make
Transforming cloud/fulldev-config.in --> cloud/fulldev-config.yaml
Transforming cloud/jenkins-config.in --> cloud/jenkins-config.yaml
Transforming cloud/mini-config.in --> cloud/mini-config.yaml
Transforming cloud/minidev-config.in --> cloud/minidev-config.yaml
Transforming cloud/pg-config.in --> cloud/pg-config.yaml
Transforming cloud/sq-config.in --> cloud/sq-config.yaml
```

This will add the generated `*.yaml` files (based on the current user)
together with the template files in `./cloud` directory. The
created files will have the current users public SSH keys and user-name inserted.

Please note that only files where the template files has a newer modified timestamp than any existing `*.yaml` will be re-generated. To force all `*.yaml` files to be created
regardless of timestamp first run `make clean`

The installed SSH keys in the nodes will make it easier for tools and "manual" access to the
created nodes by simple ssh:ing into the nodes.

New cloud file templates can be easily added by, for example,
copying an existing file to a new name and make modifications.
The makefile will automatically
pick up any new template files in the cloud directory and include them
when instantiating cloud-init YAML files.

## Resolving location of cloud-init files

Cloud init file is specified with the `-c` option. If no cloud file is specified
in the call to `mkmpnode.sh` the default
cloud-init file will be used, `minidev-config.yaml` . This cloud-init file installs
a minimal development environment in the node.

If the cloud init file is specified with a path then that exact file and location
will be used. If the file cannot be found this results in an error message.

If, however only a filename without path is specified then `mkmpnode`
will search for the config file in three locations in order of priority:

1. The current working directory under the subdirectory `./cloud`
2. From the subdirectory `cloud` in the same folder where the script is located.
3. In the current users home directory under '~/.mptools'

This priority order is used in roer to make it possible to experiment with new
updated cloud-init files and have these be picked up by `mkmpnode` without having
to "destroy" the original `*.yaml` files under `~/.mptools`.

If the cloud-init file cannot be found in any of these places an error will be
written and the script will abort.


## Examples of creating custom nodes

We will start by illustrating how new nodes can be easily created with the help
of the supplied `mkmpnode` script and later on we will show how the same
process can be further simplified and automated by using `mpn`

To execute these examples it is assumed that the cloud-init YAML files have been
instantiated either by being installed (`make install`) or being instantiated as
described above (with a call to the default `make` target).

First we are going to create a node with a  custom name and more memory than default

```shell
% mkmpnode -m 1GB mynode
```

This will create (and start) a new node with 1GB memory named "mynode" and initialized
by the default cloud-init configuration which is set to `minidev-config.yaml` in the script.

By default, the created nodes will be based on the latest Ubuntu image (i.e. Ubuntu 22 LTS a.k.a. "jammy"
at the time of writing).

If we instead wanted to create a larger node, based on Ubuntu 18 LTS with a full development
configuration we would instead need to call

```shell
% mkmpnode -r bionic -m 4GB -c fulldev-config.yaml -d 10GB mynode
```

This will create a node with 4GB RAM and a 10GB disk based on Ubuntu 18 (i.e. "bionic")

### Setting up a Postgresql DB-server

One of the cloud-init files allow for easy setup of a postgresql server.
This server needs to be created manually with the help of the `mkmpnode` script since the
node naming convention (used by `mpn`) has no concept of a DB server.

The cloud init file will set up a basic postgres server with the password specified in the
cloud init file. *THIS IS HIGHLY INSECURE AND IS ONLY MEANT FOR TESTING AND EXPERIMENTS!*.
See table below for the actual values.


| User/DB Owner | Password | DB        |
|---------------|----------|:----------|
| postgres      | postgres | postgres  |
| ubuntu        | ubuntu   | ubuntu_db |
Table: Default roles/users created by pg-config.in

To create a Postgresql server (assuming the cloud yaml file have previously been instantiated) where we assume we need 2GB of RAM we could for example call

```shell
 % mkmpnode -c pg-config.yaml -m 2GB db-server
```

The default postresql cloud file will set up the access permission to the server
so it is accessible from the outside
and also create a new user "ubuntu" with default password "ubuntu" and a new DB `ubuntu_db` (for experiments)
The TCP/IP access restriction is set to `"samenet"` any access must be from the same
subnetwork that we are currently on (e.g. from another MP node or from the host).


### Setting up a Jenkins server

As a final example we have included a Cloud config file to help setup a Jenkins CI/CD server. 
The default 500M memory is not enough so we need to adjust to 1GB

```shell
 % mkmpnode -c jenkins-config.yaml -m 1GB jenkins
```

The Jenkins instance can be accessed at `xxx.xxx.xxx.xxx:8080` to finalize the setup after installation
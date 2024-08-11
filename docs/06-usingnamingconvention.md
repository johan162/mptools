# Creating nodes using naming conventions

To further simplify the node creation the nodes can be
both created and specified in one call to `mpn`
("**M**ultipass-**N**odes") script. This is accomplished
by using a specific way of naming the nodes
that also instructs `mpn` exactly how those nodes should be created.

The naming convention is described in the next section.

```text
NAME
   mpn - Create multipass node by naming convention
USAGE
   mpn [-h] [-v] [-s] NODE_NAME [NODE_NAME [NODE_NAME ... ]]
SYNOPSIS
      -h        : Print help and exit
      -n        : No execution. Only display actions.
      -s        : Silent
      -v        : Print version and exit
```

To create nodes one simply specifies one or more nodes using the naming
format as arguments (see next section) for example:

```shell
% mpn ub20ml01 ub22fs01 ub24fm01
```
This will create three new nodes based on Ubuntu 20,22 and 24 LTS images.
The Ubuntu 22, and the Ubuntu 24 will both have  
a full development environment in a "small" node and "medium" node respectively.

The Ubuntu 20 based node will be a minimal development environment
in a "large" node.

When creating multiple nodes the script will kick of up to four parallel  node
creations. This greatly reduces the total build/creation time.

## Node naming convention

```text
ub<MAJOR_RELEASE><CONFIG><SIZE><NODE_NUMBER>
```

### MAJOR_RELEASE

* `20` (="focal")
* `22` (="jammy")
* `24` (="noble")

### CONFIG

* `b` &nbsp;(=Basic node, no dev tools). Using cloud-init file: `mini-config.yaml`
* `f` &nbsp;(=Full dev node), Using cloud-init file: `fulldev-config.yaml`
* `m` &nbsp;(=Minimal dev node), Using cloud-init file: `minidev-config.yaml`

### SIZE

* `s` &nbsp; (= Small=500MB RAM/5GB Disk)
* `m` &nbsp; (= Medium=1GB RAM/7GB Disk)
* `l` &nbsp; (= Large=2GB RAM/7GB Disk)
* `x` &nbsp; (= X-Large=4GB RAM/15GB Disk)
* `h` &nbsp; (= Humungous=8GB RAM/15GB Disk)
* `z` &nbsp; (= Zuper Humungous=12GB RAM/15GB Disk)

### NODE_NUMBER

* `nn` &nbsp; Arbitrarily chosen two digit number to avoid name conflicts since  all node names must be unique.

## Node name examples

Some examples of valid names are:

- `ub24bz01` - A Ubuntu 24 image, basic cloud config, Zuper Humungus machine size
- `ub20bl01` - A Ubuntu 20 image, basic cloud config, large machine size
- `ub22mx12` - A Ubuntu 22 image, minimal development setup, x-large machine size

&nbsp;

@note All nodes will have 2 CPUs. If more CPUSs are needed then the nodes must be
created with the `mkmpnode.sh` directly using the `-p` option.*


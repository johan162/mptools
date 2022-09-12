# README

**mptools** Is a utility package for **macOS** to help to create 
customized 
virtual machine nodes using [multipass](https://multipass.run/). 
In addition it can also help facilitate an adapted installation of **multipass** using the
`mpinstall` utility.

The customization of nodes are done through [cloud-init](https://cloud-init.io/) files. 
A set of template cloud-init 
files are provided in this package
During installed the templates
are initiated based on the current user to setup SSH keys and user names
to make it easy to access the nodes from other tools (e.g. as Jenkins nodes)

The package offers two different utilities to help with the creation of
nodes, `mpn` and `mkmpnode`. The first utility uses a basic naming convention
(similar to AWS EC2 size convention) to simplify the node creation, the second utility offers full
levels of customization to create any node setup. 

The usage of these tools are fully described in the included documentation as well
as through the `mpn -h` and `mkmpnode -h` respectively.

## Usage

### mpn
```text
% mpn -h
NAME
   mpn - Create multipass node by naming convention
USAGE
   mpn [-h] [-v] [-s] NODE_NAME [NODE_NAME [NODE_NAME ... ]]
SYNOPSIS
      -h        : Print help and exit
      -n        : No execution. Only display actions.
      -s        : Silent
      -v        : Print version and exit

The node name will control the size and capacity of the node.
ub<MAJOR_RELEASE><CONFIG><SIZE><NODE_NUMBER>
MAJOR_RELEASE=[18|20|22]
CONFIG=[f=Full dev|m=Minimal dev|b=Basic none-dev node]
SIZE=[s=small|m=medium|l=large|x=x-larg|h=humungous]
NODE_NUMBER=[0-9]{2}
```

### mkmpnode

```text
% mkmpnode -h
NAME
   mkmpnode - Create multipass nodes with a specified (or default) cloud-init file
USAGE
   mkmpnode [-r RELEASE] [-c FILE] [-d SIZE] [-p CPUS] [-m SIZE] [-q] [-v] [-h] NODE_NAME
SYNOPSIS
      -r RELEASE: Valid ubuntu release [bionic focal impish jammy docker] (jammy)
      -c FILE   : Cloud config file (minidev-config.yaml)
      -m SIZE   : Memory size, defaults (500M)
      -d SIZE   : Disk size, defaults (5GGB)
      -p NUM    : Number of CPUs (2)
      -M        : Mount /Users/ljp/Devel inside node
      -n        : No execution. Only display actions.
      -q        : Quiet  (no output to stdout)
      -v        : Print version and exit
      -h        : Print help and exit
```

## Documentation

Full documentation can be found in the `./docs` directory in the distributed tar-ball 
both HTML and PDF format as

1. (HTML) `./docs/mptools_userguide_html/index.html`
2. (PDF) `./docs/mptools_userguide.pdf`

The documentation is also available directly online in github as

1. (HTML)  [mptools User guide](https://johan162.github.io/mptools/html/index.html)  
2. (PDF)   [mptools User guide](https://johan162.github.io/mptools/mptools_manual.pdf)







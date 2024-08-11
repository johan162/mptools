# Introduction

**mptools** Is a utility package for **macOS** and **Linux** to help to create
customized virtual machine nodes using [multipass](https://multipass.run/).

The primary benefit with this tool are:

1. the support for creating nodes both with pre-defined
and customized cloud specification files. [cloud-init](https://cloud-init.io/) files is a standardized specification 
of generic cloud environment nodes not specific to multipass.
2. The easy-to-use naming convention of specifying new nodes which automatically creates the wanted node with the 
right setup without the need to remember tens of command line options to multipass.
3. The tools will be setup with the current users public SSH keys to make it painless to SSH into the nodes 

The customization of nodes are primarily done through [cloud-init](https://cloud-init.io/) files.
A set of template cloud-init files are provided in this package.

During installation (via `make install`) the templates are initiated based on the 
current user to setup SSH public keys and username to make accessing the nodes very easy.
For example by SSH:ing into them without a password. 













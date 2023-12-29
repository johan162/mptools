# Introduction

**mptools** Is a utility package for **macOS** and **Linux** to help to create
customized virtual machine nodes using [multipass](https://multipass.run/).

The customization of nodes are done through [cloud-init](https://cloud-init.io/) files.
A set of template cloud-init files are provided in this package.

During installation (via `make install`) the templates are initiated based on the 
current user to setup SSH public keys and user name to make accessing the nodes very easy.
For example by SSH:ing into them without a password.













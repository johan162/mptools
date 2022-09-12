# Introduction

**mptools** Is a utility package for **macOS** and **Linux** to help to create
customized virtual machine nodes using [multipass](https://multipass.run/).

In addition it can also help facilitate an adapted installation of **multipass** using the
`mpinstall` utility on **macOS**

The customization of nodes are done through [cloud-init](https://cloud-init.io/) files.
A set of template cloud-init
files are provided in this package.

During installed the templates
are initiated based on the current user to setup SSH keys and user name
to make it easy to access the nodes from other tools (e.g. as Jenkins nodes) by
simply SSH'ing into the node.











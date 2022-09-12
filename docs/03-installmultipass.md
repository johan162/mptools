# Installing multipass

The easiest way to install `multipass` is to use the provided script `mpinstall`.

```text
NAME
   mpinstall.sh - Install multipass and adjust default driver
USAGE
   mpinstall.sh [-v] [-h] [-n]
SYNOPSIS
      -h        : Print help and exit
      -n        : No execution. Only display actions.
      -v        : Print version and exit
```

To install `multipass` call

```shell
% mpinstall
```

This will install `multipass` on a macOS (both M1 and Intel). On Intel architecture it will also
replace the default *hyperkit* virtualization driver with *qemu* driver since this driver will more allow
the modification of existing machine to, say, adjust the memory size.

In addition, the script will add
a number of aliases to the `~/.zshenv` file to make it easier to manage and start
nodes. See the section [Aliases](#aliases) for a detailed description.

The script will automatically detect if `multipass` have already been installed, and
hence can be considered idempotent.



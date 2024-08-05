# Creating nodes using make

@note This is only documented in order ot explain some
"advanced" concept in the makefile, mostly for historic reasons
and for those interested in novel usage of makefiles.
It is recommended to use the `mpn` script instead

The previous section showed how nodes could be manually created by giving a few
parameters to the `mkmpnode` script as well as the simplified method with
`mpn` using a strict naming convention of the nodes.

The makefile was the original method of creating nodes and for historic reason
we finish with a short description of how the this method works.

The makefile method is functionally almost identical to the method
with specifically named nodes with `mpn` as described above.

This is done with the makefile target `node`.

## Examples of using the Makefile directly

The makefile is used as the driver to create these named nodes. By default,
the makefile have three nodes predefined which are created as so

```shell
% make node
```

the following three default nodes are then prepared:

- ub18fs01 (Based on "bionic", a.k.a Ubuntu 18 LTS )
- ub20fs01 (Based on "focal", a.k.a Ubuntu 20 LTS )
- ub22fs01 (Based on "jammy", a.k.a Ubuntu 22 LTS )
- ub24fs01 (Based on "noble", a.k.a Ubuntu 24 LTS )

In order to build all nodes in parallel use the usual `-j` option to make.
So for example to build up to four nodes in parallel call

```shell
% make -j4 node
```

As their names suggest these nodes are created with a full development environment based on the
cloud init template `fulldev-config.in` which installs a complete C/C++ development
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

## Makefile targets

| Target      | Purpose                                                                                              |
|-------------|------------------------------------------------------------------------------------------------------|
| `all`       | The default target that will instantiate all `*.yaml` files from the corresponding `*.in` templates. |
| `node`      | Create the nodes specified by the `$(NODES)` makefile variable                                       |
| `clean`     | Delete all generated files                                                                           |
| `distclean` | In addition to `clean` also remove any created distribution tar-ball.                                |
| `dist`      | Create a distribution tar ball                                                                       |
| `install`   | Install the package (by default `/usr/loca` is used as prefix)                                       |
| `uninstall` | Uninstall the package                                                                                | 
| `_dbg`      | Print all Makefile variables                                                                         | 
| `docs`      | Generate documentation                                                                               |


# Installing mptools

It is recommended to download an official release (or use a tagged version in the repo)
as there is no guarantee that the latest `main` branch is ready for deployment
since that by definition is work in progress.

1. Download, unpack and install the latest tar-ball `mptools-x.y.z.tar.gz`, e.g.
    ```shell
    % curl -LO https://github.com/johan162/mptools/releases/download/v2.0.1/mptools-2.0.1.tar.gz
    % tar xzf mptools-2.0.1.tar.gz
    % cd mptools-2.0.1
    % make install
    ```

   **Note:** If `curl` is not installed `wget` could be used to download the package as so
    ```shell
    %  wget -q --show-progress https://github.com/johan162/mptools/releases/download/v2.0.1/mptools-2.0.1.tar.gz
    ```

   The `make install` will install the scripts under `/usr/local/bin` . The get the
   shell autocompletion updated either the terminal have to restarted
   or call `rehash` to update the shell auto-completion hash.  
   &nbsp;  
   In addition to installing the scripts the install target will also create a hidden directory
   in the current users home directory at `~/.mptools`. In that directory a number
   of customized cloud-init files will be stored. These are customized with the
   current users public SSH key as well as also setting up user account with the
   same name as the current user in the created nodes.    
   &nbsp;  
   This setup will then make it simple to ssh into the node for example as
   `% ssh 192.168.yy.xx` (where the IPv4 address is assigned to the node)  
   &nbsp;
2. If `multipass` (see [https://multipass.run/](https://multipass.run/)) is not installed
   then this is most easily done with the utility program provided
    ```shell
    % mpinstall
    ```
   **Note:** This requires [homebrew](https://brew.sh/) to be installed and an
   error will be given if it is not installed.  
   &nbsp;

@note The scripts can also be run directly from the downloaded package directory (e.g. mptools-2.0.0).
The one thing to remember is that the script files are named with the `*.sh` suffix. When the
package is installed the symlink is the basename of the script without this suffix
to make it slightly easier to call the script.*

## Changing install location

By default, the scripts will be installed using
the prefix `/usr/local` for the installation directory.
This means that the package will be installed under `/usr/local/share`
and the binaries will be linked in `/usr/local/bin`.

This can be changed by adjusting the `INSTALL_PREFIX`
makefile variable either permanently in the `Makefile` or as an override in the call to make.
So for example, to install into `/usr/share` and `/usr/bin`, i.e using the prefix `/usr`
the following invocation would be needed:

```shell
% make INSTALL_PREFIX=/usr install
```

Remember, the same prefix has to be used when uninstalling the package, i.e.

```shell
% make INSTALL_PREFIX=/usr uninstall
```


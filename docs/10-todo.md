# ToDo

## Planned
- Update the mptools presentation for v2.x installation method


## Completed

- Add documentation to the authors github.io pages and add a link from the README.md
- Separate the README into a proper README and then the full documentation
- Add separate script to create named nodes and not use `Makefile`
- Find directory for `*.yaml` files automatically
- Create `uninstall` target

## Will not do

- Make a homebrew package with automatic installation.  
  *This turned out to be too problematic since during install `brew` shifts to the
   user `brew`. This means that `make install`  will pick up the wrong user to
   instantiate the cloud-init templates for.*
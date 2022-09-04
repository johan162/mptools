# ==============================================================================================
# Makefile to easily create customized user specific cloud init file
#
# Note is it assumed you have defined an environment variable SSH_PUBLIC_KEY
# set to your public key.
#
# This could for example be in .zshenv (or.bash_profile) as:
#      export SSH_PUBLIC_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
#
# Supported targets:
#
# (default) all     Create proper Cloud Config Files from the *.in  templates by
#                   expanding all environment variables.
#
# node	            Create and start all predefined nodes named in $(NODES)
#                   i.e. ub22n01 ub20n01 ub18n01
#
# clean	            Delete created YAML-files
#
# distclean         clean + remove created tar-ball restores the cloned repo
#
# dist              Create distribution tar ball
#
# node naming convention:  "ub<UBUNTU VERSION><CLOUD CONFIG><MACHINE SIZE><NODE NUMBER>"
#
# By using the naming convention nodes can for example be created as so:
#
#     make NODES="ub22fl01 ub22fl02 ub22fl03" node
#
# Written by: Johan Persson <johan162@gmail.com>
# All tools released under MIT License. See LICENSE file.
# ==============================================================================================

# Uncomment to run the makefile silent
# MAKEFLAGS += --silent

# Build up to four nodes in parallel
MAKEFLAGS += -j4

# Default nodes when making target "make node"
NODES := ub22fs01 ub20fs01 ub18fs01

# ================================================================================================
# Setup section

# Predefined cloud configs based on the infix in the node name
CLOUD_CONFIG_F := cloud/fulldev-config.yaml
CLOUD_CONFIG_B := cloud/mini-config.yaml
CLOUD_CONFIG_M := cloud/minidev-config.yaml

# Predefined sizes based on the infix in the node name
MACHINE_CONFIG_S := -m 500MB -d 5GB
MACHINE_CONFIG_M := -m 1GB -d 5GB
MACHINE_CONFIG_E := -m 3GB -d 5GB
MACHINE_CONFIG_L := -m 2GB -d 10GB
MACHINE_CONFIG_X := -m 4GB -d 15GB
MACHINE_CONFIG_H := -m 8GB -d 20GB

# Predefined image names corresponding to the major Ubuntu releases as specified in the node name
IMAGE_UB22 := jammy
IMAGE_UB20 := focal
IMAGE_UB18 := bionic

# Get user SSH key
SSH_KEY=$(shell cat $${HOME}/.ssh/id_rsa.pub)

# Record keeping for the release
PKG_NAME := mptools
DIST_VERSION := 2.0.0
DIST_DIR := $(PKG_NAME)-$(DIST_VERSION)
MAKEFILE_DIR := $$(dirname $(firstword $(MAKEFILE_LIST)))
INSTALL_PREFIX := /usr/local
INSTALL_DIR := $(INSTALL_PREFIX)/share/$(DIST_DIR)
DISTCLOUD_DIR := $(INSTALL_DIR)/cloud
INSTALL_BINDIR := $(INSTALL_PREFIX)/bin
USER_CLOUDFILES_DIR := $${HOME}/.mptools

# Get all our defined cloud files
CLOUD_TEMPLATE_FILES := $(wildcard cloud/*.in)

# Generated cloud-init files
CLOUDINIT_FILES := $(patsubst %.in,%.yaml,$(CLOUD_TEMPLATE_FILES))

# ... and all tool files and shell scripts
SCRIPT_FILES := $(wildcard *.sh)

SCRIPT_BINFILES := $(patsubst %.sh,%,$(SCRIPT_FILES))

# Documentation
DOC_FILES := LICENSE $(wildcard *.md)

# ================================================================================================
# Rule and recipe sections

all: $(patsubst %.in,%.yaml,$(CLOUD_TEMPLATE_FILES))

node: $(NODES)

# Process *.in --> *.yaml
#	envsubst < $< > $@
%.yaml : %.in
	$(info Transforming $< --> $@)
	@sed -e 's#\$${SSH_PUBLIC_KEY}#$(SSH_KEY)#g' -e 's/\$${USER}/${USER}/g' < $< > $@

# This rule creates the given nodes according to the naming convention.
# This requires some explanation.
# We are extracting the markers for image, cloud cofig and machine size from the
# name with 'cut'. Then we create the variable name of one of the predefined variables above.
# (We need to use eval as we want the makefile variables to be evauated dynamically
# when the rule is evaluated and not in the initial parsing.)
# Finally we evaluate that variable indirectly to get the value specified above.
#
# Naming of nodes: "ub<UBUNTU VERSION><CLOUD CONFIG><MACHINE SIZE><NODE NUMBER>"
#
# We do a basic egrep that will fail the receipie if the node name doesn't follow
# the correct naming convention.

$(filter ub%,$(NODES)): $(CLOUD_CONFIG_F) $(CLOUD_CONFIG_M) $(CLOUD_CONFIG_B)
	@$$(echo "$@" | egrep -q 'ub(22|18|20)[bmf][smlexh][0-9]{2}') || (echo "Node name not in recognised format. \"ub<UBUNTUVERSION><CLOUDCONF><MACHINESIZE><NODENUMBER\">";exit 1)
	$(eval CLOUD_CONF := CLOUD_CONFIG_$(shell echo $@|cut -c 5|tr  '[:lower:]' '[:upper:]'))
	$(eval MACHINE_SIZE := MACHINE_CONFIG_$(shell echo $@|cut -c 6|tr  '[:lower:]' '[:upper:]'))
	$(eval IMAGE := IMAGE_UB$(shell echo $@|cut -c 3-4|tr  '[:lower:]' '[:upper:]'))
	$(MAKEFILE_DIR)/mkmpnode.sh -n -r $($(IMAGE)) -c $($(CLOUD_CONF)) $($(MACHINE_SIZE)) $@ > /dev/null

clean:
	rm -rf $(patsubst %.in,%.yaml,$(CLOUD_TEMPLATE_FILES))

distclean: clean
	rm -rf $(PKG_NAME)-[1-9].[1-9]*

$(DIST_DIR).tar.gz: $(SCRIPT_FILES) $(CLOUD_TEMPLATE_FILES) $(DOC_FILES)
	rm -rf $(DIST_DIR)
	mkdir -p $(DISTCLOUD_DIR)
	cp Makefile $(DOC_FILES) $(SCRIPT_FILES) $(DIST_DIR)
	cp $(CLOUD_TEMPLATE_FILES) $(DISTCLOUD_DIR)
	tar zcf $(DIST_DIR).tar.gz $(DIST_DIR)
	@echo "======================================================"
	@echo "Created:  $(DIST_DIR).tar.gz"
	@echo "======================================================"

dist: $(DIST_DIR).tar.gz

install: all
	@if [ -d $(INSTALL_PREFIX)/$(DIST_DIR) ]; then echo "Package already installed under $(INSTALL_PREFIX)/$(DIST_DIR)"; exit 1; fi
	@for files in $(SCRIPT_FILES); do if [ -f $(INSTALL_BINDIR)/$${files%.sh} ]; then echo "Link(s) already exists:" \"$(INSTALL_BINDIR)/$${files%.sh}\"". Please remove previous installation before installing." ; exit 1; fi; done
	mkdir -p $(DISTCLOUD_DIR)
	cp $(CLOUD_TEMPLATE_FILES) $(DISTCLOUD_DIR)
	cp Makefile $(DOC_FILES) $(SCRIPT_FILES) $(INSTALL_DIR)
	mkdir $(USER_CLOUDFILES_DIR)
	cp $(CLOUDINIT_FILES) $(USER_CLOUDFILES_DIR)
	chmod +x $(INSTALL_DIR)/*.sh
	for files in $(SCRIPT_FILES); do ln -s $(INSTALL_DIR)/$${files} $(INSTALL_BINDIR)/$${files%.sh}; done
	@echo "================================================================================="
	@echo "Installed package in: \"$(INSTALL_DIR)\""
	@echo "Linked script files as:"
	@for files in $(SCRIPT_FILES); do echo " - " $(INSTALL_BINDIR)/$${files%.sh} "->" $(INSTALL_DIR)/$${files}; done
	@echo "User specific cloud-init files installed in: \"$(USER_CLOUDFILES_DIR)\""
	@echo "================================================================================="

# Since we cannot know if the uninstall is run after we upgrades this script
# we cannot assume that the current installation version is the same as the one
# already installed. For that reason we find the installed version by backtracking
# the link from the installed binaries to figure out the previoud installed version.
# UDIR := $(shell dirname $$(readlink $(INSTALL_BINDIR)/mkmpnode))
# rm -rf $$(dirname $$(readlink $(INSTALL_BINDIR)/mkmpnode));
uninstall:
	if [[ -f $(INSTALL_BINDIR)/mkmpnode ]] || [[ -f $(INSTALL_BINDIR)/mpn ]]; then  \
	  rm -rf $(INSTALL_PREFIX)/share/mptools-*  ;                             \
	else                                                                       \
	  echo "mptools does not seemed installed. Aborting uninstall target.";                                        \
	  exit 1;                                                                  \
	fi
	rm -rf $(USER_CLOUDFILES_DIR)
	for files in $(SCRIPT_FILES); do rm -f $(INSTALL_BINDIR)/$${files%.sh}; done
	@echo "======================================================"
	@echo Uninstalled mptools.
	@echo Note: A 'rehash' or a restart of the shell is necessary
	@echo remove the cached binaries in shell completions.
	@echo "======================================================"


tst:
	echo $(USER_CLOUDFILES_DIR)

.PHONY: all clean nodes dist distclean install uninstall $(NODES)

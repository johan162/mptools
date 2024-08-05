# ==============================================================================================
# \file
# \brief Makefile to easily create customized user specific cloud init file
#
# \author Johan Persson <johan162@gmail.com>
# \copyright All tools released under MIT License. See LICENSE file.
# ==============================================================================================

# Uncomment to run the makefile silent
MAKEFLAGS += --silent

# Build up to four nodes in parallel
MAKEFLAGS += -j4

# Default nodes when making target "make node"
NODES := ub24fs01 ub22fs01 ub20fs01 ub18fs01

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
MACHINE_CONFIG_Z := -m 16GB -d 20GB

# Predefined image names corresponding to the major Ubuntu releases as specified in the node name
IMAGE_UB24 := noble
IMAGE_UB22 := jammy
IMAGE_UB20 := focal
IMAGE_UB18 := bionic

# Get user SSH key
USER_SSH_KEY=$(shell cat $${HOME}/.ssh/id_rsa.pub)

# Record keeping for the release
PKG_NAME := mptools
DIST_VERSION := 2.2.0
DIST_DIR := $(PKG_NAME)-$(DIST_VERSION)
DIST_CLOUDDIR := $(DIST_DIR)/cloud
DIST_DOCDIR := $(DIST_DIR)/docs

MAKEFILE_DIR := $$(dirname $(firstword $(MAKEFILE_LIST)))

INSTALL_PREFIX := /usr/local
INSTALL_DIR := $(INSTALL_PREFIX)/share/$(DIST_DIR)
INSTALL_CLOUDINIT_DIR := $(INSTALL_DIR)/cloud
INSTALL_BIN_DIR := $(INSTALL_PREFIX)/bin
INSTALL_USERCLOUDINIT_DIR := $${HOME}/.mptools

# Get all our defined cloud files
CLOUD_TEMPLATE_FILES := $(wildcard cloud/*.in)

# Generated cloud-init files
CLOUDINIT_FILES := $(patsubst %.in,%.yaml,$(CLOUD_TEMPLATE_FILES))

# ... and all tool files and shell scripts
SCRIPT_FILES := $(wildcard *.sh$)

# ... and make the bin files without extension
SCRIPT_BINFILES := $(patsubst %.sh,%,$(SCRIPT_FILES))

# ... shell extensions (currently only aliases)
SHELL_EXTENSIONS := $(wildcard *.sh.inc)

# Documentation
LICENSE_FILE := LICENSE
DOC_SRC_HTML_DIR := docs/out/html
DOC_DST_HTML_DIR := $(DIST_DOCDIR)/mptools_userguide_html
DOC_SRC_PDF_FILE := docs/out/latex/refman.pdf
DOC_DST_PDF_FILE := $(DIST_DOCDIR)/mptools_userguide.pdf

# ================================================================================================
# Rule and recipe sections

all: $(patsubst %.in,%.yaml,$(CLOUD_TEMPLATE_FILES))

node: $(NODES)

# Process *.in --> *.yaml
# Note: Use '#' as split character in sed since '/' is a valid character in base64
%.yaml : %.in
	$(info Transforming $< --> $@)
	@sed -e 's#\$${SSH_PUBLIC_KEY}#$(USER_SSH_KEY)#g' -e 's/\$${USER}/${USER}/g' < $< > $@

# This rule creates the given nodes according to the naming convention.
# This requires some explanation.
# We are extracting the markers for image, cloud cofig and machine size from the
# name with 'cut'. Then we create the variable name of one of the predefined variables above.
# (We need to use eval as we want the makefile variables to be evaluated dynamically
# when the rule is evaluated and not in the initial parsing.)
# Finally we evaluate that variable indirectly to get the value specified above.
#
# Naming of nodes: "ub<UBUNTU VERSION><CLOUD CONFIG><MACHINE SIZE><NODE NUMBER>"
#
# We do a basic egrep that will fail the receipie if the node name doesn't follow
# the correct naming convention.

$(filter ub%,$(NODES)): $(CLOUD_CONFIG_F) $(CLOUD_CONFIG_M) $(CLOUD_CONFIG_B)
	@$$(echo "$@" | egrep -q 'ub(24|22|20|18)[bmf][smlexh][0-9]{2}') || (echo "Node name not in recognised format. \"ub<UBUNTUVERSION><CLOUDCONF><MACHINESIZE><NODENUMBER\">";exit 1)
	$(eval CLOUD_CONF := CLOUD_CONFIG_$(shell echo $@|cut -c 5|tr  '[:lower:]' '[:upper:]'))
	$(eval MACHINE_SIZE := MACHINE_CONFIG_$(shell echo $@|cut -c 6|tr  '[:lower:]' '[:upper:]'))
	$(eval IMAGE := IMAGE_UB$(shell echo $@|cut -c 3-4|tr  '[:lower:]' '[:upper:]'))
	$(MAKEFILE_DIR)/mkmpnode.sh -n -r $($(IMAGE)) -c $($(CLOUD_CONF)) $($(MACHINE_SIZE)) $@ > /dev/null

clean:
	rm -rf $(patsubst %.in,%.yaml,$(CLOUD_TEMPLATE_FILES))
	$(MAKE) -C docs clean

distclean: clean
	rm -rf $(PKG_NAME)-[1-9].[1-9]*

$(DIST_DIR).tar.gz: $(SCRIPT_FILES) $(CLOUD_TEMPLATE_FILES) $(DOC_FILES)
	rm -rf $(DIST_DIR)
	mkdir -p $(DIST_CLOUDDIR)
	mkdir -p $(DIST_DOCDIR)
	cp Makefile $(LICENSE_FILE) $(SCRIPT_FILES)  $(SHELL_EXTENSIONS) $(DIST_DIR)
	cp $(CLOUD_TEMPLATE_FILES) $(DIST_CLOUDDIR)
	cp -r $(DOC_SRC_HTML_DIR) $(DOC_DST_HTML_DIR)
	cp $(DOC_SRC_PDF_FILE) $(DOC_DST_PDF_FILE)
	tar zcf $(DIST_DIR).tar.gz $(DIST_DIR)
	@echo "======================================================"
	@echo "Created:  $(DIST_DIR).tar.gz"
	@echo "======================================================"

dist: $(DIST_DIR).tar.gz

install: all
	@if [ -d $(INSTALL_DIR) ]; then echo "Package already installed under: $(INSTALL_DIR)"; exit 1; fi
	@for files in $(SCRIPT_FILES); do if [ -f $(INSTALL_BIN_DIR)/$${files%.sh} ]; then echo "Link(s) already exists:" \"$(INSTALL_BIN_DIR)/$${files%.sh}\"". Please remove previous installation before installing." ; exit 1; fi; done
	@if [[ ! -d $(INSTALL_CLOUDINIT_DIR) ]]; then mkdir -p $(INSTALL_CLOUDINIT_DIR); fi
	@if [[ ! -d $(INSTALL_BIN_DIR) ]]; then mkdir -p $(INSTALL_BIN_DIR); fi
	@cp $(CLOUD_TEMPLATE_FILES) $(INSTALL_CLOUDINIT_DIR)
	@cp Makefile $(DOC_FILES) $(SCRIPT_FILES) $(INSTALL_DIR)
	@if [[ ! -d $(INSTALL_USERCLOUDINIT_DIR) ]]; then mkdir -p $(INSTALL_USERCLOUDINIT_DIR); fi
	@cp $(CLOUDINIT_FILES) $(INSTALL_USERCLOUDINIT_DIR)
	@cp $(SHELL_EXTENSIONS) $(INSTALL_USERCLOUDINIT_DIR)
	@chmod +x $(INSTALL_DIR)/*.sh
	@for files in $(SCRIPT_FILES); do ln -s $(INSTALL_DIR)/$${files} $(INSTALL_BIN_DIR)/$${files%.sh}; done
	@echo "INSTALLATION SUMMARY"
	@echo "===================="
	@echo "Installed package in: \"$(INSTALL_DIR)\""
	@echo "Linked script files as:"
	@for files in $(SCRIPT_FILES); do echo " - " $(INSTALL_BIN_DIR)/$${files%.sh} "->" $(INSTALL_DIR)/$${files}; done
	@echo "Cloud-init files installed in: \"$(INSTALL_USERCLOUDINIT_DIR)\""
	@echo "To activate shell extensions and aliases add the following line(s) in you .zshenv file:"
	@echo ""
	@for files in $(SHELL_EXTENSIONS); do echo "source" $(INSTALL_USERCLOUDINIT_DIR)/$${files%.sh}; done
	@echo ""

# Since we cannot know if the uninstall is run after we upgrades this script
# we cannot assume that the current installation version is the same as the one
# already installed. For that reason we find the installed version by backtracking
# the link from the installed binaries to figure out the previous installed version.
uninstall:
	@if [[ -h $(INSTALL_BIN_DIR)/mkmpnode ]] || [[ -h $(INSTALL_BIN_DIR)/mpn ]] || [[ -h $(INSTALL_BIN_DIR)/mkinstall ]]; then \
      echo "UNINSTALLATION SUMMARY" ;                                                           \
      echo "======================" ;                                                           \
      INSTALLED_DIR=$$(dirname $$(readlink $(INSTALL_BIN_DIR)/mkmpnode));                       \
	  echo "Uninstall successful, removed: " ;                                                  \
	  echo " -" $${INSTALLED_DIR};                                                              \
	  echo " -" $(INSTALL_USERCLOUDINIT_DIR);                                                   \
	  for files in $(SCRIPT_FILES); do echo " -" $(INSTALL_BIN_DIR)/$${files%.sh}; done;        \
	  rm -rf $${INSTALLED_DIR};                                                                 \
	  rm -rf $(INSTALL_USERCLOUDINIT_DIR) ;                                                     \
	  for files in $(SCRIPT_FILES); do rm -f $(INSTALL_BIN_DIR)/$${files%.sh}; done;            \
	  echo "";                                                                                  \
	else                                                                                        \
	  if [[ -d $(INSTALL_USERCLOUDINIT_DIR) ]] || [[ $$(ls $(INSTALL_PREFIX)/share | grep "^mptools-") ]]; then \
		echo "Broken installation, missing installed script. Trying to clean up";               \
		echo "Found:";                                                                          \
		if [[ -d $(INSTALL_USERCLOUDINIT_DIR) ]]; then echo " - "$(INSTALL_USERCLOUDINIT_DIR); fi; \
		if [[ $$(ls $(INSTALL_PREFIX)/share | grep "^mptools-") ]]; then                        \
		    echo " - "$(INSTALL_PREFIX)/share/$$(ls $(INSTALL_PREFIX)/share | grep "^mptools-");\
        fi;                                                                                     \
		read -p "Continue to clean up these files (Y/N)?" -n 1 -r ;                             \
		if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then                                                     \
		    echo "\nAborting." ;                                                                \
		else                                                                                    \
     	    rm -rf $(INSTALL_USERCLOUDINIT_DIR);                                                \
		    rm -rf $(INSTALL_PREFIX)/share/$(PKG_NAME)-*;                                       \
		    echo "" ;                                                                           \
		    echo "Done cleaning up. Installation removed" ;                                     \
		fi                                                                                      \
	  else                                                                                      \
        echo "Package not installed. Nothing to do.";                                           \
	  fi                                                                                        \
  	fi

# Used to help debug makefile
_dbg:
	@echo MAKEFILE_DIR=$(MAKEFILE_DIR)
	@echo "----------------"
	@echo "--- VARIABLES"
	@echo "----------------"
	@echo SCRIPT_FILES=${SCRIPT_FILES}
	@echo SHELL_EXTENSIONS=${SHELL_EXTENSIONS}
	@echo SCRIPT_BINFILES=${SCRIPT_BINFILES}
	@echo "----------------"
	@echo "--- PKG & DIST"
	@echo "----------------"
	@echo PKG_NAME=$(PKG_NAME)
	@echo DIST_VERSION=$(DIST_VERSION)
	@echo DIST_DIR=$(DIST_DIR)
	@echo DIST_CLOUDDIR=$(DIST_CLOUDDIR)
	@echo "----------------"
	@echo "--- INSTALL"
	@echo "----------------"
	@echo INSTALL_USERCLOUDINIT_DIR=$(INSTALL_USERCLOUDINIT_DIR)
	@echo INSTALL_PREFIX=$(INSTALL_PREFIX)
	@echo INSTALL_DIR=$(INSTALL_DIR)
	@echo INSTALL_CLOUDINIT_DIR=$(INSTALL_CLOUDINIT_DIR)
	@echo INSTALL_BIN_DIR=$(INSTALL_BIN_DIR)
	@echo INSTALL_USERCLOUDINIT_DIR=$(INSTALL_USERCLOUDINIT_DIR)

docs:
	$(MAKE) -C docs

.PHONY: all clean node dist distclean install uninstall docs $(NODES)

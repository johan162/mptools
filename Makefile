# ==============================================================================================
# Makefile to easily create customized user specific cloud init file
#
# Note is it assumed you have defined an environment variable SSH_PUBLIC_KEY
# set to your public key.
#
# This could for example be in .zshenv (or.bash_profile) as:
#      export SSH_PUBLIC_KEY=$(cat ${HOME}/.ssh/id_rsa.pub)
#
# node Naming convention:  ub<MAJOR_RELEASE>n<NODE_NUMBER>
#
# Supported targets:
#
# (default) all     Create proper Cloud Config Files from the *.in  templates by
#                   expanding all environment variables.
#
# nodes	            Create and start all predefined nodes named in $(NODES)
#                   i.e. ub22n01 ub20n01 ub18n01
#
# clean	            Delete created YAML-files
#
# distclean         clean + remove created tar-ball restores the cloned repo
#
# dist              Create distribution tar ball
#
# By using the syntax as exemplified by:
#
#     make NODES="ub22n01 ub22n02 ub22n03" node
#
# one can dynamically create nodes without changing the Makefile
#
# Written by: Johan Persson <johan162@gmail.com>
# All tools released under MIT License. See LICENSE file
# ==============================================================================================

# MAKEFLAGS += --silent

NODES := ub22n01 ub20n01 ub18n01

CLOUD_FILES := $(wildcard cloud/*.in)
TOOL_FILES := Makefile $(wildcard *.sh)
CLOUD_CONFIG := cloud/fulldev-config.yaml
DIST_DIR := mptools
DIST_VERSION := 1.1.0

all: $(patsubst %.in,%.yaml,$(CLOUD_FILES))

node: $(NODES)

%.yaml : %.in
	cat $< | envsubst > $@

$(filter ub22%,$(NODES)): $(CLOUD_CONFIG)
	./mkmpnode.sh -r jammy -c $(CLOUD_CONFIG) $@

$(filter ub20%,$(NODES)): $(CLOUD_CONFIG)
	./mkmpnode.sh -r focal -c $(CLOUD_CONFIG) $@

$(filter ub18%,$(NODES)): $(CLOUD_CONFIG)
	./mkmpnode.sh -r bionic -c $(CLOUD_CONFIG) $@

clean:
	rm -fr $(patsubst %.in,%.yaml,$(CLOUD_FILES)) $(DIST_DIR)

distclean: clean
	rm -rf $(DIST_DIR)-$(DIST_VERSION).tar.gz
	rm -rf $(DIST_DIR)

$(DIST_DIR)-$(DIST_VERSION).tar.gz: $(TOOL_FILES) $(CLOUD_FILES)
	rm -rf $(DIST_DIR)
	mkdir $(DIST_DIR)
	cp Makefile LICENSE README.md $(TOOL_FILES) $(DIST_DIR)
	cp -r cloud $(DIST_DIR)
	tar zcf $(DIST_DIR)-$(DIST_VERSION).tar.gz $(DIST_DIR)
	rm -rf $(DIST_DIR)
	@echo "======================================================"
	@echo "Created tar-ball:  $(DIST_DIR)-$(DIST_VERSION).tar.gz "
	@echo "======================================================"

dist: $(DIST_DIR)-$(DIST_VERSION).tar.gz

.PHONY: all clean nodes dist distclean $(NODES)

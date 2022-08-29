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

# Default nodes when making target "make node"
NODES := ub22fs01 ub20fs01 ub18fs01

# Get all our defined cloud files
CLOUD_FILES := $(wildcard cloud/*.in)
TOOL_FILES := Makefile $(wildcard *.sh)

# Predefine cloud configs based on the infix in the node name
CLOUD_CONFIG_F := cloud/fulldev-config.yaml
CLOUD_CONFIG_B := cloud/mini-config.yaml
CLOUD_CONFIG_M := cloud/minidev-config.yaml

# Predefined sizes based on the infix in the node name
MACHINE_CONFIG_S := -m 500MB -d 5GB
MACHINE_CONFIG_M := -m 1GB -d 5GB
MACHINE_CONFIG_L := -m 2GB -d 10GB
MACHINE_CONFIG_X := -m 4GB -d 15GB
MACHINE_CONFIG_H := -m 8GB -d 20GB

# Predefined image names corresponding to the major Ubuntu releases as specified in the node name
IMAGE_UB22 := jammy
IMAGE_UB20 := focal
IMAGE_UB18 := bionic

# Record keeping for the release
DIST_DIR := mptools
DIST_VERSION := 1.2.0

# Rule and target sections

all: $(patsubst %.in,%.yaml,$(CLOUD_FILES))

node: $(NODES)

%.yaml : %.in
	cat $< | envsubst > $@


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

$(filter ub%,$(NODES)): $(CLOUD_CONFIG_F)
	@$$(echo "$@" | egrep -q 'ub(22|18|20)[bmf][smlxh][0-9]{2}') || (echo "Node name not in recognised format. \"ub<UBUNTUVERSION><CLOUDCONF><MACHINESIZE><NODENUMBER\">";exit 1)
	$(eval CLOUD_CONF := CLOUD_CONFIG_$(shell echo $@|cut -c 5|tr  '[:lower:]' '[:upper:]'))
	$(eval MACHINE_SIZE := MACHINE_CONFIG_$(shell echo $@|cut -c 6|tr  '[:lower:]' '[:upper:]'))
	$(eval IMAGE := IMAGE_UB$(shell echo $@|cut -c 3-4|tr  '[:lower:]' '[:upper:]'))
	./mkmpnode.sh -r $($(IMAGE)) -c $($(CLOUD_CONF)) $($(MACHINE_SIZE)) $@


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

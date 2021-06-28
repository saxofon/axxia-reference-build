# Reference build of Axxia deliveries
#
# Author : Per Hallsmark <per.hallsmark@windriver.com>
#

TOP 		?= $(shell pwd)
SHELL		?= /bin/bash

# Define V=1 to echo everything
V ?= 1
ifneq ($(V),1)
	Q=@
endif

RM = $(Q)rm -f

PLF := grr
AXXIA_SUPPORT_URL := git@github.com:axxia/axxia_support.git
AXXIA_SUPPORT_REL := grr_ase_rdk_del3
AXXIA_DELIVERY_REL := grr_ase_rdk_del3

MOPTS += INCLUDE_SIMICSFS=false
MOPTS += RDK_KLM_ARCHIVE=$(shell basename $(shell ls /wr/installs/grr/$(AXXIA_DELIVERY_REL)/rdk_klm_src_*txz))
MOPTS += RDK_TOOLS_ARCHIVE=$(shell basename $(shell ls /wr/installs/grr/$(AXXIA_DELIVERY_REL)/rdk_user_src_*txz))

all: check-dependencies extract-kernel-patches

check-dependencies:

$(TOP)/build/axxia_support/yocto_build/Makefile:
	mkdir -p $(TOP)/build
	git -C $(TOP)/build clone $(AXXIA_SUPPORT_URL)
	git -C $(TOP)/build/axxia_support checkout $(AXXIA_SUPPORT_REL)
	cp $(shell ls /wr/installs/grr/$(AXXIA_DELIVERY_REL)/rdk_klm_src_*txz) $(TOP)/build/axxia_support/yocto_build
	cp $(shell ls /wr/installs/grr/$(AXXIA_DELIVERY_REL)/rdk_user_src_*txz) $(TOP)/build/axxia_support/yocto_build

$(TOP)/build/axxia_support/yocto_build/axxia/tmp/work-shared/axxiax86-64/kernel-source : $(TOP)/build/axxia_support/yocto_build/Makefile
	cd $(TOP)/build/axxia_support/yocto_build && LANG=en_US.UTF-8 make $(MOPTS) fs

.PHONY: extract-kernel-patches
extract-kernel-patches: $(TOP)/build/axxia_support/yocto_build/axxia/tmp/work-shared/axxiax86-64/kernel-source
	mkdir -p $(TOP)/build/extracted-kernel-patches
	git -C $(TOP)/build/axxia_support/yocto_build/axxia/tmp/work-shared/axxiax86-64/kernel-source format-patch -o $(TOP)/build/extracted-kernel-patches before_rdk_commits..after_rdk_commits

layer-list:
	echo $(LAYERS)

find-delivery-diffs:
	PREVIOUS=$(shell git -C $(TOP)/build/axxia_support describe --abbrev=0 --tags $(AXXIA_SUPPORT_REL)^) ;\
		echo $$PREVIOUS ;\
		git -C $(TOP)/build/axxia_support/yocto_build/meta-intel-axxia diff $$PREVIOUS..$(AXXIA_SUPPORT_REL) README ;\
		git -C $(TOP)/build/axxia_support/yocto_build/meta-intel-axxia diff $$PREVIOUS..$(AXXIA_SUPPORT_REL) meta-intel-vcn/recipes-core/images


clean:
	$(RM) -r build

distclean: clean

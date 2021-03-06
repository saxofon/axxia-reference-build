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

ifneq ("$(JENKINS_URL)","")
AXXIA_SUPPORT_URL := /wr/installs/repo_mirrors/github.com/axxia/axxia_support.git
else
AXXIA_SUPPORT_URL := git@github.com:axxia/axxia_support.git
endif
AXXIA_SUPPORT_REL := snr_rdk_2106
AXXIA_DELIVERY_REL := snr_rdk_2106

MOPTS += INCLUDE_SIMICSFS=false

all: check-dependencies extract-kernel-patches

check-dependencies:
	locale

.PHONY: build
$(TOP)/build/axxia_support:
	mkdir -p $(TOP)/build
	git -C $(TOP)/build clone $(AXXIA_SUPPORT_URL)
	git -C $(TOP)/build/axxia_support checkout $(AXXIA_SUPPORT_REL)

$(TOP)/build/axxia_support/yocto_build/rdk_klm_src.txz:
	cd $(TOP)/build/axxia_support/yocto_build && ln -s $(shell ls /wr/installs/snr/$(AXXIA_DELIVERY_REL)/rdk_klm_src_*txz) rdk_klm_src.txz

$(TOP)/build/axxia_support/yocto_build/rdk_user_src.txz:
	cd $(TOP)/build/axxia_support/yocto_build && ln -s $(shell ls /wr/installs/snr/$(AXXIA_DELIVERY_REL)/rdk_user_src_*txz) rdk_user_src.txz

$(TOP)/build/axxia_support/yocto_build/axxia/tmp/work-shared/axxiax86-64/kernel-source urf: $(TOP)/build/axxia_support $(TOP)/build/axxia_support/yocto_build/rdk_klm_src.txz $(TOP)/build/axxia_support/yocto_build/rdk_user_src.txz
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

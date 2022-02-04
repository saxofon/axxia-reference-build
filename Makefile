# Reference build of Axxia deliveries
#
# Author : Per Hallsmark <per.hallsmark@windriver.com>
#

TOP 		?= $(shell pwd)
SHELL		?= /bin/bash
HOSTNAME	?= $(shell hostname)
USER		?= $(shell whoami)

# Define V=1 to echo everything
V ?= 1
ifneq ($(V),1)
	Q=@
endif

all: build/axxia_support/yocto_build/axxia/tmp/work-shared/axxiax86-64/kernel-source

# Optional configuration
-include hostconfig-$(HOSTNAME).mk
-include userconfig-$(USER).mk
-include $(TOP)/lib.mk/*.mk  

RM = $(Q)rm -f

PLF := grr
AXXIA_SUPPORT_URL := git@github.com:axxia/axxia_support.git
AXXIA_SUPPORT_REL := grr_ase_rdk_del7
AXXIA_DELIVERY_REL := grr_ase_rdk_del7

MOPTS += INCLUDE_SIMICSFS=false
MOPTS += RDK_KLM_ARCHIVE=$(shell basename $(shell ls /wr/installs/grr/$(AXXIA_DELIVERY_REL)/rdk_klm_src_*txz))
MOPTS += RDK_TOOLS_ARCHIVE=$(shell basename $(shell ls /wr/installs/grr/$(AXXIA_DELIVERY_REL)/rdk_user_src_*txz))


find-delivery-diffs:
	PREVIOUS=$(shell git -C $(TOP)/build/axxia_support describe --abbrev=0 --tags $(AXXIA_SUPPORT_REL)^) ;\
	echo $$PREVIOUS ;\
	git -C $(TOP)/build/axxia_support/yocto_build/meta-intel-axxia diff $$PREVIOUS..$(AXXIA_SUPPORT_REL) README ;\
	git -C $(TOP)/build/axxia_support/yocto_build/meta-intel-axxia diff $$PREVIOUS..$(AXXIA_SUPPORT_REL) meta-intel-snr ;\
	git -C $(TOP)/build/axxia_support/yocto_build/meta-intel-axxia diff $$PREVIOUS..$(AXXIA_SUPPORT_REL) meta-intel-vcn/recipes-core/images


clean:
	$(RM) -r build

distclean: clean

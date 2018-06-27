# Reference build of Axxia deliveries
#
# Author : Per Hallsmark <per.hallsmark@windriver.com>
# Repo   : https://github.com/saxofon/axxia-reference-build
#
#

TOP 		?= $(shell pwd)
SHELL		?= /bin/bash

# Define V=1 to echo everything
V ?= 1
ifneq ($(V),1)
	Q=@
endif

RM = $(Q)rm -f

POKY_URL = git://git.yoctoproject.org/poky.git
POKY_REL = 9915e071bcadd7c4d5363a067c529889851d37a5

OE_URL = https://github.com/openembedded/meta-openembedded.git
OE_REL = dacfa2b1920e285531bec55cd2f08743390aaf57
LAYERS += $(TOP)/build/layers/meta-openembedded
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-oe
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-python
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-networking
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-filesystems

VIRT_URL = git://git.yoctoproject.org/meta-virtualization
VIRT_REL = bd77388f31929f38e7d4cc9c711f0f83f563007e
LAYERS += $(TOP)/build/layers/meta-virtualization

INTEL_URL=git://git.yoctoproject.org/meta-intel
INTEL_REL=7e284b95b45c7ec5c5b5c8cb08122d3b470c0d63
LAYERS += $(TOP)/build/layers/meta-intel

AXXIA_URL=git@github.com:axxia/meta-intel-axxia_private.git
AXXIA_REL=snr_delivery13.2_linux4_12
LAYERS += $(TOP)/build/layers/meta-intel-axxia/meta-intel-snr
LAYERS += $(TOP)/build/layers/meta-intel-axxia

ENABLE_AXXIA_RDK=yes
ifeq ($(ENABLE_AXXIA_RDK),yes)
LAYERS += $(TOP)/build/layers/meta-intel-axxia-rdk
AXXIA_RDK_URL=git@github.com:axxia/meta-intel-axxia-rdk.git
AXXIA_RDK_KLM=/wr/installs/ASE/snowridge/13/rdk_klm_src_*xz
endif

MACHINE=axxiax86-64

IMAGE=axxia-image-sim

define bitbake
	cd build ; \
	source poky/oe-init-build-env ; \
	bitbake $(1)
endef

define bitbake-task
	cd build ; \
	source poky/oe-init-build-env ; \
	bitbake $(1) -c $(2)
endef

all: fs

$(TOP)/build/poky:

$(TOP)/build/layers/meta-openembedded:
	git -C $(TOP)/build/layers clone $(OE_URL) $@
	git -C $@ checkout $(OE_REL)

$(TOP)/build/layers/meta-virtualization:
	git -C $(TOP)/build/layers clone $(VIRT_URL) $@
	git -C $@ checkout $(VIRT_REL)

$(TOP)/build/layers/meta-intel:
	git -C $(TOP)/build/layers clone $(INTEL_URL) $@
	git -C $@ checkout $(INTEL_REL)

$(TOP)/build/layers/meta-intel-axxia:
	git -C $(TOP)/build/layers clone $(AXXIA_URL) $@
	git -C $@ checkout $(AXXIA_REL)

$(TOP)/build/layers/meta-intel-axxia/meta-intel-snr: $(TOP)/build/layers/meta-intel-axxia

ifeq ($(ENABLE_AXXIA_RDK),yes)
$(TOP)/build/layers/meta-intel-axxia-rdk:
	git -C $(TOP)/build/layers clone $(AXXIA_RDK_URL) $@
	git -C $@ checkout $(AXXIA_REL)
	mkdir -p $@/downloads
	cp $(AXXIA_RDK_KLM) $@/downloads/rdk_klm_src.tar.xz
	mkdir -p $@/downloads/unpacked
	tar -C $@/downloads/unpacked -xf $(AXXIA_RDK_KLM)

.PHONY: extract-rdk-patches
extract-rdk-patches:
	mkdir -p $(TOP)/build/extracted-rdk-patches
	git -C build/build/tmp/work-shared/axxiax86-64/kernel-source format-patch -5 -o $(TOP)/build/extracted-rdk-patches
	for p in $$(ls $(TOP)/build/extracted-rdk-patches/*.patch); do \
		sed -i 's/^From:.*/From: Axxia Intel <axxia@intel.com>/g' $$p ;\
	done
endif

# create wrlinux platform
.PHONY: build
build:
	$(Q)if [ ! -d $@ ]; then \
		mkdir -p $@/layers ; \
		cd $@ ; \
		git clone $(POKY_URL) ; \
		git -C poky checkout $(POKY_REL) ; \
	fi

# create bitbake build
.PHONY: build/build
build/build: build $(LAYERS)
	$(Q)if [ ! -d $@ ]; then \
		cd build ; \
		source poky/oe-init-build-env ; \
		$(foreach layer, $(LAYERS), bitbake-layers add-layer $(layer);) \
		sed -i s/^MACHINE.*/MACHINE\ =\ \"$(MACHINE)\"/g conf/local.conf ; \
		echo "DISTRO = \"intel-axxia\"" >> conf/local.conf ; \
		echo "RUNTARGET = \"simics\"" >> conf/local.conf ; \
		echo "RELEASE_VERSION = \"$(AXXIA_REL)\"" >> conf/local.conf ; \
		echo "PREFERRED_PROVIDER_virtual/kernel = \"linux-yocto\"" >> conf/local.conf ; \
		echo "PREFERRED_VERSION_linux-yocto = \"4.12%\"" >> conf/local.conf ; \
	fi

bbs: build/build
	$(Q)cd build ; \
	source poky/oe-init-build-env ; \
	bash

fs: build/build
	$(call bitbake, $(IMAGE))

sdk: build/build
	$(call bitbake-task, $(IMAGE), populate_sdk)

esdk: build/build
	$(call bitbake-task, $(IMAGE), populate_sdk_ext)

clean:
	$(RM) -r build/build

distclean:
	$(RM) -r build

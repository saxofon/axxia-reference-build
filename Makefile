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
POKY_REL = 50f33d3bfebcbfb1538d932fb487cfd789872026

OE_URL = https://github.com/openembedded/meta-openembedded.git
OE_REL = 4cd3a39f22a2712bfa8fc657d09fe2c7765a4005
#LAYERS += $(TOP)/build/layers/meta-openembedded
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-oe
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-perl
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-python
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-networking
LAYERS += $(TOP)/build/layers/meta-openembedded/meta-filesystems

VIRT_URL = git://git.yoctoproject.org/meta-virtualization
VIRT_REL = 9b568b6ae1bf1bebcb9552703ee40f9b880e07ed
LAYERS += $(TOP)/build/layers/meta-virtualization

INTEL_URL = git://git.yoctoproject.org/meta-intel
INTEL_REL = 27dadcfc7bc0de70328b02fecb841608389d22fc
LAYERS += $(TOP)/build/layers/meta-intel

SECURITY_URL = git://git.yoctoproject.org/meta-security
SECURITY_REL = 31dc4e7532fa7a82060e0b50e5eb8d0414aa7e93
LAYERS += $(TOP)/build/layers/meta-security
LAYERS += $(TOP)/build/layers/meta-security/meta-tpm

AXXIA_URL=git@github.com:axxia/meta-intel-axxia.git
AXXIA_REL=snr_ase_rdk_1905
LAYERS += $(TOP)/build/layers/meta-intel-axxia/meta-intel-axxia
LAYERS += $(TOP)/build/layers/meta-intel-axxia/meta-intel-snr

ENABLE_AXXIA_RDK=yes
ifeq ($(ENABLE_AXXIA_RDK),yes)
LAYERS += $(TOP)/build/layers/meta-intel-axxia-rdk
AXXIA_RDK_URL=git@github.com:axxia/meta-intel-axxia-rdk.git
AXXIA_RDK_KLM=/wr/installs/snr/$(AXXIA_REL)/rdk_klm_src_*xz
AXXIA_RDK_USER=/wr/installs/snr/$(AXXIA_REL)/rdk_user_src_*xz
endif

ENABLE_AXXIA_ADK=yes
ifeq ($(ENABLE_AXXIA_ADK),yes)
AXXIA_ADK_REL=adk-0.0.6.075_610
LAYERS += $(TOP)/build/layers/meta-intel-axxia-adknetd
AXXIA_ADK_LAYER=/wr/installs/snr/$(AXXIA_ADK_REL)/adk_meta-intel-axxia-adknetd*gz
endif

ENABLE_AXXIA_DPDK=no
ifeq ($(ENABLE_AXXIA_DPDK),yes)
DPDK_URL=https://git.yoctoproject.org/cgit/cgit.cgi/meta-dpdk
DPDK_REL=9d2d7a606278131479cc5b6c8cad65ddea3ff9f6
AXXIA_RDK_DPDKPATCH=/wr/installs/snr/$(AXXIA_REL)/dpdk_diff*.patch
endif

MACHINE=axxiax86-64

IMAGE=axxia-image-vcn

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

$(TOP)/build/layers/meta-openembedded/meta-oe: $(TOP)/build/layers/meta-openembedded

$(TOP)/build/layers/meta-virtualization:
	git -C $(TOP)/build/layers clone $(VIRT_URL) $@
	git -C $@ checkout $(VIRT_REL)

$(TOP)/build/layers/meta-intel:
	git -C $(TOP)/build/layers clone $(INTEL_URL) $@
	git -C $@ checkout $(INTEL_REL)

$(TOP)/build/layers/meta-security:
	git -C $(TOP)/build/layers clone $(SECURITY_URL) $@
	git -C $@ checkout $(SECURITY_REL)

$(TOP)/build/layers/meta-intel-axxia:
	git -C $(TOP)/build/layers clone $(AXXIA_URL) $@
	git -C $@ checkout $(AXXIA_REL)

$(TOP)/build/layers/meta-intel-axxia/meta-intel-axxia: $(TOP)/build/layers/meta-intel-axxia
$(TOP)/build/layers/meta-intel-axxia/meta-intel-snr: $(TOP)/build/layers/meta-intel-axxia

ifeq ($(ENABLE_AXXIA_RDK),yes)
$(TOP)/build/layers/meta-intel-axxia-rdk:
	git -C $(TOP)/build/layers clone $(AXXIA_RDK_URL) $@
	git -C $@ checkout $(AXXIA_REL)
	mkdir -p $@/downloads
	cp $(AXXIA_RDK_KLM) $@/downloads/rdk_klm_src.tar.xz
	cp $(AXXIA_RDK_USER) $@/downloads/rdk_user_src.tar.xz
	mkdir -p $@/downloads/unpacked
	tar -C $@/downloads/unpacked -xf $(AXXIA_RDK_KLM)

$(TOP)/build/layers/meta-intel-axxia-adknetd:
	tar -C $(TOP)/build/layers -xf $(AXXIA_ADK_LAYER)
endif

.PHONY: extract-kernel-patches
extract-kernel-patches:
	mkdir -p $(TOP)/build/extracted-kernel-patches
ifeq ($(ENABLE_AXXIA_RDK),yes)
	git -C build/build/tmp/work-shared/axxiax86-64/kernel-source format-patch -o $(TOP)/build/extracted-kernel-patches before_rdk_commits..after_rdk_commits
endif
ifeq ($(ENABLE_AXXIA_ADK),yes)
	git -C build/build/tmp/work-shared/axxiax86-64/kernel-source format-patch --start-number 1000 -o $(TOP)/build/extracted-kernel-patches before_adknetd_commits..after_adknetd_commits
endif

ifeq ($(ENABLE_AXXIA_DPDK),yes)
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
		bitbake-layers add-layer -F $(LAYERS) ; \
		sed -i s/^MACHINE.*/MACHINE\ =\ \"$(MACHINE)\"/g conf/local.conf ; \
		echo "DISTRO = \"intel-axxia-indist\"" >> conf/local.conf ; \
		echo "DISTRO_FEATURES_append = \" rdk-userspace\"" >> conf/local.conf ; \
		echo "RUNTARGET = \"snr\"" >> conf/local.conf ; \
		echo "RELEASE_VERSION = \"$(AXXIA_REL)\"" >> conf/local.conf ; \
		echo "PREFERRED_PROVIDER_virtual/kernel = \"linux-intel\"" >> conf/local.conf ; \
		echo "PREFERRED_VERSION_linux-intel = \"4.19%\"" >> conf/local.conf ; \
	fi

layer-list:
	echo $(LAYERS)

find-delivery-diffs:
	git -C build/layers/meta-intel-axxia diff snr_combined_ase_rdk3..snr_combined_ase_rdk4 README
	git -C build/layers/meta-intel-axxia-rdk diff snr_combined_ase_rdk3..snr_combined_ase_rdk4 README

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

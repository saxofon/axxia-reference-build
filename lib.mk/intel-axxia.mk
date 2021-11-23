build/axxia_support/yocto_build/Makefile:
	mkdir -p $(TOP)/build
	git -C $(TOP)/build clone $(AXXIA_SUPPORT_URL)
	git -C $(TOP)/build/axxia_support checkout $(AXXIA_SUPPORT_REL)
	cp $(shell ls /wr/installs/grr/$(AXXIA_DELIVERY_REL)/rdk_klm_src_*txz) $(TOP)/build/axxia_support/yocto_build
	cp $(shell ls /wr/installs/grr/$(AXXIA_DELIVERY_REL)/rdk_user_src_*txz) $(TOP)/build/axxia_support/yocto_build

build/axxia_support/yocto_build/axxia/tmp/work-shared/axxiax86-64/kernel-source : build/axxia_support/yocto_build/Makefile
	cd $(TOP)/build/axxia_support/yocto_build && LANG=en_US.UTF-8 make $(MOPTS) fs

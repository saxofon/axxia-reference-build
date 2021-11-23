BUILD_DIR=$(TOP)/build
ASE_BUILD_DIR=$(BUILD_DIR)/$(TARGET)

# Intel/Axxia stuff
SIMICS_VERSION="simics-6.0.88_del3"
RDK_SAMPLE ?= data_path_sample_multiFlow

TOPOLOGY=topology.xml
TRAFFIC=tester.xml

BIOS=ase/images/grr_bios.bin

TOPOLOGY_TEMPLATE=$(ASE_BUILD_DIR)/samples/grr/$(RDK_SAMPLE)/topology.xml
TRAFFIC_TEMPLATE=$(ASE_BUILD_DIR)/samples/grr/$(RDK_SAMPLE)/tester.xml

# set ASE_INTERACTIVE=true for ase monitor access
ASE_INTERACTIVE=false

ASE_OPTS += -t /ase-sim/topology.xml
ifeq ($(ASE_INTERACTIVE),true)
ASE_OPTS += -i
ASE_OPTS += -c /ase-sim/traffic.xml
else
ASE_OPTS += -N
endif

# WindRiver stuff
IMAGES=$(BUILD_DIR)/build/tmp-glibc/deploy/images/$(MACHINE)
USBDISK=$(IMAGE)-$(MACHINE).hddimg

ASE-CONTAINER-ID ?= "$(shell id -u)"

ASE_CONTAINER_IMAGE ?= wrl-rcs-grr/ase-container-image:$(AXXIA_REL)
ASE_CONTAINER ?= "wrl-rcs-grr-ase-$(AXXIA_REL)-$(ASE-CONTAINER-ID)"

ASE_SERIAL_CONSOLE_PORT=4042
ASE_SSH_PORT=4022

# PORT_BASE for offset'ing exposed ports from container per user to make them uniqe
# can be overriden on make params if a user needs to have multiple ase sessions
ifeq ($(USER),abradian)
PORT_BASE ?= 0
else ifeq ($(USER),vstanimi)
PORT_BASE ?= 1000
else ifeq ($(USER),phallsma)
PORT_BASE ?= 2000
endif

help:: sim-ase.help

sim-ase.help:
	$(ECHO) "\n--- sim-ase ---"
	$(ECHO) " sim-start                      : Start a simulation session, using $(ASE_CONTAINER_IMAGE) together with $(RDK_SAMPLE)"
	$(ECHO) " sim-console                    : Connect to the simulated target serial console"
	$(ECHO) " sim-stop                       : Stop the simulator"
	$(ECHO) "\n--- ase-container ---"
	$(ECHO) " ase-container-image            : build ase-container image, $(ASE_CONTAINER_IMAGE)"
	$(ECHO) " ase-container-shell            : open a shell inside ase container"
	$(ECHO) " ase-container-root-shell       : open a root shell inside ase container"
	$(ECHO) " ase-container-ase-clean        : remove existing ASE installation"

sim-samples: rdk-samples-list

sim-update:: ase.sim-update
ase.sim-update:

# serial console - pch.uart0.telnet_port - set to port $(ASE_SERIAL_CONSOLE_PORT)
sim-start:: ase.sim-start
ase.sim-start:
ifneq ($(TARGET),ase-sim)
	$(Q)exit 0
endif
	$(Q)tar -C $(ASE_BUILD_DIR) -xf $(DELIVERY_ASE_DIR)/rdk_samples*txz
	$(CP) $(IMAGES)/$(USBDISK) $(ASE_BUILD_DIR)
	chmod 666 $(ASE_BUILD_DIR)/$(USBDISK)
	$(CP) $(TOPOLOGY_TEMPLATE) $(ASE_BUILD_DIR)/topology.xml
	chmod 666 $(ASE_BUILD_DIR)/topology.xml
	$(CP) $(TRAFFIC_TEMPLATE) $(ASE_BUILD_DIR)/traffic.xml || touch $(ASE_BUILD_DIR)/traffic.xml
	chmod 666 $(ASE_BUILD_DIR)/traffic.xml

	$(XMLSTARLET) ed --inplace -u 'topology:Topology/Devices/Device/SimParameters/SimParameter[@name="pch.uart0.telnet_port"]/@value' -v "$(ASE_SERIAL_CONSOLE_PORT)" $(ASE_BUILD_DIR)/$(TOPOLOGY)
	$(XMLSTARLET) ed --inplace -u 'topology:Topology/Devices/Device/SimParameters/SimParameter[@name="pch.spi0.nvm_image0"]/@value' -v "$(BIOS)" $(ASE_BUILD_DIR)/$(TOPOLOGY)
	$(XMLSTARLET) ed --inplace -u 'topology:Topology/Devices/Device/SimParameters/SimParameter[@name="pch.sata0.disk_image"]/@value' -v "/ase-sim/disk.img" $(ASE_BUILD_DIR)/$(TOPOLOGY)
	$(XMLSTARLET) ed --inplace -u 'topology:Topology/Devices/Device/SimParameters/SimParameter[@name="cpu.real_time_scale_factor"]/@value' -v "1" $(ASE_BUILD_DIR)/$(TOPOLOGY)
	$(XMLSTARLET) ed --inplace -u 'topology:Topology/Devices/Device/SimParameters/SimParameter[@name="pch.enet.enable_host_services"]/@value' -v "true" $(ASE_BUILD_DIR)/$(TOPOLOGY)

	docker run --rm -t --name $(ASE_CONTAINER) \
		-v $(ASE_BUILD_DIR)/topology.xml:/ase-sim/topology.xml \
		-v $(ASE_BUILD_DIR)/traffic.xml:/ase-sim/traffic.xml \
		-v $(ASE_BUILD_DIR)/$(USBDISK):/ase-sim/disk.img \
		-p $$(($(PORT_BASE)+$(ASE_SERIAL_CONSOLE_PORT))):$(ASE_SERIAL_CONSOLE_PORT)/tcp \
		-p $$(($(PORT_BASE)+$(ASE_SSH_PORT))):$(ASE_SSH_PORT)/tcp \
		-it $(ASE_CONTAINER_IMAGE) $(ASE_OPTS)

sim-console:
	telnet localhost $$(($(PORT_BASE)+$(ASE_SERIAL_CONSOLE_PORT)))

sim-ssh:
	ssh -p $(ASE_SSH_PORT) root@localhost

sim-run:: ase.sim-run
ase.sim-run:

sim-stop:
	$(Q)docker kill $(ASE_CONTAINER)

ase-container-image:
	$(MKDIR) $(ASE_BUILD_DIR)
	cp -r $(DELIVERY_ASE_DIR) $(ASE_BUILD_DIR)/ase-delivery
	docker build --no-cache --build-arg DELIVERY_ASE_DIR=$(DELIVERY_ASE_DIR) -t $(ASE_CONTAINER_IMAGE) -f dockerfiles/ase/ase_container.dockerfile $(ASE_BUILD_DIR)

ase-container-shell:
	$(Q)docker exec -it -u ase -w /ase-sim $(ASE_CONTAINER) /bin/bash

ase-container-root-shell:
	$(Q)docker exec -it -u 0:0 -w /ase-sim $(ASE_CONTAINER) /bin/bash

ase-container-logs:
	$(Q)docker logs $(ASE_CONTAINER)

ase-container-ase-clean:
	rm -rf $(ASE_BUILD_DIR)

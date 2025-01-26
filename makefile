# Memory Addresses
ZEROPAGE = 0x0080
STACK = 0x0100
LZDATA = 0x2000
DRIVER = 0xD800
BUFFERS = 0xED00
RELOCATOR = $(STACK)
ORG_ADDRESS = $(LZDATA)
VUPLAYER = $(DRIVER)

# Assembly Options
OBX_NOTHING = 0
OBX_LZDATA = 1
OBX_RELOCATOR = 2
OBX_VUPLAYER = 3
OBX_PLAYLZ16 = 4
OBX_MERGEXEX = 5
OBX_MERGESAP = 6

# MADS Function Definition
define MADS
	$(eval $@COMMANDS = lzssp.asm -d:OPTION=$(1) -d:ORG_ADDRESS=$(ORG_ADDRESS))
	$(eval $@LABELS = -d:LZDATA=$(LZDATA) -d:DRIVER=$(DRIVER) -d:BUFFERS=$(BUFFERS) -d:RELOCATOR=$(RELOCATOR))
	$(eval $@PARAMETERS = -o:$(2) -l:$(3) -c -p -vu -x)
	mads ${$@COMMANDS} ${$@LABELS} ${$@PARAMETERS}
endef

# Command Lines
all: lzdata relocator vuplayer mergexex

nothing:
	@echo -e "> Assembling Nothing..."
	@$(call MADS,$(OBX_NOTHING),ASSEMBLED/Nothing.obx,ASSEMBLED/Nothing.lst)
	
lzdata:
	@echo -e "> Assembling LZData..."
	@$(call MADS,$(OBX_LZDATA),ASSEMBLED/LZData.obx,ASSEMBLED/LZData.lst)

relocator:
	@echo -e "> Assembling Relocator..."
	@$(call MADS,$(OBX_RELOCATOR),ASSEMBLED/Relocator.obx,ASSEMBLED/Relocator.lst)

vuplayer:
	@echo -e "> Assembling VUPlayer..."
	@$(call MADS,$(OBX_VUPLAYER),ASSEMBLED/VUPlayer.obx,ASSEMBLED/VUPlayer.lst)

playlz16:
	@echo -e "> Assembling PlayLZ16..."
	@$(call MADS,$(OBX_PLAYLZ16),ASSEMBLED/PlayLZ16.obx,ASSEMBLED/PlayLZ16.lst)

mergexex:
	@echo -e "> Assembling MergeXEX..."
	@$(call MADS,$(OBX_MERGEXEX),ASSEMBLED/build.xex,ASSEMBLED/build.lst)

mergesap:
	@echo -e "> Assembling MergeSAP..."
	@$(call MADS,$(OBX_MERGESAP),ASSEMBLED/MergeSAP.sap,ASSEMBLED/MergeSAP.lst)
	

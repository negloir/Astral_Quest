#---------------------------------------------------------------------------------
# Astral Quest - NDS (ARM9) build
#---------------------------------------------------------------------------------

.SUFFIXES:

# Provided by the devkitpro/devkitarm container
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM (provided in the devkitpro/devkitarm container).")
endif

#---------------------------------------------------------------------------------
# Project metadata / layout
#---------------------------------------------------------------------------------
TARGET      := astral_quest
BUILD       := build

# Source & headers (case-sensitive)
SOURCES     := source
INCLUDES    := include

# NitroFS directory (may be empty; still included in ROM)
NITRO_FILES := nitrofiles

#---------------------------------------------------------------------------------
# Toolchain/lib paths
#---------------------------------------------------------------------------------
DEVKITPRO   ?= $(shell dirname $(DEVKITARM))
LIBDIRS     := $(DEVKITPRO)/libnds $(DEVKITPRO)/portlibs/arm

#---------------------------------------------------------------------------------
# Flags
#---------------------------------------------------------------------------------
ARCH     := -marm -mthumb-interwork -march=armv5te -mtune=arm946e-s
CFLAGS   := -g -Wall -O2 $(ARCH) -DARM9
CXXFLAGS := $(CFLAGS) -fno-rtti -fno-exceptions
ASFLAGS  := -g $(ARCH)
# Use ds_arm9.specs (our workflow installs the missing sync-none.specs)
LDFLAGS  := -specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(notdir $(TARGET).map)

# Link order matters for libfat/libnds
LIBS     := -lfilesystem -lfat -lnds9

# Put our local include directory FIRST so <calico/...> resolves to stubs
INCLUDE  := \
	-I$(CURDIR)/$(INCLUDES) \
	-iquote $(CURDIR)/$(INCLUDES) \
	$(foreach d,$(LIBDIRS),-I$(d)/include)

# Library search paths
LIBPATHS := $(foreach d,$(LIBDIRS),-L$(d)/lib)

#---------------------------------------------------------------------------------
# Build orchestration (let ds_rules do discovery & dependency wiring)
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT     := $(CURDIR)/$(TARGET)
export TOPDIR     := $(CURDIR)
export VPATH      := $(foreach d,$(SOURCES),$(CURDIR)/$(d))
export DEPSDIR    := $(CURDIR)/$(BUILD)

# Re-export variables used by ds_rules
export SOURCES INCLUDES NITRO_FILES
export INCLUDE LIBPATHS LIBS CFLAGS CXXFLAGS ASFLAGS LDFLAGS

.PHONY: all clean
all: $(BUILD)

$(BUILD):
	@mkdir -p $(BUILD)
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo "[CLEAN] $(BUILD)"
	@rm -rf $(BUILD) $(TARGET).nds $(TARGET).elf $(TARGET).map

else  # ---------------------------- inside $(BUILD)

# Pull in devkitPro DS rules (handles object discovery & ROM creation)
include $(DEVKITARM)/ds_rules

# Ensure the GCC driver (arm-none-eabi-gcc) performs the link, not bare ld
override LD := $(CC)

# Default goal builds the ROM; ds_rules wires object prerequisites correctly.
.PHONY: all
all: $(OUTPUT).nds

endif

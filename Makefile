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
NITRO       := nitrofiles

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

# Use ds_arm9.specs (workflow installs missing sync-none.specs)
# Write the .map to the repo root via $(OUTPUT).map
LDFLAGS  := -specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(OUTPUT).map

# Link order matters
LIBS     := -lfilesystem -lfat -lnds9

#---------------------------------------------------------------------------------
# Outer phase: discover sources, set paths, then recurse into $(BUILD)
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT  := $(CURDIR)/$(TARGET)
export VPATH   := $(foreach d,$(SOURCES),$(CURDIR)/$(d))
export DEPSDIR := $(CURDIR)/$(BUILD)

# Discover sources now; ds_rules expects these exported
CFILES    := $(foreach d,$(SOURCES),$(notdir $(wildcard $(d)/*.c)))
CPPFILES  := $(foreach d,$(SOURCES),$(notdir $(wildcard $(d)/*.cpp)))
SFILES    := $(foreach d,$(SOURCES),$(notdir $(wildcard $(d)/*.s)))

# Objects to build (no paths here; VPATH handles finding sources)
export OFILES_SOURCES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES         := $(OFILES_SOURCES)

# NitroFS wiring (ds_rules consumes NITRO_FILES if set)
ifneq ($(strip $(NITRO)),)
export NITRO_FILES := $(CURDIR)/$(NITRO)
endif

# Include paths (our local include/ FIRST for calico stubs), then SDK
export INCLUDE := \
	-I$(CURDIR)/$(INCLUDES) \
	-iquote $(CURDIR)/$(INCLUDES) \
	$(foreach d,$(LIBDIRS),-I$(d)/include) \
	-I$(CURDIR)/$(BUILD)

# Library search paths
export LIBPATHS := $(foreach d,$(LIBDIRS),-L$(d)/lib)

# Export tool flags/libs
export CFLAGS CXXFLAGS ASFLAGS LDFLAGS LIBS

.PHONY: all clean
all: $(BUILD)

$(BUILD):
	@mkdir -p $(BUILD)
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo "[CLEAN] $(BUILD)"
	@rm -rf $(BUILD) $(TARGET).nds $(TARGET).elf $(TARGET).map

else  # ---------------------------- inside $(BUILD)

# Pull in devkitPro DS rules (compiles objects & builds ROM)
include $(DEVKITARM)/ds_rules

# Ensure the GCC driver (arm-none-eabi-gcc) performs the link, not bare ld
override LD := $(CC)

# Default goal builds the ROM
.PHONY: all
all: $(OUTPUT).nds

endif

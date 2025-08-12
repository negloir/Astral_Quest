#---------------------------------------------------------------------------------
# Astral Quest - NDS (ARM9) build (NitroFS)
#---------------------------------------------------------------------------------

.SUFFIXES:

# devkitARM must be present (provided by devkitpro/devkitarm container)
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM (provided in the devkitpro/devkitarm container).")
endif

#---------------------------------------------------------------------------------
# Project configuration
#---------------------------------------------------------------------------------
TARGET      := astral_quest
BUILD       := build
SOURCES     := source
INCLUDES    := include
DATA        :=
GRAPHICS    :=
AUDIO       :=
ICON        :=

# NitroFS dir (can be empty; include a .keep file)
NITRO       := nitrofiles

#---------------------------------------------------------------------------------
# Toolchain/library roots
#---------------------------------------------------------------------------------
DEVKITPRO   ?= $(shell dirname $(DEVKITARM))
LIBDIRS     := $(DEVKITPRO)/libnds $(DEVKITPRO)/portlibs/arm

#---------------------------------------------------------------------------------
# Flags
#---------------------------------------------------------------------------------
ARCH        := -march=armv5te -mtune=arm946e-s -marm -mthumb-interwork
CFLAGS      := -g -Wall -O2 -ffunction-sections -fdata-sections $(ARCH) -DARM9
CXXFLAGS    := $(CFLAGS) -fno-rtti -fno-exceptions
ASFLAGS     := -g $(ARCH)

# Use ds_arm9.specs; your workflow drops sync-none.specs beside it
LDFLAGS     := -specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(OUTPUT).map

# Link order matters (filesystem -> fat -> nds9)
LIBS        := -lfilesystem -lfat -lnds9

#---------------------------------------------------------------------------------
# Outer stage: discover sources, set paths, then recurse to $(BUILD)
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT     := $(CURDIR)/$(TARGET)
export VPATH      := \
	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
	$(foreach dir,$(DATA),$(CURDIR)/$(dir)) \
	$(foreach dir,$(GRAPHICS),$(CURDIR)/$(dir)) \
	$(CURDIR)/$(dir $(ICON))

export DEPSDIR    := $(CURDIR)/$(BUILD)

# Source discovery (relative file names; VPATH resolves directories)
CFILES            := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES          := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES            := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PNGFILES          := $(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.png)))
BINFILES          := $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

# Export NitroFS location for ds_rules
ifneq ($(strip $(NITRO)),)
export NITRO_FILES := $(CURDIR)/$(NITRO)
endif

# Choose linker driver (C project by default)
ifeq ($(strip $(CPPFILES)),)
export LD := $(CC)
else
export LD := $(CXX)
endif

# Object lists consumed by ds_rules
export OFILES_BIN      := $(addsuffix .o,$(BINFILES))
export OFILES_SOURCES  := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES          := $(PNGFILES:.png=.o) $(OFILES_BIN) $(OFILES_SOURCES)
export HFILES          := $(PNGFILES:.png=.h) $(addsuffix .h,$(subst .,_,$(BINFILES)))

# Include search order:
# 1) our local include/ FIRST (for calico stubs)
# 2) SDK/portlibs
# 3) build dir for generated headers
export INCLUDE  := \
	-I$(CURDIR)/$(INCLUDES) \
	-iquote $(CURDIR)/$(INCLUDES) \
	$(foreach d,$(LIBDIRS),-I$(d)/include) \
	-I$(CURDIR)/$(BUILD)

# Library search paths
export LIBPATHS := $(foreach d,$(LIBDIRS),-L$(d)/lib)

# Propagate flags/libs
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

# Bring in the devkitPro rules inside the build dir
include $(DEVKITARM)/ds_rules

# Ensure the GCC driver (arm-none-eabi-gcc) performs the link (not bare ld)
override LD := $(CC)

# Default goal builds the ROM; ds_rules wires object prerequisites
.PHONY: all
all: $(OUTPUT).nds

endif  # --------------------------- end outer ifneq

#---------------------------------------------------------------------------------
# Astral Quest - NDS (ARM9) build (NitroFS)
#---------------------------------------------------------------------------------

.SUFFIXES:

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
LDFLAGS     := -specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(OUTPUT).map

# Link order matters
LIBS        := -lfilesystem -lfat -lnds9

#---------------------------------------------------------------------------------
# OUTER STAGE: discover sources, set paths, then recurse to $(BUILD)
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

# Freeze absolute top dir so paths don't shift inside build/
export TOPDIR    := $(CURDIR)
export OUTPUT    := $(TOPDIR)/$(TARGET)
export VPATH     := \
	$(foreach dir,$(SOURCES),$(TOPDIR)/$(dir)) \
	$(foreach dir,$(DATA),$(TOPDIR)/$(dir)) \
	$(foreach dir,$(GRAPHICS),$(TOPDIR)/$(dir))
export DEPSDIR   := $(TOPDIR)/$(BUILD)

# Source discovery (relative names; VPATH resolves dirs)
CFILES            := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES          := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES            := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PNGFILES          := $(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.png)))
BINFILES          := $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

# Export NitroFS location for ds_rules
ifneq ($(strip $(NITRO)),)
export NITRO_FILES := $(TOPDIR)/$(NITRO)
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

# Library search paths
export LIBPATHS := $(foreach d,$(LIBDIRS),-L$(d)/lib)

# Propagate flags/libs
export CFLAGS CXXFLAGS ASFLAGS LDFLAGS LIBS

.PHONY: all clean
all: $(BUILD)

$(BUILD):
	@mkdir -p $(BUILD)
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(TOPDIR)/Makefile

clean:
	@echo "[CLEAN] $(BUILD)"
	@rm -rf $(BUILD) $(TARGET).nds $(TARGET).elf $(TARGET).map

else  # ---------------------------- inside $(BUILD)

# Bring in the devkitPro rules inside the build dir
include $(DEVKITARM)/ds_rules

# FORCE both include roots onto every compile line (beats ds_rules defaults)
INCLUDE_EXTRA := \
	-I$(TOPDIR)/$(INCLUDES) \
	-iquote $(TOPDIR)/$(INCLUDES) \
	$(foreach d,$(LIBDIRS),-I$(d)/include) \
	-I$(DEPSDIR)

override CFLAGS   := $(CFLAGS)   $(INCLUDE_EXTRA)
override CXXFLAGS := $(CXXFLAGS) $(INCLUDE_EXTRA)

# Ensure the GCC driver (arm-none-eabi-gcc) performs the link (not bare ld)
override LD := $(CC)

# Explicit dependency wiring so objects compile BEFORE linking
$(OUTPUT).nds: $(OUTPUT).elf $(GAME_ICON)
$(OUTPUT).elf: $(OFILES)
$(OFILES_SOURCES): $(HFILES)
$(OFILES): $(SOUNDBANK)

# Default goal builds the ROM
.PHONY: all
all: $(OUTPUT).nds

endif  # --------------------------- end outer ifneq

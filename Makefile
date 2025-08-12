#---------------------------------------------------------------------------------
# Astral Quest - NDS (ARM9) build
#---------------------------------------------------------------------------------

.SUFFIXES:

# Require devkitARM (provided by devkitpro/devkitarm container)
ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment. In CI this is provided by the devkitpro/devkitarm container.")
endif

#---------------------------------------------------------------------------------
# Project metadata / layout
#---------------------------------------------------------------------------------
TARGET      := astral_quest
BUILD       := build
SOURCES     := source
INCLUDES    := include
DATA        :=
GRAPHICS    :=
AUDIO       :=

# NitroFS directory (can be empty; ds_rules packs it into the ROM)
NITRO       := nitrofiles

#---------------------------------------------------------------------------------
# Toolchain/lib paths
#---------------------------------------------------------------------------------
DEVKITPRO   ?= $(shell dirname $(DEVKITARM))
LIBDIRS     := $(DEVKITPRO)/libnds $(DEVKITPRO)/portlibs/arm

#---------------------------------------------------------------------------------
# Codegen flags
#---------------------------------------------------------------------------------
ARCH        := -marm -mthumb-interwork -march=armv5te -mtune=arm946e-s

CFLAGS      := -g -Wall -O2 $(ARCH) -DARM9
CXXFLAGS    := $(CFLAGS) -fno-rtti -fno-exceptions
ASFLAGS     := -g $(ARCH)

# Keep classic ds_arm9.specs (container needs sync-none.specs; workflow installs it)
LDFLAGS     := -specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(notdir $(TARGET).map)

# Link order matters; filesystem -> fat -> nds9
LIBS        := -lfilesystem -lfat -lnds9

#---------------------------------------------------------------------------------
# Recursive build into $(BUILD)
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT     := $(CURDIR)/$(TARGET)
export VPATH      := \
	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
	$(foreach dir,$(DATA),$(CURDIR)/$(dir)) \
	$(foreach dir,$(GRAPHICS),$(CURDIR)/$(dir))

export DEPSDIR    := $(CURDIR)/$(BUILD)

# Discover sources & assets
CFILES           := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES         := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES           := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

# NitroFS wiring (ds_rules consumes NITRO_FILES)
ifneq ($(strip $(NITRO)),)
export NITRO_FILES := $(CURDIR)/$(NITRO)
endif

# Include paths:
# 1) our local "include/" first for <calico/...> stubs
# 2) -iquote for "" includes
# 3) system/portlibs includes
# 4) build dir for generated headers
export INCLUDE := \
	-I$(CURDIR)/$(INCLUDES) \
	-iquote $(CURDIR)/$(INCLUDES) \
	$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
	-I$(CURDIR)/$(BUILD)

# Library search paths
export LIBPATHS := $(foreach dir,$(LIBDIRS),-L$(dir)/lib)

# Object lists used by ds_rules
export OFILES_SOURCES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES         := $(OFILES_SOURCES)

.PHONY: all clean
all: $(BUILD)

$(BUILD):
	@mkdir -p $(BUILD)
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo "[CLEAN] $(BUILD)"
	@rm -rf $(BUILD) $(TARGET).nds $(TARGET).elf $(TARGET).map

else  # ---------------------------- inside $(BUILD)

# Pull in devkitPro DS rules (defines CC/CXX/AS/LD with arm-none-eabi- prefix)
include $(DEVKITARM)/ds_rules

# Force the linker to be the GCC driver (NOT bare ld), so ARCH flags are handled.
override LD := $(CC)

# Always expose a default goal
.PHONY: all
all: $(OUTPUT).nds

endif

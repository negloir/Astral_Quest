#---------------------------------------------------------------------------------
# Astral Quest - NDS (ARM9) build (ARM9 only, NitroFS)
# Based on the official devkitPro libnds template, adjusted to search our local
# include/ first so Calico stubs are found.  Ends with the standard ds_rules flow.
#---------------------------------------------------------------------------------

.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM (provided in the devkitpro/devkitarm container).")
endif

include $(DEVKITARM)/ds_rules

#---------------------------------------------------------------------------------
# Project config
#---------------------------------------------------------------------------------
TARGET   := astral_quest
BUILD    := build
SOURCES  := source
INCLUDES := include            # our stubs live here
DATA     :=
GRAPHICS :=
AUDIO    :=
ICON     :=
NITRO    := nitrofiles         # keep directory in repo (can be empty)

#---------------------------------------------------------------------------------
# Codegen flags
#---------------------------------------------------------------------------------
ARCH     := -march=armv5te -mtune=arm946e-s
CFLAGS   := -g -Wall -O2 -ffunction-sections -fdata-sections $(ARCH) $(INCLUDE) -DARM9
CXXFLAGS := $(CFLAGS) -fno-rtti -fno-exceptions
ASFLAGS  := -g $(ARCH)
LDFLAGS  := -specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

#---------------------------------------------------------------------------------
# Libraries (NitroFS adds filesystem+fat automatically)
#---------------------------------------------------------------------------------
LIBS := -lnds9
ifneq ($(strip $(NITRO)),)
  LIBS := -lfilesystem -lfat $(LIBS)
endif
ifneq ($(strip $(AUDIO)),)
  LIBS := -lmm9 $(LIBS)
endif

#---------------------------------------------------------------------------------
# Library/search paths (top-level dirs with include/ and lib/)
#---------------------------------------------------------------------------------
LIBDIRS := $(LIBNDS) $(PORTLIBS)

#---------------------------------------------------------------------------------
# Nothing below here normally needs editing (template logic)
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT  := $(CURDIR)/$(TARGET)
export VPATH   := $(CURDIR)/$(subst /,,$(dir $(ICON))) \
                  $(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
                  $(foreach dir,$(DATA),$(CURDIR)/$(dir)) \
                  $(foreach dir,$(GRAPHICS),$(CURDIR)/$(dir))
export DEPSDIR := $(CURDIR)/$(BUILD)

CFILES    := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES  := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES    := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PNGFILES  := $(foreach dir,$(GRAPHICS),$(notdir $(wildcard $(dir)/*.png)))
BINFILES  := $(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

ifneq ($(strip $(NITRO)),)
  export NITRO_FILES := $(CURDIR)/$(NITRO)
endif

# choose linker (C project by default)
ifeq ($(strip $(CPPFILES)),)
  export LD := $(CC)
else
  export LD := $(CXX)
endif

export OFILES_BIN     := $(addsuffix .o,$(BINFILES))
export OFILES_SOURCES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES         := $(PNGFILES:.png=.o) $(OFILES_BIN) $(OFILES_SOURCES)
export HFILES         := $(PNGFILES:.png=.h) $(addsuffix .h,$(subst .,_,$(BINFILES)))

# IMPORTANT: search our local include/ FIRST so <calico/...> resolves to stubs.
export INCLUDE := -iquote $(CURDIR)/$(INCLUDES) \
                  $(foreach dir,$(LIBDIRS),-I$(dir)/include) \
                  -I$(CURDIR)/$(BUILD)
export LIBPATHS := $(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: all clean
all: $(BUILD)

$(BUILD):
	@mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).elf $(

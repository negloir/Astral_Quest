#---------------------------------------------------------------------------------
# Minimal libnds Makefile for ARM9 + NitroFS (with Calico stub support)
#---------------------------------------------------------------------------------

.SUFFIXES:

ifeq ($(strip $(DEVKITARM)),)
$(error "Please set DEVKITARM in your environment.")
endif

include $(DEVKITARM)/ds_rules

#---------------------------------------------------------------------------------
# Project settings
#---------------------------------------------------------------------------------
TARGET       := astral_quest
BUILD        := build
SOURCES      := source
INCLUDES     := include
NITRO_FILES  := nitrofiles

#---------------------------------------------------------------------------------
# Flags
#---------------------------------------------------------------------------------
ARCH      := -mthumb -mthumb-interwork
CFLAGS    := -g -Wall -O2 -fomit-frame-pointer -ffast-math              -march=armv5te -mtune=arm946e-s $(ARCH) $(INCLUDE) -DARM9
CXXFLAGS  := $(CFLAGS) -fno-rtti -fno-exceptions
ASFLAGS   := -g $(ARCH)
LDFLAGS   := -specs=ds_arm9.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)
LIBS      := -lnds9 -lfilesystem -lfat
LIBDIRS   := $(LIBNDS)

# Include paths — ensure our local include/ is searched first for <calico.h>
export INCLUDE :=   $(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir) -iquote $(CURDIR)/$(dir))   $(foreach dir,$(LIBDIRS),-I$(dir)/include)   -I$(CURDIR)/$(BUILD)

#---------------------------------------------------------------------------------
# Build rules
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))

export OUTPUT      := $(CURDIR)/$(TARGET)
export VPATH       := $(foreach dir,$(SOURCES),$(CURDIR)/$(dir))
export DEPSDIR     := $(CURDIR)/$(BUILD)

CFILES    := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.c)))
CPPFILES  := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES    := $(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))

ifeq ($(strip $(CPPFILES)),)
  export LD := $(CC)
else
  export LD := $(CXX)
endif

export OFILES_SOURCES := $(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)
export OFILES          := $(OFILES_SOURCES)
export LIBPATHS        := $(foreach dir,$(LIBDIRS),-L$(dir)/lib)

.PHONY: $(BUILD) clean

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).elf $(TARGET).nds $(TARGET).map

else  # ------------------------------- build rules -----------------------------

$(OUTPUT).nds: $(OUTPUT).elf $(NITRO_FILES)
	@ndstool -c $@ -9 $(TARGET).elf -d $(NITRO_FILES)
	@echo built ... $(notdir $@)

$(OUTPUT).elf: $(OFILES)
	@echo linking $(notdir $@)
	@$(LD) $(LDFLAGS) $(OFILES) $(LIBPATHS) $(LIBS) -o $@

%.o: %.c
	@echo $(notdir $<)
	@$(CC) -MMD -MF $(DEPSDIR)/$*.d $(CFLAGS) -c $< -o $@

%.o: %.cpp
	@echo $(notdir $<)
	@$(CXX) -MMD -MF $(DEPSDIR)/$*.d $(CXXFLAGS) -c $< -o $@

%.o: %.s
	@echo $(notdir $<)
	@$(CC) -MMD -MF $(DEPSDIR)/$*.d $(ASFLAGS) -c $< -o $@

endif
#---------------------------------------------------------------------------------

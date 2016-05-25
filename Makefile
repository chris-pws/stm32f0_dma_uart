#Project settings
PROJECT_NAME = uart
SOURCES = main.c uart.c
BUILD_DIR = build/

OBJECTS = $(SOURCES:%.c=$(BUILD_DIR)%.o)
DEPS = $(SOURCES:%.c=$(BUILD_DIR)%.d)
TARGET_ELF = $(BUILD_DIR)$(PROJECT_NAME).elf
TARGET_BIN = $(TARGET_ELF:%.elf=%.bin)
TARGET_HEX = $(TARGET_ELF:%.elf=%.hex)

#Toolchain settings
TOOLCHAIN = arm-none-eabi

CC = $(TOOLCHAIN)-gcc
OBJCOPY = $(TOOLCHAIN)-objcopy
OBJDUMP = $(TOOLCHAIN)-objdump
SIZE = $(TOOLCHAIN)-size

#Target CPU options
CPU_DEFINES = -mthumb -mcpu=cortex-m0 -msoft-float -DSTM32F0

#Compiler options
CFLAGS		+= -Os -g -c
CFLAGS		+= -Wall -MD -Wundef
CFLAGS		+= -fno-common -ffunction-sections -fdata-sections $(CPU_DEFINES)

INCLUDE_PATHS += -Ilib/libopencm3/include -Iinc

LINK_SCRIPT = ./stm32l030r8.ld

LINK_FLAGS =  -Llib/libopencm3/lib --static -nostartfiles
LINK_FLAGS += -Llib/libopencm3/lib/stm32/f0 
LINK_FLAGS += -T$(LINK_SCRIPT) -lopencm3_stm32f0 
LINK_FLAGS += -Wl,--start-group -lc -lgcc -lnosys -Wl,--end-group -Wl,--gc-sections
LINK_FLAGS += $(CPU_DEFINES)

LIBS = libopencm3_stm32f0.a

#Not used for now but we should add it
DEBUG_FLAGS = -g   

#Directories
vpath %.c src
vpath %.o $(BUILD_DIR)
vpath %.d $(BUILD_DIR)
vpath %.ld lib/libopencm3/lib/stm32/f0
vpath %.a lib/libopencm3/lib


default: $(TARGET_BIN)

include $(DEPS)


$(DEPS): $(BUILD_DIR)%.d: %.c
	@set -e; rm -f $@; \
	$(CC) -MM $(CFLAGS) $(INCLUDE_PATHS) $< > $@.$$$$; \
	sed 's,\($*\)\.o[ :]*,$(BUILD_DIR)\1.o $@ : ,g' < $@.$$$$ > $@; \
	rm -f $@.$$$$

$(TARGET_BIN): $(TARGET_ELF)
	$(OBJCOPY) -Obinary $(TARGET_ELF) $(TARGET_BIN)

$(TARGET_HEX): $(TARGET_ELF)
	$(OBJCOPY) -Oihex $(TARGET_ELF) $(TARGET_HEX)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET_ELF): $(BUILD_DIR) $(LIBS) $(OBJECTS) $(LINK_SCRIPT)
	$(CC) $(OBJECTS) $(LINK_FLAGS) -o $(TARGET_ELF)

$(OBJECTS): $(BUILD_DIR)%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDE_PATHS) $< -o $@ -Wa,-a,-ad > $@.lst

$(LINK_SCRIPT): libopencm3_stm32f0.a

libopencm3_stm32f0.a: lib/libopencm3/.git
	cd lib/libopencm3; $(MAKE) lib/stm32/f0

lib/libopencm3/.git:
	cd lib/libopencm3; git submodule init
	cd lib/libopencm3; git submodule update

clean:
	rm -f $(OBJECTS) $(TARGET_ELF) $(TARGET_BIN) $(TARGET_HEX)

deep-clean: clean
	cd lib/libopencm3; $(MAKE) clean

all: default

upload: $(TARGET_HEX)

	openocd -f interface/stlink-v2-1.cfg \
		    -f board/st_nucleo_f0.cfg \
		    -c "init" -c "reset init" \
		    -c "flash write_image erase $(TARGET_HEX)" \
		    -c "reset" \
		    -c "shutdown"

#test: upload
#	python -i ~/projekt/radiotest2/python_scripts/com2.py $(UART)


.PHONY: default clean deep-clean libopencm3 all upload test

#######################################################
# Debugging targets
#######################################################

gdb: all
	/opt/gcc-arm-none-eabi-5_3-2016q1/bin/arm-none-eabi-gdb $(TARGET_ELF)

# Start OpenOCD GDB server (supports semihosting)
openocd: 
	openocd -f board/st_nucleo_f0.cfg

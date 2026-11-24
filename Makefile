# ------------------------------------------------
# Makefile for STM32F429ZI (Pure CMSIS)
# ------------------------------------------------

TARGET = stm32f429_auto_door

DEBUG = 1
OPT = -Og
BUILD_DIR = build

#######################################
# MCU & Toolchain settings
#######################################
PREFIX = arm-none-eabi-
ifdef GCC_PATH
	CC = $(GCC_PATH)/$(PREFIX)gcc
	AS = $(GCC_PATH)/$(PREFIX)gcc -x assembler-with-cpp
	CP = $(GCC_PATH)/$(PREFIX)objcopy
	SZ = $(GCC_PATH)/$(PREFIX)size
else
	CC = $(PREFIX)gcc
	AS = $(PREFIX)gcc -x assembler-with-cpp
	CP = $(PREFIX)objcopy
	SZ = $(PREFIX)size
endif

HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S

MCU = -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard

#######################################
# Sources
#######################################
C_SOURCES = \
$(wildcard src/app/*.c) \
$(wildcard src/bsp/*.c) \
$(wildcard src/drivers/*.c) \
$(wildcard src/sys/*.c)

ASM_SOURCES = \
src/sys/startup_stm32f429xx.s

#######################################
# Includes & Defines
#######################################
C_DEFS = \
-DSTM32F429xx

C_INCLUDES = \
-Iinclude \
-Ilib/CMSIS/Include \
-Ilib/CMSIS/Devices/STM32F4xx/Inc 

#######################################
# Compiler & Linker flags
#######################################
ASFLAGS = $(MCU) $(OPT) -Wall -fdata-sections -ffunction-sections

CFLAGS = $(MCU) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wall -Wextra -fdata-sections -ffunction-sections
ifeq ($(DEBUG), 1)
	CFLAGS += -g3 -gdwarf-4
endif
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"

LDSCRIPT = ld/STM32F429ZITx_FLASH.ld
LIBS = -lc -lm -lnosys
LDFLAGS = $(MCU) -specs=nano.specs -T$(LDSCRIPT) $(LIBS) \
          -Wl,-Map=$(BUILD_DIR)/$(TARGET).map,--cref \
          -Wl,--gc-sections \
          -Wl,--no-warn-rwx-segment

#######################################
# Build rules
#######################################
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin
	@echo "==========================================="
	@echo "|| The build was completed successfully! ||"
	@echo "==========================================="

OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))

OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR)
	$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	$(AS) -c $(ASFLAGS) $< -o $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@

$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	@echo "---------------------   SIZE   ----------------------"
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@ -Wl,--print-memory-usage
	@echo ""
	@$(SZ) $@
	@echo "-----------------------------------------------------"

$(BUILD_DIR):
	@mkdir $@

clean:
	@rm -rf $(BUILD_DIR)

flash: all
	openocd -f interface/stlink.cfg -f target/stm32f4x.cfg -c "program $(BUILD_DIR)/$(TARGET).elf verify reset exit"
	@echo "=================================="
	@echo "|| The download was successful! ||"
	@echo "=================================="

-include $(wildcard $(BUILD_DIR)/*.d)

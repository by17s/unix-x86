CC=gcc
CC_ARGS=-finput-charset=UTF-8 -fexec-charset=UTF-8 -I ../include/kernel/ -fno-stack-protector -m32 -mgeneral-regs-only -nostdlib -O0 -c

ASMC=nasm
ASMC_ARGS=-felf32

ARCH=i586

SRC=src/
OBJ=obj/

ASM_FILES_ARCH := $(addprefix ../,$(shell find $(SRC)kernel/arch/ -name "*.asm"))
C_FILES := $(addprefix ../,$(shell find $(SRC)kernel/ -name "*.c"))
#C_FILES_KDRIVERS := $(addprefix ../,$(shell find $(SRC)kdrivers/ -name "*.c"))

ISO_NAME=Unix-P6
ISO_VER=0.0.1a
ISO_DIR=iso/

OUTPUTLOG=/dev/pts/0

build:
	#==[ NASM ]==#
	@cd obj;for element in $(notdir $(ASM_FILES_ARCH)); do \
		$(ASMC) $(ASMC_ARGS) ../src/kernel/arch/$$element -o $$element.o; \
		echo \~ Building asm object $$element; \
	done
	#==[ GCC  ]==#
	@cd obj;for element in $(C_FILES); do \
		filename=$$(basename $$element); \
		$(CC) $(CC_ARGS) $$element -o $$filename.o; \
		echo \~ Building С object $$filename; \
	done
	#==[ LD   ]==#
	ld -m elf_i386 -T link.ld -o $(ISO_DIR)boot/kernel.elf $(shell find $(OBJ) -name "*.o")
	#==[ GRUB ]==#
	@grub-mkrescue -o $(ISO_NAME)-$(ISO_VER).iso $(ISO_DIR)

run:
	@qemu-system-x86_64 -cpu pentium3 -serial file:serial.log -accel kvm -m 512m -boot d -cdrom $(ISO_NAME)-$(ISO_VER).iso -netdev socket,id=n0,listen=:2030 -device rtl8139,netdev=n0,mac=11:11:11:11:11:11 

clear:
	rm obj/*
	rm iso/boot/kernel.elf

ramfs:
	@tar -cvf iso/sys/initramfs.tar -C initramfs .
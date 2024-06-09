#!/bin/bash

# Find all .c and .h files and count lines
find . \( -name '*.c' -or -name '*.h' \) -print0 | xargs -0 wc -l

# Compile assembly and C source files
clang -m32 -c "src/asm/boot.s" -o "bin/boot.o" -march=i386
clang -m32 -c -ffreestanding "src/C/kernel32.c" -o "bin/krnl32.o" -Wall -Wextra -march=i386

# Link the object files to create the binary
ld -m elf_i386 -T linker.ld -o bin/Nova.bin -O2 -nostdlib "bin/boot.o" "bin/krnl32.o"

# Check if the binary is multiboot compliant
if grub-file --is-x86-multiboot bin/Nova.bin; then
    echo "Multiboot confirmed"

    # Create directories for ISO contents
    mkdir -p isodir/boot/grub

    # Copy the binary and configuration files to the ISO directory
    cp bin/Nova.bin isodir/boot/Nova.bin
    cp grub.cfg isodir/boot/grub/grub.cfg
    cp a.txt isodir/a.txt

    # Create the ISO image
    grub-mkrescue -o bin/Nova.iso isodir

    # Create a 512MB raw disk image
    dd if=/dev/zero of=bin/Nova_512MB.img bs=1M count=512

    # Write the ISO contents into the raw disk image
    dd if=bin/Nova.iso of=bin/Nova_512MB.img conv=notrunc

    # Optionally run the OS in QEMU
    qemu-system-x86_64 -m 256m -soundhw pcspk -debugcon stdio -drive file=bin/Nova_512MB.img,index=0,if=ide,format=raw
else
    echo "The file is not multiboot"
fi

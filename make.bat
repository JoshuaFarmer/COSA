fasm "src/Kernel.asm" "bin/Kernel.bin"
fasm "src/Bootloader.asm" "bin/bootloader.bin"
cd bin
copy /b *.bin COSA.img
cd ../
fasm "src/test.asm" "bin/test.img"

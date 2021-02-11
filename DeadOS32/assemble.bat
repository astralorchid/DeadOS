cd bin
nasm ../kernel/boot.asm -f bin -o boot.bin
nasm ../kernel/kernel.asm -f bin -o kernel.bin

copy /b boot.bin+kernel.bin os.flp
qemu-system-x86_64 -drive format=raw,file=os.flp
cd ..

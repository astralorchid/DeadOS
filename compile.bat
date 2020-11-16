nasm boot.asm -f bin -o boot.bin
nasm kernel.asm -f bin -o kernel.bin
nasm program.asm -f bin -o program.flp
copy /b boot.bin+kernel.bin os.flp
pause
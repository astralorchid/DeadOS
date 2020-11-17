nasm boot.asm -f bin -o boot.bin
nasm kernel.asm -f bin -o kernel.bin
nasm program.asm -f bin -o program.bin
copy /b boot.bin+kernel.bin+program.bin os.flp
pause
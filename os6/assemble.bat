cd bin
nasm ../boot.asm -f bin -o boot.bin
nasm ../kernel.asm -f bin -o kernel.bin
nasm ../programs.asm -f bin -o programs.bin
copy /b boot.bin+kernel.bin+programs.bin os.flp

cd ..
pause
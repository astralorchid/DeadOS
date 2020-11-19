cd bin
nasm ../boot.asm -f bin -o boot.bin
nasm ../kernel.asm -f bin -o kernel.bin
copy /b boot.bin+kernel.bin os.flp

cd ..
pause
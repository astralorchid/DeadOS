cd bin
nasm ../boot.asm -f bin -o boot.bin
nasm ../kernel.asm -f bin -o kernel.bin
nasm ../programs.asm -f bin -o programs.bin
nasm ../programs/terminal.asm -f bin -o terminal.bin
nasm ../programs/textedit.asm -f bin -o textedit.bin
copy /b boot.bin+kernel.bin+terminal.bin+textedit.bin os.flp

cd ..
pause
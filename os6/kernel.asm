[org 0x7e00]
xor ax, ax
mov ds, ax

pop dx ;transferred from boot
mov [DRIVE], dl

mov si, DRIVE_STR
call sprint

call hprint.drive

jmp $

%include '../kernel_data.asm'
times 4096-($-$$) db 0
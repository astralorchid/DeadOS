[org 0x7e00]
xor ax, ax
mov ds, ax

pop ax

mov [KERNEL_SIZE], byte al
pop dx ;transferred from boot
mov [DRIVE], dl

call getInitVideoMode
call setInitVideoMode

mov si, DRIVE_STR
call sprint
call hprint.drive
call newLine

call irq.driver
call irq.printEnabledIRQ
call newLine

xor ah, ah
mov al, byte [KERNEL_SIZE]
call hprep
call hprint

jmp $

%include '../kernel/kernel_data.asm'
%include '../kernel/irq.asm'
times 4096-($-$$) db 0
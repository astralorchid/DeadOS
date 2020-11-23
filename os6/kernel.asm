[org 0x7e00]
xor ax, ax
mov ds, ax

pop ax
mov [readProgram], ax

pop ax
mov [KERNEL_SIZE], byte al
pop dx ;transferred from boot
mov [DRIVE], dl

call getInitVideoMode
call setInitVideoMode

call [readProgram]

mov si, DRIVE_STR
call sprint
call hprint.drive
call newLine

mov si, KERNEL_SIZE_STR
call sprint
xor ah, ah
mov al, byte [KERNEL_SIZE]
call hprep
call hprint
call newLine

call irq.driver

call irq.printEnabledIRQ

cli
    mov bl, [IRQ_MASKS+1]
    call irq.DISABLE_IRQx
    call irq.ENABLE_MASTER_PIC
sti
call irq.printEnabledIRQ
call pdt.map

jmp $

%include '../kernel/kernel_data.asm'
%include '../kernel/irq.asm'
%include '../kernel/pdt.asm'
times 5120-($-$$) db 0
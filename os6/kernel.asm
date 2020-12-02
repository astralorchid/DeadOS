[org 0x7e00]

xor ax, ax
mov ds, ax

pop ax
mov [loadProgram], ax

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

;cli
    ;mov bl, [IRQ_MASKS+1]
    ;mov dx, 0
    ;call irq.DISABLE_IRQx
    ;call irq.ENABLE_MASTER_PIC
;sti
;call irq.printEnabledIRQ
call pdt.map
call pdt.print

mov bx, 0x1000
mov es, bx
mov bx, 0x0500
mov cl, byte [bx]
mov dh, byte [bx+1]
xor bx, bx
call [loadProgram]
add bx, 0x0020

mov ax, mapProgramInput
push ax
push ds

mov ax, es
mov ds, ax

push es
push bx
retf

mapProgramInput:
xor ax, ax
mov ds, ax
pop ax
mov [inputName], ax 
pop ax ;input table offset
mov [inputOff], ax
pop ax
mov [inputSeg], ax
pop ax
mov [mainOff], ax

.getProgramName:
    push ds
    push es
    mov ax, [inputName]
    push ax
        mov ax, [inputSeg]
        mov ds, ax
        xor ax, ax
        mov es, ax

        pop ax
        mov si, ax
        mov di, programName
        mov cx, 8
        rep movsb
    pop es
    pop ds

mov si, respone_msg
call sprint
mov si, programName
call sprint
call newLine

mov ax, [inputSeg]
push ax
mov ax, [mainOff]
push ax

mov ax, [inputSeg]
mov ds, ax
retf

respone_msg db 'INPUT MAP REQUEST FROM ', 0
inputSeg dw 0
mainOff dw 0
inputOff dw 0
inputName dw 0
programName:
times 9 db 0

%include '../kernel/kernel_data.asm'
%include '../kernel/irq.asm'
%include '../kernel/pdt.asm'

times 5120-($-$$) db 0
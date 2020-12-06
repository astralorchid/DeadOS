isPROGRAM db 'program', 0
prgmNAME db 'TERMINAL', 0
MAX_SECTORS equ 0x2
prgmSec db MAX_SECTORS, 0
times 32-(prgmSec-$$) db 0

jmp setInput

main:
call setInitVideoMode
int 0x20
mov al, byte '>'
mov bl, 0x0C
call charInt
jmp $

setInput:
pop ax
mov [enableInputSeg], ax
pop ax
mov [enableInputOff], ax

call getInitVideoMode

mov si, msg
call sprint
call newLine
;packup for retf
mov ax, main
push ax
push ds
mov ax, input
push ax
mov ax, prgmNAME
push ax

mov ax, [enableInputSeg]
push ax
mov ax, [enableInputOff]
push ax
retf

input:
    pop ax
    mov bx, ax

    pop ax
    mov cx, ax

    pop ax

    mov [isReturn], ah
    mov [isShift], al

    pop ax

    mov [InputState], al

    pop ax;scancode
    mov [Scancode], al
    push ax ;save scancode again

    cmp [InputState], byte 0
    jz .InputEnded

    push bx
    mov bl, [isShift]
    int 0x21
    pop bx

    cmp [isReturn], byte 0
    jz .noReturn
    call newLine
    call getcmd
    call newLine

    push ax
    push bx
    mov al, byte '>'
    mov bl, 0x0C
    call charInt
    pop bx
    pop ax
    
    .noReturn:
    cmp al, byte 0
    jz .dontPrint
    call charInt
    pop dx ;scancode
    call saveInput
    jmp .inputretf
    .dontPrint:
        pop ax
        cmp al, byte 0x39
        jne .inputretf
        mov al, byte ' '
        call charInt
        call saveInput
        jmp .inputretf
    .InputEnded:
        pop ax ;scancode
    .inputretf:
    push bx
    push cx
retf

saveInput:
    push bx
    push ax
    mov ax, [InputLen]
    mov bx, command
    add bx, ax
    pop ax
    mov [bx], al
    add [InputLen], word 1
    pop bx
ret

getcmd:
pusha
mov si, command
call sprint

    mov al, 0x00
    mov di, command
    mov cx, word [InputLen]
    rep stosb
    mov [InputLen], word 0

popa
ret

msg db 'WELCOME TO DEADOS', 0
enableInputOff dw 0
enableInputSeg dw 0
isShift db 0
isReturn db 0
Scancode db 0
InputState db 0
InputLen dw 0
%include '../kernel/kernel_data.asm'
command:
times (512*MAX_SECTORS)-($-$$) db 0
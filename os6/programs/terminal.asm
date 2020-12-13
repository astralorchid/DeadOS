isPROGRAM db 'program', 0
prgmNAME db 'TERMINAL', 0
MAX_SECTORS equ 0xf
prgmSec db MAX_SECTORS, 0
times 32-(prgmSec-$$) db 0

jmp setInput

main:
call setInitVideoMode
;int 0x20
;tokenizer testing
push ds
push es
mov ax, 0x1000
mov ds, ax
mov es, ax

xor ax, ax
push ax
mov word [TOKEN_FLAG], ax
mov si, asmFile
push si
mov di, asmTokens
push di
;mov [di], byte ' '
;inc di
call dasm.tokenizeCharLoop
pop di
pop si
mov si, di ;prep token scan

pop es
pop ds
;print output
        mov si, asmFile
        call sprint
        call newLine
        mov si, asmTokens
        call sprint
        call newLine

mov si, OSNAME
call sprint
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

    push ax
    push bx
    mov si, OSNAME
    call sprint
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
mov ax, ds
mov es, ax
    mov bx, cmdTable
    .findCmdLoop:
    push bx
    cmp [bx], byte 0
    jz .endCmdTable
    mov si, command
    mov di, bx
    mov cx, 4
    rep cmpsb
    cmp cx, byte 0
    jz .foundCmd
    pop bx
    add bx, cmdTableOffset
    jmp .findCmdLoop
    .foundCmd:
        mov ax, word [bx+4]
        cmp ax, byte 0
        jz .endCmdTable
        call ax
    .endCmdTable:
    pop bx
    .clearCmd:
    mov al, 0x00
    mov di, command
    mov cx, word [InputLen]
    rep stosb
    mov [InputLen], word 0
popa
ret

pdtcmd:
int 0x20
ret

clrcmd:
call setInitVideoMode
ret

stkcmd:

mov cx, 0
mov dx, sp
.printStack:
    push ds
    mov ax, ss
    mov ds, ax

    mov bx, bp
    sub bx, cx
    cmp bx, dx
    je .endprintStack
    mov ax, [bx]
    pop ds
    pusha
    call hprep
    call hprint
    mov al, byte ' '
    call charInt
    popa
    inc cx
    inc cx
    jmp .printStack
.endprintStack:
pop ds

call newLine
mov ax, cx
pusha
call hprep
call hprint
popa
call newLine
ret


msg db 'WELCOME TO DEADOS', 0
SS_STR db 'SS: ', 0
SP_STR db 'SP: ', 0
BP_STR db 'BP: ', 0
enableInputOff dw 0
enableInputSeg dw 0
isShift db 0
isReturn db 0
Scancode db 0
InputState db 0
InputLen dw 0
%include '../kernel/kernel_data.asm'
%include '../kernel/dasm.asm'
asmFile:
    db 'xor ax     ,ax',0x0D,'mov ds, ax',0x0D,'jmp 0x7c00 ',0x0D,' mov ax , word[mem]',0x0D,' mov ax, word [0x0800]',0x0D,'inc ax',0x0d,'jmp ds: 0x0000', 0x00
cmdTableOffset equ 0x06
asmTokens:
    times 500 db 0
cmdTable:
    db 'reg', 0
    dw 0
    db 'pdt', 0
    dw pdtcmd
    db 'clr', 0
    dw clrcmd
    db 'stk', 0
    dw stkcmd
    db 0,0,0,0
command:
times (512*MAX_SECTORS)-($-$$) db 0
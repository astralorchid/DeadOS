isPROGRAM db 'program', 0
prgmNAME db 'TERMINAL', 0
times 32-($-$$) db 0
jmp setInput

main:
int 0x20
jmp $

setInput:
pop ax
mov [enableInputSeg], ax
pop ax
mov [enableInputOff], ax

call getInitVideoMode
call setInitVideoMode

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

    pop ax;scancode
    int 0x21
    call charInt
    
    push bx
    push cx
retf

msg db 'WELCOME TO DEADOS', 0
enableInputOff dw 0
enableInputSeg dw 0
%include '../kernel/kernel_data.asm'

times (512*2)-($-$$) db 0
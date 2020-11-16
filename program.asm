db 'p', 0
pop ax
mov [returnOff], ax
pop ax
mov [returnSeg], ax

mov ax, ds
mov dx, ax
xor cx, cx
xor bx, bx
call hprint
call newLine


mov ax, [returnSeg]
push ax
mov ax, [returnOff]
push ax
retf

jmp $
%include 'print16.asm'
returnSeg dw 0
returnOff dw 0
times 2048-($-$$) db 0
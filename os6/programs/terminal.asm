db 'program', 0
db 'TERMINAL', 0
times 15 db 0
toKernel:
mov ax, 0
push ax
mov ax, word [ds:0x01F0]
push ax
retf
jmp $
times (512)-($-$$) db 0
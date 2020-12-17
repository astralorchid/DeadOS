mov bx, SaveMem

mov ax, 0x1337
mov byte [bx], ax
inc bx
mov word [bx], 0xFFFF
mov cl, byte [0x83DF]

SaveMem db 0
JumpTo dw 0x7e00
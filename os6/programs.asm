PROGRAM db 'program', 0
db 'TERMINAL', 0
times 15 db 0
toKernel:
mov ax, 0x1000
mov ss, ax
mov bp, 0xFFFF
mov sp, bp
;mov si, 0x1002
db 0xBE,0x02,0x10
call sprint
call newLine

mov ax, 0x7000 ;dont go past this lol
mov ss, ax

mov bp, 0xFFFF
mov sp, bp

mov ax, wtf_offset
push ax
push ds

mov ax, 0
push ax
mov ax, word [ds:0x1000]
push ax
retf
jmp $

wtf db 'hi', 0
str_len equ $-wtf
wtf_offset equ wtf-PROGRAM
%include '../kernel/kernel_data.asm'

times (512*2)-($-$$) db 0

db 'program', 0
db 'ur mom', 0
times (512*3)-($-$$) db 0
db 'program', 0
db 'ENDLIST', 0
times (512*4)-($-$$) db 0
isPROGRAM db 'program', 0
prgmNAME db 'TERMINAL', 0
times 32-($-prgmNAME) db 0
main:
call getInitVideoMode
call setInitVideoMode
mov si, msg
call sprint
call newLine
jmp $
msg db 'WELCOME TO DEADOS', 0
%include '../kernel/kernel_data.asm'

times (512)-($-$$) db 0
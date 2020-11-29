db 'program', 0
db 'TERMINAL', 0
times 15 db 0

jmp $
times (512*2)-($-$$) db 0
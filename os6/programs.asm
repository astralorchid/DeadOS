%include '../programs/terminal.asm'
db 'program', 0
db 'ur mom', 0
times (512*2)-($-$$) db 0
db 'program', 0
db 'ENDLIST', 0
times (512*3)-($-$$) db 0
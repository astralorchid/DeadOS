;pdt - program descriptor table
;pdt starts at 0x0000:0x0500

pdt:
.map:
    push es
    mov ax, 0x0000
    mov es, ax
        call .readHead0
    pop es
    ret

.readHead0:
    mov bx, 1 ;Sector offset
    push bx
    .readLoop:
        mov dh, 0x00 ;head
        call [readProgram]
        call .isProgram
        pop bx
            cmp bx, 4
            je .readDone
            inc bx
        push bx
        jmp .readLoop
    .readDone:
ret

    .isProgram:
        mov cx, PROGRAM_STR_LEN  
        cld           
        mov si, PROGRAM_READ_OFFSET
        mov di, PROGRAM_STR
        repe cmpsb     
        cmp cx, 0
        je .equ_str 

        mov si, msg_noprogram
        call sprint
        call newLine
        ret

        .equ_str:
        mov si, msg_hasprogram
        call sprint
        call newLine
    ret
ret

PROGRAM_STR db 'program', 0
PROGRAM_STR_LEN equ $-PROGRAM_STR
msg_hasprogram db 'program found', 0
msg_noprogram db 'program not found', 0
SectorOffset db 1
MAX_SECTORS equ 63
PROGRAM_READ_OFFSET equ 0x1000
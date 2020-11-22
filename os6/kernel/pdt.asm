;pdt - program descriptor table
;pdt starts at 0x0000:0x0500

pdt:
    .map:
    push es
    mov ax, 0x0000
    mov es, ax
        mov ah, 0x02 ;read
        mov al, 0x01  ;#sectors
        mov ch, 0 ;cyl
        mov cl, 12 ;start from sector
        mov dh, 0x00 ;head
        mov dl, [DRIVE] ;drive
        mov bx, PROGRAM_READ_OFFSET;offset dest
        int 0x13

        mov ah, 0x0e
        mov al, [bx]
        int 0x10

        call .isProgram
    pop es
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

        ret

        .equ_str:
        mov si, msg_hasprogram
        call sprint
    ret
ret

PROGRAM_STR db 'program', 0
PROGRAM_STR_LEN equ $-PROGRAM_STR
msg_hasprogram db 'program found', 0
msg_noprogram db 'program not found', 0
SectorOffset db 1
MAX_SECTORS equ 63
PROGRAM_READ_OFFSET equ 0xF000
;pdt - program descriptor table
;pdt starts at 0x0000:0x0500

pdt:
    .map:
    mov ax, 0x0000
    mov es, ax
        mov ah, 0x02 ;read
        mov al, 0x01  ;#sectors
        mov ch, 0 ;cyl
        mov cl, 17 ;start from sector
        mov dh, 0x00 ;head
        mov dl, [DRIVE] ;drive
        mov bx, PROGRAM_READ_OFFSET;offset dest
        int 0x13

        call .isProgram

    ret

    .isProgram:
        mov cx, PROGRAM_STR_LEN  
        cld           
        mov si, [PROGRAM_READ_OFFSET]
        mov di, PROGRAM_STR
        repe cmpsb     
        cmp cx, 0
        je .equ_str 

        mov bx, PROGRAM_READ_OFFSET
        mov ax, word [ds:bx]
        cmp ax, 0x70
        je .equ_str

        mov si, msg_noprogram
        call sprint

        ret

        .equ_str:
        mov si, msg_hasprogram
        call sprint
    ret
ret

PROGRAM_STR db 'p', 0
PROGRAM_STR_LEN equ $-PROGRAM_STR
msg_hasprogram db 'program found', 0
msg_noprogram db 'program not found', 0
SectorOffset db 1
MAX_SECTORS equ 63
PROGRAM_READ_OFFSET equ 0x1000
;pdt - program descriptor table
;pdt starts at 0x0000:0x0500

pdt:
.map:
    push es
    mov ax, 0x0000
    mov es, ax

    ;mov ax, 1; pdt offset
    ;push ax
    cmp [IS_BOCHS], byte 1
    je .BochsDriver

    .RigDriver:

        mov [HEAD0_SECTORS], byte 10
        call .readHead0
        jmp .endDriver

    .BochsDriver:

        mov [HEAD0_SECTORS], byte 4
        call .readHead0
        ;call .readHeads

    .endDriver:
    pop es
ret

.readHead0:
    xor bh, bh ;clear bh
    mov bl, 1 ;Sector offset
    push bx

    .readLoop:
        mov dh, 0x00 ;head
        mov ah, 0; 0 - head0 check, 1 - all other heads
        call [readProgram]
        call .isProgram

            cmp bx, 0
        je .noProgramHead0
        
        call .PDTEntry
        call newLine

        .noProgramHead0:
        pop bx
            cmp bl, [HEAD0_SECTORS]
            je .readDone
            inc bl
        push bx
        jmp .readLoop
    .readDone:
ret

.readHeads:
    mov bh, 1; head
    mov bl, 1; sector
    push bx

    .mainReadLoop:
        mov dh, bh ;head
        mov ah, 1; 0 - head0 check, 1 - all other heads
        call [readProgram]
        call .isProgram

        cmp bx, 0
        je .noProgramHeads
        
        call .PDTEntry
        call newLine

        .noProgramHeads:
        pop bx
        cmp bl, 15
        jl .incSector
        je .incHead

    .incSector:
        inc bl
        push bx
        jmp .mainReadLoop

    .incHead:
        cmp bh, 1; amount of heads to read
        jl .moveHead
        je .endHead

    .moveHead:
        inc bh ;move head
        mov bl, 1 ;reset sector count
        push bx
        jmp .mainReadLoop

    .endHead:
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
        mov bx, 0
        ret

        .equ_str:
        mov si, msg_hasprogram
        call sprint
        call newLine
        mov bx, 1
    ret
ret

.PDTEntry:
    mov ax, PDT_OFFSET
    mov bx, PDT_START
    mov cx, 0

    .addPDTOffset:
        cmp cx, [PDT_ENTRY]
        je .addedPDTOffset
        add bx, ax ;bx = start of entry
        inc cx
        jmp .addPDTOffset

    .addedPDTOffset:
        mov al, [PDT_ENTRY]
        inc al
        mov [PDT_ENTRY], al
        mov ax, bx
        call hprep
        call hprint
ret

PROGRAM_STR db 'program', 0
PROGRAM_STR_LEN equ $-PROGRAM_STR
msg_hasprogram db 'program found', 0
msg_noprogram db 'program not found', 0
SectorOffset db 1
MAX_SECTORS equ 63
PROGRAM_READ_OFFSET equ 0x1000
HEAD0_SECTORS db 4
IS_BOCHS db 1
PDT_START equ 0x0500
PDT_OFFSET equ 2
PDT_ENTRY db 0
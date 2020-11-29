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

        mov [HEAD0_SECTORS], byte 6
        call .readHead0
        jmp .endDriver

    .BochsDriver:

        mov [HEAD0_SECTORS], byte 4 ;do not change
        call .readHead0
        call .readHeads

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
        jz .noProgramHead0

        call .PDTEntry
        call newLine

        .noProgramHead0:

            cmp [PDT_ENTRY], word 0
            jz NoPrograms_Error

            pop ax
            push ax

            mov bx, word [PDT_ENTRY]
            
            cmp [ds:bx], byte 1 ;funny sector exploit
            jg .contreadLoop
            add al, byte [KERNEL_SIZE]
            mov byte [ds:bx], al ;save start sector
            mov byte [ds:bx+1], ah ;save head
            
            pusha
            call hprep
            call hprint
            call newLine
            popa

            call writeProgramName

        .contreadLoop:
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
        jz .noProgramHeads

        call .PDTEntry
        call newLine

        .noProgramHeads:
            cmp [PDT_ENTRY], word 0
            jz NoPrograms_Error

            pop ax
            push ax

            cmp [ds:bx], byte 0 ;funny sector exploit
            jnz .contreadLoop2

            mov bx, word [PDT_ENTRY]

            mov byte [ds:bx], al
            mov byte [ds:bx+1], ah ;save head

            pusha
            call hprep
            call hprint
            call newLine
            popa

            call writeProgramName

        .contreadLoop2:
        pop bx
        cmp bl, 4 ;#sectors to read
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
        ;cld           
        mov si, PROGRAM_READ_OFFSET
        mov di, PROGRAM_STR
        rep cmpsb 

        cmp cx, 0
        jz .equ_str 

        mov si, msg_noprogram
        ;call sprint
        ;call newLine
        mov bx, 0
        ret

        .equ_str:
        mov si, msg_hasprogram
        ;call sprint
        ;call newLine
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

NoPrograms_Error:
    mov si, [NoproErrorStr]
    call sprint
    jmp $
ret

writeProgramName:
    pusha
    mov si, PROGRAM_READ_OFFSET+PROGRAM_STR_LEN
    mov di, ds:bx+2
    xor cx, cx
    .writePgrmNameByte:
        mov al, [si]
        mov [di], al

        cmp cx, word PROGRAM_NAME_MAXLEN
        je .endName
        inc cx

        cmp [si], byte 0
        je .endName
        inc si
        inc di
        jmp .writePgrmNameByte
    .endName:
        mov [di], byte 0 ;force null term
        mov si, ds:bx+2
        call sprint
        call newLine
    popa
ret

PROGRAM_STR db 'program', 0
PROGRAM_STR_LEN equ $-PROGRAM_STR
msg_hasprogram db 'program found', 0
msg_noprogram db 'program not found', 0
NoproErrorStr db 'PDT Entry Fail: No initial program.', 0
SectorOffset db 1
MAX_SECTORS equ 63
PROGRAM_READ_OFFSET equ 0x1000
HEAD0_SECTORS db 4
IS_BOCHS db 1
PDT_START equ 0x0500
PDT_OFFSET equ 10
PDT_ENTRY db 0
CURRENT_PDT_ENTRY db 0
PROGRAM_NAME_MAXLEN equ 8
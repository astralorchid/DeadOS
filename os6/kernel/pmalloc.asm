pmalloc:
push ds
push es
    xor ax, ax
    mov ds, ax
    ;es:di
    ;ds:si

    mov ax, 0x1000
    mov bx, word [SEGMENT_LIMIT]
    mov cx, word [SEGMENT_SIZE]

.checkForProgram:
    mov es, ax
    xor di, di
    mov si, PROGRAM_STR
    xor dh, dh
.cmpProgramLoop:
    mov dl, [di]
    cmp [si], dl
    jne .noProgramLoaded
    inc di
    inc si
    cmp [si], byte 0
    jz .programLoaded
    jmp .cmpProgramLoop
.programLoaded:
    add ax, 0x1000
    jmp .checkForProgram
.noProgramLoaded:
mov bx, ax
    .endpmalloc:
pop es
pop ds
ret

getPDTEntryByName:
push es
push ds
push ax
    xor ax, ax
    mov es, ax
    mov ds, ax

    mov bx, PDT_START
    .byName:
        cmp [bx], byte 0
        jz .endOfPDTbyName
        push bx ;save start
        inc bx
        inc bx

        mov si, bx
        mov di, ProgramToLoad
        mov cx, 8
        rep cmpsb

        cmp cx, 0
        jz .foundPDTbyName
        pop bx
        add bx, PDT_OFFSET
        jmp .byName

    .foundPDTbyName:
    pop bx
    jmp .endgetPDTEntryByName
.endOfPDTbyName:
mov bx, 0
.endgetPDTEntryByName:
pop ax
pop ds
pop es
ret

SEGMENT_START dw 0x1000
SEGMENT_LIMIT dw 0x7000
SEGMENT_SIZE dw 0x1000
ProgramToLoad:
    db 'TERMINAL', 0

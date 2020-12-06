pmalloc:
push ds
push es
    xor ax, ax
    mov ds, ax

    ;es:di
    ;ds:si

    mov ax, word [SEGMENT_START]
    mov bx, word [SEGMENT_LIMIT]
    mov cx, word [SEGMENT_SIZE]

    .checkForProgram:
    push ax
    push bx
    push cx

    mov es, ax
    mov bx, 0
    mov di, bx
    mov si, PROGRAM_STR
    mov cx, PROGRAM_STR_LEN

    rep cmpsb

    cmp cx, 0
    jz .isLoaded

    mov dx, ax
    pop cx
    pop bx
    pop ax
    mov bx, dx
    jmp .endpmalloc

    .isLoaded:
    pop cx
    pop bx
    pop ax

    add ax, cx
    cmp ax, bx
    jg .atMemoryLimit
    jmp .checkForProgram

    .atMemoryLimit:
    mov bx, 0
    .endpmalloc:
    cmp bx, 0
    jz pmallocFull
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


pmallocFull:
    mov si, OUT_OF_MEMORY
    call sprint
jmp $

OUT_OF_MEMORY db 'pmalloc: Out of memory', 0
SEGMENT_START dw 0x1000
SEGMENT_LIMIT dw 0x7000
SEGMENT_SIZE dw 0x1000
ProgramToLoad:
    db 'TERMINAL', 0

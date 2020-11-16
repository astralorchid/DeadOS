sprint:
    lodsb
    or al, al
    jz .end
    call charInt
    jmp sprint
    .end:
ret

charInt:
    mov ah, 0x0e
    mov bh, 0x00
    int 0x10
ret

clearScreen:
    call resetCursor

    mov cx, [CLEAR_AMOUNT]
    .repeat:
        cmp cx, 0
        je .done
        mov al, 0x00
        call charInt
        dec cx
        jmp .repeat
    .done:
    ;xor cx,cx
    call resetCursor
    ret

resetCursor: ;move cursor to 0,0 (top left)
    mov ah, 0x02
    mov bh, 0x00
    mov dh, 0x00
    mov dl, 0x00
    int 0x10
ret

getCursorPos:
    mov ah, 0x03 ;get cursor position
    mov bh, 0x00 ;
    int 0x10
ret

newLine:
    call getCursorPos
    mov ah, 0x02
    mov bh, 0x00
    inc dh
    mov dl, 0
    int 0x10
ret

getInitVideoMode:
    mov ah, 0x0f
    int 0x10
    mov [defaultVideoMode], al
ret

setInitVideoMode:
    mov ah, 0x00
    mov al, [defaultVideoMode]
    int 0x10
ret

;mov ax, 0x1337
;mov dx, ax
;xor cx, cx
;xor bx, bx

hprint:
    mov bx, hstring
    add bx, [hcounter]
    inc bx
    mov [bx], byte 0

    shl al, 4
    shr al, 4 ;isolate low nibble
    add al, 48
    cmp al, 58
    jl .isNum ;may be number
    add al, 7
    cmp al, 91
    jl .isChar
        .isNum:
            cmp al, 48 ;check if number
            jl .hloop ;not number
            push ax
            ;call charInt
        .isChar:
            cmp al, 65
            jl .hloop
            push ax
            ;call charInt
    .hloop:
        cmp cl, 1
        je .endh
        inc cl
        mov ax, dx
        ror al, 4
        jmp hprint
    .endh:
        cmp ch, 1
        je .highNib
        jg .endh2
        inc ch
        mov ax, dx
        ror ax, 8
        jmp hprint
    .highNib:
        inc ch
        mov ax, dx
        rol ax, 8
        rol al, 4
        jmp hprint
    .endh2:
        mov si, HEX_DEF
        call sprint
        mov bx, [hcounter]
        .getStack:
        cmp bx, 0
        je .endStack
        dec bx
        pop ax
        call charInt
        jmp .getStack
    .endStack:
ret



hw db 'Hello world!', 0
lastKey db 'a'
CLEAR_AMOUNT dw 1500
CURSOR_X db 0
CURSOR_Y db 0
hstring db 0
hcounter dw 4
HEX_DEF db '0x', 0
defaultVideoMode db 0 
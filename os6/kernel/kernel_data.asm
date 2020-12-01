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

;mov ax, 0x1337
hprep:
mov dx, ax
xor cx, cx
xor bx, bx
ret
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
    .drive:
        xor ah, ah
        mov al, byte [DRIVE]
        call hprep
        call hprint
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

;boot data
DRIVE db 0
DRIVE_STR db 'BOOT DRIVE: ', 0
RFT_STR db 'Returned from terminal', 0
KERNEL_SIZE_STR db 'KERNEL SECTORS: ', 0
;hprint data
hstring db 0
hcounter dw 4
HEX_DEF db '0x', 0
KERNEL_SIZE db 0x00
readProgram dw 0
loadProgram dw 0
;vga
defaultVideoMode db 0 
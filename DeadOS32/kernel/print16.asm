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

sprint16:
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
hprint16:
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
    jmp hprint16
.endh:
    cmp ch, 1
    je .highNib
    jg .endh2
    inc ch
    mov ax, dx
    ror ax, 8
    jmp hprint16
.highNib:
    inc ch
    mov ax, dx
    rol ax, 8
    rol al, 4
    jmp hprint16
.endh2:
    ;mov si, HEX_DEF
    ;call sprint
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

getCursorPos16:
    mov ah, 0x03 ;get cursor position
    mov bh, 0x00 ;
    int 0x10
ret

newLine16:
    pusha
    call getCursorPos16
    mov ah, 0x02
    mov bh, 0x00
    inc dh
    xor dl, dl
    int 0x10
    popa
ret

Print64BitMemMapEntry:
    add esi, 4
    call MemMapHprint

    sub esi, 4
    call MemMapHprint
    call newLine16
ret

h16:
    pusha
    call hprep
    call hprint16
    popa
ret

MemMapHprint:
    mov eax, dword [esi]
    ror eax, 16
    call h16
    ror eax, 16
    call h16
ret

MemMapErr:
    mov si, MEM_MAP_ERR
    call sprint16
    jmp $

hstring db 0
hcounter dw 4
defaultVideoMode db 0
MEM_MAP_ERR db 'Error building memory map', 0
MEM_MAP_SIZE dw 0
MEM_MAP_START equ 0x0500
MEM_MAP_ENTRY_BASE dd 0
MEM_MAP_ENTRY_SIZE dd 0
MEM_MAP_ENTRY_TYPE dd 0
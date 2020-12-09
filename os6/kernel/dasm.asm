dasm:

;ds:si - start of string
;es:di - token output
.tokenize:
xor ah, ah
mov al, byte 'B'
push ax
call .isChar
cmp ax, word 0
jz .notChar
pop ax
call .tokenFlagProc
ret
    .notChar:
    pop ax
    push ax
    call .isNum
    cmp ax, word 0
    jz .notNum
    pop ax
    call .tokenFlagProc
ret
    .notNum:
    pop ax
ret

;al - char
.isChar:
    cmp al, 122
    jl .mayBeChar
    jmp .clrcharflag
    .mayBeChar:
        cmp al, 97
        jl .mayBeUcase
        jmp .setcharflag
    .mayBeUcase:
        cmp al, 91
        jl .mayBeUcase2
    .mayBeUcase2:
        cmp al, 65
        jge .setcharflag 
    .clrcharflag:
    mov ax, word [TOKEN_FLAG]
    mov ch, 15
    call .clearWordBit
    mov word [TOKEN_FLAG], ax
    xor ax, ax ;return 0
    ret
.setcharflag:
    mov ax, word [TOKEN_FLAG]
    or ax, 1000000000000000b
    mov word [TOKEN_FLAG], ax
    xor ax, ax
    inc ax
ret

;al - num
.isNum:
    cmp al, 58
    jl .mayBeNum

    .mayBeNum:
        cmp al, 48
        jge .setnumflag
    .clrnumflag:
    mov ax, word [TOKEN_FLAG]
    mov ch, 14
    call .clearWordBit
    mov word [TOKEN_FLAG], ax
    xor ax, ax ;return 0
    ret
.setnumflag:
    mov ax, word [TOKEN_FLAG]
    or ax, 0100000000000000b
    mov word [TOKEN_FLAG], ax
    xor ax, ax
    inc ax
ret
;mov ax, word [TOKEN_FLAG]
;mov ch, 15 ;bit #
.clearWordBit:
    push ax
    mov cl, 15 ;max bits
    sub cl, ch ;steps needed to reach 15
    push cx    
    shl ax, cl ;move wanted bit to 15
    shr ax, 15 ;move wanted bit to 0
    cmp ax, word 0
    je .alreadyZero
    pop cx ;ch = bit #, cl = 15-ch
    pop bx ;original flag
    push bx
    mov ch, 15
    sub ch, cl ;bit #
    mov cl, ch ;opcode quirks
    shl ax, cl ;1 in bit #
    pop bx
    xor bx, ax
    mov ax, bx
    jmp .endClearWordBit
    .alreadyZero:
    pop cx
    pop ax
    .endClearWordBit:
ret

.startToken:
ret

.endToken:
ret

.tokenFlagProc:
mov ax, word [TOKEN_FLAG]
ret

TOKEN_FLAG dw 10b
TOKEN_FLAG_PROC:
dw dasm.startToken
dw 0
dw 1000000010000000b
dw 0100000010000000b
dw 0010000010000000b
dw dasm.endToken
dw 0
dw 0001010000000001b
dw 0001001000000001b
dw 0001000100000001b
dasm:

;ds:si - start of string
;es:di - token output
.tokenize:
xor ah, ah
mov al, [si]
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
    push ax
    call .isSymbol
    cmp ax, word 0
    jz .notSymbol
    pop ax
    call .tokenFlagProc
ret
    .notSymbol:
    pop ax
    push ax
    call .isSpace
    cmp ax, word 0
    jz .notSpace
    pop ax
    call .tokenFlagProc
ret
    .notSpace:
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
;al - symbol
.isSymbol:
    cmp al, 46
    je .setsymflag
    cmp al, 44
    je .setsymflag
    cmp al, 91
    je .setsymflag
    cmp al, 93
    je .setsymflag
    cmp al, 95
    je .setsymflag
    .clrsymflag:
    mov ax, word [TOKEN_FLAG]
    mov ch, 13
    call .clearWordBit
    mov word [TOKEN_FLAG], ax
    xor ax, ax ;return 0
    ret
.setsymflag:
    mov ax, word [TOKEN_FLAG]
    or ax, 0010000000000000b
    mov word [TOKEN_FLAG], ax
    xor ax, ax
    inc ax
ret

.isSpace:
    cmp al, 32
    je .setspaceflag
    cmp al, 9
    je .setspaceflag
    .clrspaceflag:
    mov ax, word [TOKEN_FLAG]
    mov ch, 12
    call .clearWordBit
    mov word [TOKEN_FLAG], ax
    xor ax, ax ;return 0
    ret
.setspaceflag:
    mov ax, word [TOKEN_FLAG]
    or ax, 0001000000000000b
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
    mov ax, word [TOKEN_FLAG]
    or ax, 0000000000000001b
    mov word [TOKEN_FLAG], ax
ret

.endToken:
    mov ax, word [TOKEN_FLAG]
    mov ch, 0
    call .clearWordBit
    mov word [TOKEN_FLAG], ax
ret

.nop:
ret

.tokenFlagProc:
mov ax, word [TOKEN_FLAG]
mov bx, TOKEN_FLAG_PROC
.TFPloop:
cmp ax, word [bx]
je .foundTokenFlag
cmp word [bx], 0xFFFF ;end of struct
je .endofTFP
inc bx
inc bx
jmp .TFPloop
.foundTokenFlag:
    cmp word [bx], word 0
    jz .tokenSubProc
    dec bx
    dec bx
    jmp .foundTokenFlag
    .tokenSubProc:
    dec bx
    dec bx
    call word [bx]
.endofTFP:
ret

.tokenFlagShift:
push ax
push bx
    mov ax, word [TOKEN_FLAG]
    push ax ;save flag for lower bits
    shr ax, 11
    shl ax, 6 ;move bits into prev bits
    pop bx
    shl bx, 10
    shr bx, 10
    or ax, bx
    mov word [TOKEN_FLAG], ax
pop bx
pop ax
ret

.incTotalTokens:
push ax
    mov ax, word [TOTAL_TOKENS]
    inc ax
    mov word [TOTAL_TOKENS], ax
pop ax
ret

TOKEN_FLAG dw 0000000000000000b
TOTAL_TOKENS dw 0
TOKEN_FLAG_PROC:
dw dasm.startToken
dw 0000000000000000b
dw 1000000010000000b ;is char prev space
dw 0100000010000000b ;is num prev space
dw 0010000010000000b ;is sym prev space
dw 1000000000000000b ;is char start of text
dw 0100000000000000b ;is num start of text
dw 0010000000000000b ;is sym start of text
dw dasm.endToken
dw 0000000000000000b
dw 0001010000000001b ;is space prev char on token
dw 0001001000000001b ;is space prev num on token
dw 0001000100000001b ;is space prev sym on token
dw dasm.nop
dw 0001000000000000b
dw 1111111111111111b ;end of struct
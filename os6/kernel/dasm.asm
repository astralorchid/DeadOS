dasm:

.tokenizeCharLoop:
cmp [si], byte 0x00
je .endasmFile
.startasmFile:
    ;save prev bit 0 in cx (edit: why did i say this?)
    mov ax, word [TOKEN_FLAG]
    bt ax, 0
    jc .onToken
    xor cx, cx
    jmp .gotPrevTokenState
    .onToken:
    xor cx, cx
    inc cx

    .gotPrevTokenState:
    push cx
        call dasm.tokenize

        push ax
        mov dh, byte [TOKEN_FLAG+1]
        call bprint
        mov dh, byte [TOKEN_FLAG]
        call bprint
        pop ax

        call dasm.tokenFlagShift
        mov ax, word [TOKEN_FLAG]
    pop cx

    bt ax, 0
    jc .nowOnToken
    
    cmp cx, 0
    jz .stillOffTokenNOP ;new and prev = 0
        ;prev = 0 new = 1
    ;end of token (at the space)
    ;si and di are equal here
    
    jmp .stillOnToken
    .stillOffTokenNOP: ;new = 0
    ;nop
    ;call newLine
    jmp .incsi
    .nowOnToken: ;new = 1
    cmp cx, 1
    je .stillOnToken

    .stillOnToken:

    push ax ;just for charint
        mov al, [si]
        mov [di], al

        cmp [di], byte 0x0D
        jne .changeR

        mov [si], byte 0x0D

        mov [di], byte ' '
        inc di
        mov [di], byte 59
        inc di
        mov [di], byte ' '

        .changeR:
    
        push ax
        mov al, byte ' '
        call charInt
        pop ax

        call charInt
        ;call newLine
    pop ax

        inc di
    .incsi:
    inc si
    jmp .tokenizeCharLoop
.endasmFile:
mov [di], byte ' '
mov [di+1], byte 0
;pop es
;pop ds
ret

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
    push ax
    call .isReturn
    cmp ax, word 0
    jz .notReturn
    pop ax
    call .tokenFlagProc
ret
    .notReturn:
    pop ax
ret

.isReturn:
    cmp al, 0x0D
    je .setretflag
    .clrretflag:
    mov ax, word [TOKEN_FLAG]
    mov ch, 11
    call .clearWordBit
    mov word [TOKEN_FLAG], ax
    xor ax, ax ;return 0
    ret
.setretflag:
    mov ax, word [TOKEN_FLAG]
    or ax, 0000100000000000b
    mov word [TOKEN_FLAG], ax
    xor ax, ax
    inc ax
ret
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
        je .setsymflag
        jg .isSymbol
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
    je .setsymflag
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

.spaceBefore:
push ax
;mov al, [di]
mov [di], byte ' '
inc di
pop ax
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

.onReturn:
call dasm.endToken
jmp .onToken

TOKEN_FLAG dw 0000000000000000b
INST_FLAG dw 0b
LINE_NUMBER dw 0
OPCODE db 00000000b
MODRM db 00000000b
MNEM_0OP:
db 'nop ',  10010000b
db 'pusha ',01100000b
db 'popa ', 01100001b
db 'cmpsb ',10100110b
db 'cmpsw ',10100111b
db 'movsb ',10100100b
db 'movsw ',10100101b
db 'scasb ',10101110b
db 'scasw ',10101111b
db 'ret ',  11000011b
db 'retf ', 11001011b
db 0
MNEM_1OP:
db 'inc ',01000000b ;byte [] 11111110 word [] 11111111 w/ modrm
db 'dec '
db 'call '
db 'jmp '
db 'push '
db 'pop '
db 'int '
db 'not '
db 'neg '
db 'jo '
db 'jno '
db 'jb '
db 'jnae '
db 'jc '
db 'jnb '
db 'jae '
db 'jnc '
db 'jz '
db 'je '
db 'jnz '
db 'jne '
db 'jbe '
db 'jna '
db 'jnbe '
db 'ja '
db 'js '
db 'jns '
db 'jp '
db 'jpe '
db 'jnp '
db 'jpo '
db 'jl '
db 'jnge '
db 'jnl '
db 'jge '
db 'jle '
db 'jng '
db 'jnle '
db 'jg '
db 'daa '
db 0
MNEM_2OP:
db 'mov ',10001000b
db 'xor ',00110000b
db 'cmp ',00111000b
db 'add ',00000000b
db 'or ',00001000b
db 'adc '
db 'sbb '
db 'and ',00100000b
db 'sub ',00101000b
db 'das '
db 'aaa '
db 'aas '
db 'ins '
db 'insb '
db 'insw '
db 'outs '
db 'outsb '
db 'ouisw '
db 'test ',10000100b
db 'xchg '
db 'lea '
db 'rol '
db 'ror '
db 'rcl '
db 'rcr '
db 'shl '
db 'sal '
db 'shr '
db 'sar '
db 0
TOKEN_FLAG_PROC:
dw dasm.startToken
dw 0000000000000000b
dw 1000000010000000b ;is char prev space
dw 0100000010000000b ;is num prev space
dw 0010000010000000b ;is sym prev space
dw 1000000000000000b ;is char start of text
dw 0100000000000000b ;is num start of text
dw 0010000000000000b ;is sym start of text

dw 1000000001000000b
dw 0100000001000000b
dw 0010000001000000b
dw 0001000001000000b

;dw 0000110000000000b
dw dasm.endToken
dw 0000000000000000b
dw 0001010000000001b ;is space prev char on token
dw 0001001000000001b ;is space prev num on token
dw 0001000100000001b ;is space prev sym on token

dw dasm.spaceBefore
dw 0000000000000000b
dw 0010010000000001b ;is sym prev char on token
dw 1000000100000001b ;is char prev sym on token
dw 0010001000000001b ;is sym prev char on token
dw 0100000100000001b ;is char prev sym on token

dw dasm.onReturn
dw 0000000000000000b

;dw 0000110000000001b
;dw 0000101000000001b
;dw 0000100100000001b
;dw 0000100010000001b

dw dasm.nop
dw 0000000000000000b
dw 0001000000000000b
;dw 0001001000000000b
dw 1111111111111111b ;end of struct
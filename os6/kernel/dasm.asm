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

        ;push ax
        ;mov dh, byte [TOKEN_FLAG+1]
        ;call bprint
        ;mov dh, byte [TOKEN_FLAG]
        ;call bprint
        ;pop ax

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
    
        ;push ax
        ;mov al, byte ' '
        ;call charInt
        ;pop ax

        ;call charInt
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
    call .tokenFlagProc
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

.pass2:
    mov si, di ;move tokens to si
    .startReadToken:
    mov di, tokenToAssemble
    push di
    .readToken:
    cmp [si], byte 0
    jz .pass2Done
    cmp [si], byte 59
    je .endofInst
    cmp [si], byte ' '
    je .endpass2Token
    movsb
    jmp .readToken

    .endpass2Token:
    cmp [si-1], byte ' '
    je .emptyToken
    movsb
    pop di

    push si
    mov si, di
    call sprint
    pop si

    call dasm.assembleToken
    call .clearToken

    jmp .startReadToken
    .emptyToken:
    call .clearToken
    inc si
    inc di
    pop di
    jmp .startReadToken

    .endofInst:
    call .handleInstFlag
    pop di
    jmp .startReadToken
    .pass2Done:
    cmp word [INST_FLAG], 0
    jz .lastInstProcessed
    call .handleInstFlag
    .lastInstProcessed:
    pop di
    call newLine
ret

.testDualMemErr:
    push ax
    xor ax, ax
    bt word [INST_FLAG], 5
    jc .incDual1
    .incDual2:
        bt word [INST_FLAG], 6
        jc .incDual3
        jmp .checkDualMem
    .incDual1:
        inc ax
        jmp .incDual2
    .incDual3:
        inc ax
    .checkDualMem:
        cmp ax, word 1
        jg .DualMemErr
        pop ax
    ret
    .DualMemErr:
        or word [INST_ERR_FLAG], 100b
        pop ax
    ret

    .testOpenMemErr:
        bt word [INST_FLAG], 12
        jnc .NoSetOpenMemError
        or word [INST_ERR_FLAG], word 10b
    .NoSetOpenMemError:
ret

.handleInstFlag:
call .testDualMemErr
call .testOpenMemErr
    pusha
    mov dh, byte [INST_FLAG+1]
    call bprint
    mov dh, byte [INST_FLAG]
    call bprint
    mov al, byte ' '
    call charInt
    popa

    pusha
    mov dh, byte [INST_ERR_FLAG+1]
    call bprint
    mov dh, byte [INST_ERR_FLAG]
    call bprint
    popa

    pusha
        mov al, byte ' '
        call charInt
        xor ah, ah
        mov al, byte [OPCODE]
        call hprep
        call hprint
    popa

    pusha
        mov al, byte ' '
        call charInt
        mov dh, byte [RM]
        call bprint
        mov al, byte ' '
        call charInt
        mov dh, byte [REG]
        call bprint
    popa

    call .clearToken
    inc si
    inc si

    call newLine

    mov ax, word [LINE_NUMBER]
    inc ax
    mov word [LINE_NUMBER], ax

    mov word [INST_FLAG], 0
    ;mov word [INST_ERR_FLAG], 0
    mov byte [OPCODE], 0
    mov byte [OPERANDS], 0
    mov byte [RM], 0
    mov byte [REG], 0
ret

.clearToken:
    push ax
    push di
    mov al, 0x00
    mov di, tokenToAssemble
    mov cx, 32
    rep stosb
    pop di
    pop ax
ret

.assembleToken:

bt word [INST_FLAG], 0
jc .hasInst
jmp .noInst
bt word [INST_FLAG], 1
jc .hasInst
jmp .noInst
bt word [INST_FLAG], 2
jc .hasInst
jmp .noInst

    .noInst:
pusha
    mov si, di
    mov di, MNEM_0OP

    mov bx, OPCODE
    call .useMnemStruct

    cmp ax, 0
    jz .Not0OP
    or [INST_FLAG], byte 1
    .Not0OP:
popa
pusha
    mov si, di
    mov di, MNEM_1OP

    mov bx, OPCODE
    call .useMnemStruct
    cmp ax, 0
    jz .Not1OP
    or [INST_FLAG], byte 2
    .Not1OP:
popa
pusha
    mov si, di
    mov di, MNEM_2OP

    mov bx, OPCODE
    call .useMnemStruct
    cmp ax, 0
    jz .Not2OP
    or [INST_FLAG], byte 4
    .Not2OP:
popa

.hasInst:
    push di
    mov di, tokenToAssemble
    cmp [di], byte '['
    je .isOpenMemToken
    cmp [di], byte ']'
    je .isCloseMemToken
    jmp .notOpenMemToken
    .isOpenMemToken:
    or word [INST_FLAG], word 1000000000000b
    pop di
ret
    .isCloseMemToken:
    mov ax, word [INST_FLAG]
    mov ch, 12
    call .clearWordBit
    mov word [INST_FLAG], ax
    pop di
;popa
ret
    .notOpenMemToken:
    bt word [INST_FLAG], 12
    jc .isMemToken
    pop di
    jmp .notMemRegister
;popa
ret

.isMemToken:
pop di
    cmp byte [OPERANDS], byte 1
    jl .is1stOperand
    je .is2ndOperand
ret
    .is1stOperand:
    or word [INST_FLAG], word 100000b
    jmp .getOperandType
    .is2ndOperand:
    or word [INST_FLAG], word 1000000b
    .getOperandType:
    add [OPERANDS], byte 1
    mov al, [RM]
    mov [REG], al
    pusha
    mov si, di
    mov di, REGISTERS
    mov bx, RM
    call .useRegStruct
    cmp ax, 0
    jg .endIsMemToken

    jmp .notMemRegister
    .endIsMemToken:
popa
ret
    .notMemRegister:

    bt word [INST_FLAG], 5
    jc .RMUsed
    bt word [INST_FLAG], 6
    jc .RMUsed
    cmp byte [OPERANDS], 1
    je .RMUsed

    pusha
    mov si, di
    mov di, REGISTERS

    mov bx, RM
    call .useRegStruct
    cmp ax, 0
    jz .NotReg
    add byte [OPERANDS], 1
popa
    call .setRegOpSize
ret
    .RMUsed:

    pusha
    mov si, di
    mov di, REGISTERS

    mov bx, REG
    call .useRegStruct
    cmp ax, 0
    jz .NotReg
    add byte [OPERANDS], 1
    popa
    call .setRegOpSize
    ret
    .NotReg:
popa
ret

.setRegOpSize:
pusha
    mov si, di
    mov di, WORD_REG

    mov bx, DUMP
    call .useRegStruct
    cmp ax, 0
    jz .NotWordReg
    cmp byte [OPERANDS], 1
    je .SetOp1Size
    jg .SetOp2Size
    jl .NotWordReg
    .SetOp1Size:
    or word [INST_FLAG], word 1000b
    jmp .NotWordReg
    .SetOp2Size:
    or word [INST_FLAG], word 10000b
    .NotWordReg:
popa
ret


.useRegStruct:
    mov dx, si
    .cmpRegChar:

    mov ah, byte [si]
    mov al, byte [di]

    cmp ah, al
    jne .gotoNextReg
    cmp [di], byte ' '
    je .endOfReg
    cmp [di], byte 0
    jz .endOfRegStruct
    inc si
    inc di
    jmp .cmpRegChar
    .gotoNextReg:
    cmp [di], byte ' '
    je .jumpOver
    cmp [di], byte 0
    je .endOfRegStruct
    inc di
    jmp .gotoNextReg
    .jumpOver:
    inc di
    inc di
    mov si, dx
    jmp .cmpRegChar
    .endOfReg:
    mov al, [di+1]
    dec al
    mov [bx], al
    xor ax, ax
    inc ax
ret
    .endOfRegStruct:

    xor ax, ax
ret

.useMnemStruct:
    .cmpMnemChar:

    mov ah, byte [si]
    mov al, byte [di]

    cmp ah, al
    jne .notequalChar

    cmp al, byte ' '
    je .endOfMnem

    inc si
    inc di
    jmp .cmpMnemChar
    .notequalChar:
    cmp [di], byte ' '
    je .jmpToNextMnem
    cmp [di], byte 0
    jz .endOfMnemStruct
    ;jmp .jmpToNextMnem
    .getToMnemEnd:
    inc di
    cmp [di], byte ' '
    je .jmpToNextMnem
    cmp [di], byte 0
    jz .endOfMnemStruct
    jmp .getToMnemEnd
    .jmpToNextMnem:
    inc di
    inc di
    jmp .cmpMnemChar
    .endOfMnem:
    push ax
    mov al, [di+1]
    mov [bx], al ;used to be [OPCODE]
    pop ax
    xor ax, ax
    inc ax
ret
    .endOfMnemStruct:
    xor ax, ax
ret

TOKEN_FLAG dw 0000000000000000b
INST_ERR_FLAG dw 0
INST_FLAG dw 0b
LINE_NUMBER dw 0
OPCODE db 00000000b
OPERANDS db 0
REG db 0
RM db 0
MODRM db 0
DUMP db 0
HEX_PREFIX db '0x',0
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
db 'dec ',1
db 'call ',1
db 'jmp ',1
db 'push ',1
db 'pop ',1
db 'int ',1
db 'not ',1
db 'neg ',1
db 'jo ',1
db 'jno ',1
db 'jb ',1
db 'jnae ',1
db 'jc ',1
db 'jnb ',1
db 'jae ',1
db 'jnc ',1
db 'jz ',1
db 'je ',1
db 'jnz ',1
db 'jne ',1
db 'jbe ',1
db 'jna ',1
db 'jnbe ',1
db 'ja ',1
db 'js ',1
db 'jns ',1
db 'jp ',1
db 'jpe ',1
db 'jnp ',1
db 'jpo ',1
db 'jl ',1
db 'jnge ',1
db 'jnl ',1
db 'jge ',1
db 'jle ',1
db 'jng ',1
db 'jnle ',1
db 'jg ',1
db 'daa ',1
db 0
MNEM_2OP:
db 'mov ',10001000b
db 'xor ',00110000b
db 'cmp ',00111000b
db 'add ',00000000b
db 'or ',00001000b
db 'adc ',1
db 'sbb ',1
db 'and ',00100000b
db 'sub ',00101000b
db 'das ',1
db 'aaa ',1
db 'aas ',1
db 'ins ',1
db 'insb ',1
db 'insw ',1
db 'outs ',1
db 'outsb ',1
db 'ouisw ',1
db 'test ',10000100b
db 'xchg ',1
db 'lea ',1
db 'rol ',1
db 'ror ',1
db 'rcl ',1
db 'rcr ',1
db 'shl ',1
db 'sal ',1
db 'shr ',1
db 'sar ',1
db 0
REGISTERS:
db 'al ', 00000001b
db 'ax ', 00000001b
db 'cl ', 00000010b
db 'cx ', 00000010b
db 'dl ', 00000011b
db 'dx ', 00000011b
db 'bl ', 00000100b
db 'bx ', 00000100b
db 'ah ', 00000101b
db 'sp ', 00000101b
db 'ch ', 00000110b
db 'bp ', 00000110b
db 'dh ', 00000111b
db 'si ', 00000111b
db 'bh ', 00001000b
db 'di ', 00001000b
db 0
WORD_REG:
db 'ax ', 00000001b
db 'cx ', 00000010b
db 'dx ', 00000011b
db 'bx ', 00000100b
db 'sp ', 00000101b
db 'bp ', 00000110b
db 'si ', 00000111b
db 'di ', 00001000b
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
dw 0010000100000001b
dw dasm.nop
dw 0000000000000000b
dw 0001000000000000b

dw 1111111111111111b ;end of struct


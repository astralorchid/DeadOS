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
    ;jmp .tokenizeCharLoop ;59 issue
    .stillOnToken:
    or word [TOKEN_FLAG], 1b ;bugfix
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
    ;mov word [TOKEN_FLAG], 0 ;clear to use w/ inst flag
    call .handleInstFlag
    pop di
    cmp ax, 0
    jnz .retWithErr

    jmp .startReadToken
    .pass2Done:
    cmp word [INST_FLAG], 0
    jz .lastInstProcessed
    ;mov word [TOKEN_FLAG], 0
    call .handleInstFlag
    cmp ax, 0
    jnz .retWithErr

    .lastInstProcessed:
    pop di
    call newLine
    xor ax, ax
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
    
.testDualImmOperands:
    push ax
    push bx
    mov ax, word [INST_FLAG]
    mov bx, ax
    or ax, 110000000b
    xor ax, bx
    jnz .popleave
    mov ax, word [INST_FLAG]
    shl ax, 6
    shr ax, 14
    and ax, 11b
    jz .popleave
    .DualImmErr:
    bt word [INST_FLAG], 5
    jc .popleave
    bt word [INST_FLAG], 6
    jc .popleave
    or word [INST_ERR_FLAG], 1000b
    .popleave:
    pop bx
    pop ax
    ret

.testOpSizeMismatch: ;also applies operand size mods
    push ax
    push bx
        mov ax, word [INST_FLAG]
        shl ax, 1
        shr ax, 14
        shl ax, 3
        or word [INST_FLAG], ax
        mov ax, word [INST_FLAG]
        shl ax, 11 ;op 2
        shr ax, 15
        mov bl, al
        mov ax, word [INST_FLAG]
        shl ax, 12 ;op 1
        shr ax, 15
        mov bh, al
        cmp bl, bh
        jne .opSizeMismatch
        jmp .endMismatch
        .opSizeMismatch:
        or word [INST_ERR_FLAG], 10000b
        .endMismatch:
    pop bx
    pop ax
ret

.testDualSegErr: ;also test sreg with mov opcode
    push ax
    push bx
    mov bx, word [INST_FLAG_2]
    mov ax, word [INST_FLAG]
    shr ax, 15
    cmp bx, ax
    jne .NotDualSeg
    cmp ax, 1
    jne .NotDualSeg
    or word [INST_ERR_FLAG], 100000b
    .NotDualSeg:
    add ax, bx
    cmp ax, 1b
    jne .endSregErr
    cmp byte [OPCODE], 0x88
    je .endSregErr
    or word [INST_ERR_FLAG], 100000b
    .endSregErr:
    pop bx
    pop ax
ret

.testSregAsMemErr:
push ax
push bx
xor ax, ax
mov bx, word [INST_FLAG]
shr bx, 15
add ax, bx

mov bx, word [INST_FLAG]
shl bx, 10
shr bx, 15
add ax, bx
cmp ax, 10b
je .SregMemErr
jmp .noSregMemErr
xor ax, ax
mov bx, word [INST_FLAG_2]
shl bx, 15
shr bx, 15
add ax, bx

mov bx, word [INST_FLAG]
shl bx, 11
shr bx, 15
add ax, bx
cmp ax, 10b
jne .noSregMemErr
.SregMemErr:
or word [INST_ERR_FLAG], 100000b
.noSregMemErr:
pop bx
pop ax
ret

.handleInstFlag:
call .testDualMemErr
call .testOpenMemErr
call .testDualImmOperands
call .testOpSizeMismatch
call .testDualSegErr
call .testSregAsMemErr

cmp word [INST_ERR_FLAG], 0
jnz .retWithErr 
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

    pusha
    mov si, LBL_DEF
    mov di, SYMBOL_TABLE
    call .parseLabels
    popa

    bt word [INST_FLAG_2], 2
    cmovc ax, word [END_BIN]
    jnc .skipEntryOffset
    mov word [ENTRY_OFFSET], ax
    .skipEntryOffset:

    pusha
    push es
    push ds
    mov ax, 0x6000
    mov es, ax
    mov ax, 0x1000
    mov ds, ax
    xor di, di
    call assembleInstruction
    pop ds
    pop es
    popa

    call .clearToken
    inc si
    inc si

    pusha
    mov si, LBL_DEF
    call sprint
    popa

    pusha
    mov si, SYMBOL_TABLE
    call sprint
    popa
    call newLine

    mov ax, word [LINE_NUMBER]
    inc ax
    mov word [LINE_NUMBER], ax

    mov word [INST_FLAG], 0
    mov word [INST_FLAG_2], 0
    ;mov word [INST_ERR_FLAG], 0
    mov byte [OPCODE], 0
    mov byte [OPERANDS], 0
    mov byte [RM], 0
    mov byte [REG], 0
    mov word [IMM_OP1], 0
    mov word [IMM_OP2], 0

    ;clear LBL_DEF
    push ax
    push di
    mov al, 0x00
    mov di, LBL_DEF
    mov cx, 100
    rep stosb
    pop di
    pop ax

    xor ax, ax ;ret 0
ret
.retWithErr:
    xor ax, ax
    inc ax
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
cmp [di], byte ','
jne .startassembleToken
ret
.startassembleToken:
bt word [INST_FLAG], 0
jc .hasInst
jmp .noInst
bt word [INST_FLAG], 1
jc .hasInst
jmp .noInst
bt word [INST_FLAG], 2
jc .hasInst
jmp .noInst

;dx - 0 - no ret, 1 - ret
    .noInst:
pusha
    mov si, di
    mov di, MNEM_0OP

    mov bx, OPCODE
    xor ax, ax
    xor dh, dh
    call .useMnemStruct

    cmp ax, 0
    jz .Not0OP
    or [INST_FLAG], byte 1
    popa
    ret
    .Not0OP:
popa
pusha
    mov si, di
    mov di, MNEM_1OP

    mov bx, OPCODE
    xor ax, ax
    xor dh, dh
    call .useMnemStruct

    cmp ax, 0
    jz .Not1OP
    or [INST_FLAG], byte 2
    popa
    ret
    .Not1OP:
popa
pusha
    mov si, di
    mov di, MNEM_2OP

    mov bx, OPCODE
    xor ax, ax
    xor dh, dh
    call .useMnemStruct

    cmp ax, 0
    jz .Not2OP
    or [INST_FLAG], byte 4
    popa
    ret
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
    popa
    xor ax, ax
    call .checkImm
    cmp ax, 0
    jz .PosImmLbl
    
ret
    ;jmp .notMemRegister
    .endIsMemToken:
popa
    call .checkSReg
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
    call .checkSReg
ret
    .RMUsed:

    ;

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
    call .checkSReg
    ret
    .NotReg:
popa
    xor ax, ax
    inc ax
    call .checkImm
    cmp ax, 0
    jz .NotImm
ret
    .NotImm:
    pusha
    mov si, di
    mov di, SIZE_DEF

    mov bx, DUMP
    call .useRegStruct
    cmp ax, 0
    jz .PosLbl ;.NotSizeDef
    cmp [OPERANDS], byte 1
    jl .SizeModOp1
    shl byte [DUMP], 6
    jmp .xorToInstFlag
    .SizeModOp1:
    shl byte [DUMP], 5
    .xorToInstFlag:
    mov ah, byte [DUMP]
    xor al, al
    or word [INST_FLAG], ax
    popa
ret
    .NotSizeDef:
    cmp [OPERANDS], byte 1
    jl .PosLbl
    popa
ret
    .PosLbl:
    mov ah, 0
    call .storeLbl

    add byte [OPERANDS], 1
    popa
    .PosImmLbl:
    bt word [INST_FLAG], 1
    jc .OpLbl
    bt word [INST_FLAG], 2
    jc .OpLbl
    or word [INST_FLAG], 100100000000b
ret
    .OpLbl:
    cmp byte [OPERANDS], 1
    cmove ax, word [OP1LBL_MASK]
    cmovg ax, word [OP2LBL_MASK]
    or word [INST_FLAG], ax
    mov ah, 1
    call .storeLbl
ret
;    .OpLbl:
;    cmp byte [OPERANDS], 1
;    je .Op1Lbl
;    jg .Op2Lbl
;ret
;    .Op1Lbl:
;    mov ah, 1
;    call .storeLbl
;    or word [INST_FLAG], 1010000000b
;ret
;    .Op2Lbl:
;    mov ah, 1
;    call .storeLbl
;    or word [INST_FLAG], 10100000000b
;ret

;ah - 0 = def lbl, 1 - op lbl
.storeLbl:
pusha
    mov di, LBL_DEF
    .getLblDefOffset:
    cmp [di], byte 0x0
    jz .storeLblLoop
    inc di
    jmp .getLblDefOffset
    .storeLblLoop:
    cmp [si], byte ' '
    je .endStoreLbl
    cmp [si], byte ']'
    je .putItInReverseTerry
    .storeLblMov:
    movsb
    jmp .storeLblLoop
    .endStoreLbl:
    movsb
    xor dx, dx
    xor bx, bx
    inc dx
    cmp ah, byte 0
    cmovnz bx, dx
    xor bx, 1
    mov al, byte [OPERANDS]
    add ax, bx
    mov [di], al
popa
ret

.putItInReverseTerry:
    push ax
    xor ax, ax
    .reverseCmp:
    dec si
    cmp [si], byte ' '
    je .checkSpace
    jmp .reverseCmp
    .checkSpace:
    cmp al, byte 0
    jnz .endReverse
    inc al
    jmp .reverseCmp
    .endReverse:
    pop ax
jmp .storeLblMov

;mov ax 0 - mem, 1 - not mem
.checkImm:
pusha
pushf
    cld
    mov si, di
    mov di, HEX_PREFIX
    cmpsb
    jne .endcheckImm0
    cmpsb
    jne .endcheckImm0
    cmp ax, 0
    jz .immMem
    add byte [OPERANDS], 1
    .immMem:
    cmp byte [OPERANDS], 1
    je .SetOp1Imm
    jg .SetOp2Imm
    .SetOp1Imm:
    popf
    popa
    pusha
    xor ax, ax
    call .storeImm
    ; call .GetImmOpcode

    or word [INST_FLAG], 10000000b
    jmp .endcheckImm1
    .SetOp2Imm:
    popf
    popa
    pusha
    xor ax, ax
    inc ax
    call .storeImm
    ;call .GetImmOpcode

    or word [INST_FLAG], 100000000b
    .endcheckImm1:
popa
    xor ax, ax
    inc ax
ret
    .endcheckImm0:
popf
popa
    xor ax, ax
ret

;ax - mnem struct
.GetImmOpcode:
    pusha
    mov si, di
    mov di, MNEM_0OP ;include all mnem structs
    mov bx, OPCODE
    mov dh, byte 1
    mov dl, byte 1
    xor ax, ax
    call .useMnemStruct
    mov si, di
    mov di, MNEM_1OP ;include all mnem structs
    mov bx, OPCODE
    mov dh, byte 1
    mov dl, byte 1
    xor ax, ax
    call .useMnemStruct
    mov si, di
    mov di, MNEM_2OP ;include all mnem structs
    mov bx, OPCODE
    mov dh, byte 1
    mov dl, byte 1
    xor ax, ax
    call .useMnemStruct
    popa
ret

.GetImmOpcodeExt:
    pusha
    mov si, di
    mov di, MNEM_0OP ;include all mnem structs
    mov bx, REG
    mov dh, byte 1
    mov dl, byte 2
    xor ax, ax
    call .useMnemStruct
    mov si, di
    mov di, MNEM_1OP ;include all mnem structs
    mov bx, REG
    mov dh, byte 1
    mov dl, byte 2
    xor ax, ax
    call .useMnemStruct
    mov si, di
    mov di, MNEM_2OP ;include all mnem structs
    mov bx, REG
    mov dh, byte 1
    mov dl, byte 2
    xor ax, ax
    call .useMnemStruct
    popa
ret

;ax = 0 - Immediate op 1, 1 - Immediate op 2
.storeImm:
    cmp ax, 0
    jz .storeIn1
    jnz .storeIn2
    .storeIn1:
    mov bx, IMM_OP1
    jmp .storeImmLoop
    .storeIn2:
    mov bx, IMM_OP2
    .storeImmLoop:
    mov al, [di+HEX_PREFIX_LEN]
    
    cmp al, ' '
    je .endStoreImm
    cmp al, 48
    jl .endStoreImmErr
    cmp al, 57
    jle .isImmNum
    cmp al, 65
    jl .endStoreImmErr
    cmp al, 70
    jle .isImmChar

    .endStoreImmErr:
    xor ax, ax
    inc ax
    ret

    .isImmNum:
    sub al, 48
    jmp .addToStoredImm

    .isImmChar:
    sub al, 55
    jmp .addToStoredImm
    
    .endStoreImm:
    xor ax, ax
ret

.addToStoredImm:
    mov dx, word [bx]
    shl dx, 4
    or dl, al
    mov word [bx], dx
    inc di
jmp .storeImmLoop

.checkSReg:
pusha
cmp [di+1], byte 's'
jne .NotSreg
cmp [OPERANDS], byte 1
je .Op1Sreg
jg .Op2Sreg
jmp .NotSreg
.Op1Sreg:
or word [INST_FLAG], 1000000000000000b
jmp .NotSreg
.Op2Sreg:
or word [INST_FLAG_2], 0b
.NotSreg:
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

;ax - 0-#opcodes
;dh - 0 - start from mnem, 1 - start from base opcode
;dl - offset from opcode to return
.useMnemStruct:
    push ax
    cmp dh, byte 0
    jz .findByMnem

.findByOpcode:
    mov al, byte [OPCODE]
    .findMnemEnd:
    cmp [di], byte ' '
    je .getOpcode
    inc di
    jmp .findMnemEnd
    .getOpcode:
    inc di
    cmp al, [di]
    je .foundOpcode
    add di, word NUM_DATA
    dec di
    cmp [di], byte 0
    jz .foundNoOpcode
    jmp .findMnemEnd
    .foundOpcode:
    xor dh, dh
    add di, word dx ;extended dl
    mov ah, byte [di]
    mov [bx], ah ;update base opcode
    pop ax
    xor ax, ax
    inc ax ;return 1
ret
    .foundNoOpcode:
    pop ax
    xor ax, ax ;return 0
ret

    .findByMnem:
    mov dx, si
    .cmpMnemChar:
    mov ah, byte [si]
    mov al, byte [di]
    cmp ah, al
    jne .gotoNextMnem
    cmp [di], byte ' '
    je .endOfMnem
    cmp [di], byte 0
    jz .endOfMnemStruct
    inc si
    inc di
    jmp .cmpMnemChar
    .gotoNextMnem:
    cmp [di], byte ' '
    je .jumpOverMnem
    cmp [di], byte 0
    jz .endOfMnemStruct
    inc di
    jmp .gotoNextMnem
    .jumpOverMnem:
    add di, word NUM_DATA
    inc di
    mov si, dx
    jmp .cmpMnemChar
    .endOfMnem:
    pop ax
    add di, ax
    mov al, [di+1]
    ;dec al
    mov [bx], al
    xor ax, ax
    inc ax
ret
    .endOfMnemStruct:
    pop ax
    xor ax, ax
ret

;si = label def table
;di = symbol table start
.parseLabels:
xor cx, cx

    cmp [si], byte 0
    je .endparseLbls

    bt word [INST_FLAG], 11
    jnc .normalLbl

    mov al, 2
    call .findLbl
    cmp ax, word 0
    jnz .found2ndLbl
    ;error here
    ret
    .found2ndLbl:
    push si
    mov si, ax

    push di
    push dx

    mov dx, si ;save si
    mov di, DEFINE_TYPES ;use di for struct ptr
    
    .cmpLbl2prep:
    mov si, dx
    .cmpLbl2:
    cmp [si], byte ' '
    je .endCmpLbl2

    mov al, [di]
    cmp [si], al
    jne .cmpLbl2ne
    inc si
    inc di
    jmp .cmpLbl2
    .cmpLbl2ne:
    inc di
    cmp [di], byte ' '
    jne .cmpLbl2ne
    add di, 3
    cmp [di], byte 0
    jne .cmpLbl2prep
    ;end of struct
    ;error here (lbl doesn't exist in struct)

    .endCmpLbl2:
    inc di
    mov bx, word [di] ;store proc mem ptr in ax

    pop dx
    pop di
    ;pop cx
    ;pop si

    jmp bx; address in DEFINE_TYPES struct

    .normalLbl:
    .endparseLbls:
ret

;al = label #
.findLbl:
    push si
    push cx ;use as label length counter
.findLblSpace:
    cmp [si], byte ' '
    je .getLbl2Index
    cmp [si], byte 0
    je .LblNotFound
    inc si
    inc cx
    jmp .findLblSpace

    .getLbl2Index:
    inc si
    cmp [si], al
    je .gotoLbl2Start
    inc si
    xor cx, cx ;reset label length counter
    jmp .findLblSpace

    .LblNotFound:
    pop cx
    pop si
    ;error lbl not found
    xor ax, ax
    ret

    .gotoLbl2Start:
    inc cx
    sub si, cx ;si = start of 2nd label
    mov ax, si
    pop cx
    pop si
ret

.defineByte:
    pop si
    mov di, SYMBOL_TABLE
    mov dx, si ;save si
    call .findLblInSymTable
    mov si, dx
    cmp ax, word 0
    jz .dbAddLblToSymTable
ret
    .dbAddLblToSymTable:
    mov di, SYMBOL_TABLE
    call .addLblToSymTable

    or word [INST_FLAG_2], 100b
ret

.defineProc:
pop si
ret

;si - start of testing lbl
;di - start of symbol table struct
.findLblInSymTable:
    mov al, [si]
    cmp [di], byte ' '
    je .checkEquSpaces
    cmp [di], al
    jne .tryNextLbl
    inc si
    inc di
    jmp .findLblInSymTable
    .tryNextLbl:
    cmp [di], byte ' '
    je .jmpOverAddress
    cmp [di], byte 0
    je .NoLblInSymTable
    inc di
    jmp .tryNextLbl
    .jmpOverAddress:
    add di, 3
    mov si, dx
    jmp .findLblInSymTable
    .LblAlreadyInSymTable:
    xor ax, ax
    inc ax
    ret
    .NoLblInSymTable:
    xor ax, ax
    ret

    .checkEquSpaces:
    cmp [si], byte ' '
    je .LblAlreadyInSymTable
    jmp .tryNextLbl

.addLblToSymTable:
    cmp [di], byte ' '
    je .jmpOverSymAddr
    cmp [di], byte 0
    je .writeLblToSymTable
    inc di
    jmp .addLblToSymTable
    .jmpOverSymAddr:
    add di, 3
    jmp .addLblToSymTable
    .writeLblToSymTable:
    cmp [si], byte ' '
    je .endWriteLblToSymTable
    movsb
    jmp .writeLblToSymTable
    .endWriteLblToSymTable:
    movsb
    mov ax, word [END_BIN]
    mov word [di], ax
    push es
    mov ax, 0x6000 ;output binary segment
    mov es, ax
    mov al, [DEFINE_BYTE]
    call assembleInstruction.writeByte
    pop es
ret

assembleInstruction:
mov ax, word [INST_FLAG]
shl ax, 4
shr ax, 13
and ax, 111b
jnz .assembleLabelOp

mov ax, word [INST_FLAG]
shr ax, 15
mov bx, word [INST_FLAG_2]
shl bx, 1
or ax, bx
cmp ax, 1b
jg .Op2Sreg
je .Op1Sreg
bt word [INST_FLAG], 0
jc .assemble0OpInst

mov ax, word [INST_FLAG]
shl ax, 7
shr ax, 14
and ax, 11b
jnz .assembleImmOp

call .isolateOpType
cmp ax, 0
jz .RegReg
ret

.Op2Sreg:
mov byte [OPCODE], 10001100b 
bt word [INST_FLAG], 5
jc .Op2SregMem
mov dx, 11000000b
call .constructModRMByte
call .writeOpMod
ret
.Op2SregMem:
mov byte [RM], 110b
xor dx, dx
call .constructModRMByte
call .writeOpMod
mov bx, IMM_OP1
call .writeWord
ret

.Op1Sreg:
push ax
mov al, byte [RM]
mov ah, byte [REG]
mov byte [REG], al
mov byte [RM], ah
pop ax
mov byte [OPCODE], 10001110b
bt word [INST_FLAG], 6
jc .Op1SregMem
mov dx, 11000000b
call .constructModRMByte
call .writeOpMod
ret
.Op1SregMem:
mov byte [RM], 110b
xor dx, dx
call .constructModRMByte
call .writeOpMod
mov bx, IMM_OP2
call .writeWord
ret

.isolateOpType:
mov ax, word [INST_FLAG]
shl ax, 9
shr ax, 14
ret

.assembleImmOp:
call .isolateOpType
cmp ax, 0
jnz .MemImmOp

call dasm.GetImmOpcodeExt
dec byte [REG]
call dasm.GetImmOpcode

mov dx, 11000000b
call .constructModRMByte

mov bx, IMM_OP2
.useImmSize:
bt word [INST_FLAG], 4
jc .ImmOpWord

call .writeOpMod
mov al, byte [bx]
call .writeByte
ret

.ImmOpWord:
or word [OPCODE], 1b
call .writeOpMod
.writeWord:
mov al, byte [bx]
call .writeByte
mov al, byte [bx+1]
call .writeByte
ret

.MemImmOp:
mov ax, word [INST_FLAG]
shl ax, 7
shr ax, 14
cmp ax, 11b
jne .NotDualImmOp
call dasm.GetImmOpcodeExt
dec byte [REG]
call dasm.GetImmOpcode

mov byte [RM], 110b
mov dx, 11000000b
call .constructModRMByte

.NotDualImmOp:
bt word [INST_FLAG], 5
jc .Op1MemImm
;op2 mem imm
or word [OPCODE], 10b
mov byte [RM], 110b
xor dx, dx
call .constructModRMByte

bt word [INST_FLAG], 4
jnc .Op2MemImmByte
or byte [OPCODE], 1b

.Op2MemImmByte:
mov bx, IMM_OP2
call .writeOpMod
call .writeWord
ret


.Op1MemImm:
mov byte [RM], 110b
xor dx, dx
call .constructModRMByte

bt word [INST_FLAG], 3
jnc .Op1MemImmByte
or byte [OPCODE], 1b

mov bx, IMM_OP1
call .writeOpMod
call .writeWord
bt word [INST_FLAG], 8
jnc .endit2
mov bx, IMM_OP2
call .writeWord
.endit2:
ret

.Op1MemImmByte:
mov bx, IMM_OP1
call .writeOpMod
call .writeWord
bt word [INST_FLAG], 8
jnc .endit
mov bx, IMM_OP2
mov al, byte [bx]
call .writeByte
.endit:
ret

.assembleLabelOp:
ret

;mov dx - mod 
.constructModRMByte:
mov al, byte [REG]
xor ah, ah
mov word [MODRM], ax
mov ax, word [MODRM]
shl ax, 3
mov word [MODRM], ax
mov al, byte [RM]
xor ah, ah
or ax, dx
or word [MODRM], ax
ret

.RegReg:
mov dx, 11000000b
call .constructModRMByte
bt word [INST_FLAG], 3
jnc .endRegReg
or word [OPCODE], 1b
.endRegReg:
call .writeOpMod
ret

.assemble0OpInst:
mov al, byte '*'
call charInt
mov al, [OPCODE]
call .writeByte
pusha
mov ax, word [END_BIN]
call hprep
call hprint
popa
ret

.writeByte:
mov di, word [END_BIN]
mov [di], al
inc word [END_BIN]
ret

.writeOpMod:
mov al, [OPCODE]
call .writeByte
mov al, [MODRM]
call .writeByte
ret

OP1LBL_MASK dw 1010000000b
OP2LBL_MASK dw 10100000000b
END_BIN dw 0
ENTRY_OFFSET dw 0
TOKEN_FLAG dw 0
INST_ERR_FLAG dw 0
INST_FLAG dw 0b
INST_FLAG_2 dw 0b
LINE_NUMBER dw 0
OPCODE db 0
OPERANDS db 0
REG db 0
RM db 0
MODRM db 0
IMMEDIATE dw 0
IMM_OP1 dw 0
IMM_OP2 dw 0
DUMP db 0
DEFINE_BYTE db 0
HEX_PREFIX db '0x',0
HEX_PREFIX_LEN equ $-HEX_PREFIX-1
NUM_DATA equ 3
MNEM_0OP:
db 'nop ',  10010000b,1,1
db 'pusha ',01100000b,1,1
db 'popa ', 01100001b,1,1
db 'cmpsb ',10100110b,1,1
db 'cmpsw ',10100111b,1,1
db 'movsb ',10100100b,1,1
db 'movsw ',10100101b,1,1
db 'scasb ',10101110b,1,1
db 'scasw ',10101111b,1,1
db 'ret ',  11000011b,1,1
db 'retf ', 11001011b,1,1
db 0
MNEM_1OP:
db 'inc ',01000000b,1,1 ;byte [] 11111110 word [] 11111111 w/ modrm
db 'dec ',01001000b,1,1
db 'call ',11111111b,11101000b,10b
db 'jmp ',11101001b,1,1
db 'push ',01010000b,1,1
db 'pop ',1,1,1
db 'int ',1,1,1
db 'not ',1,1,1
db 'neg ',1,1,1
db 'jo ',1,1,1
db 'jno ',1,1,1
db 'jb ',1,1,1
db 'jnae ',1,1,1
db 'jc ',1,1,1
db 'jnb ',1,1,1
db 'jae ',1,1,1
db 'jnc ',1,1,1
db 'jz ',1,1,1
db 'je ',1,1,1
db 'jnz ',1,1,1
db 'jne ',1,1,1
db 'jbe ',1,1,1
db 'jna ',1,1,1
db 'jnbe ',1,1,1
db 'ja ',1,1,1
db 'js ',1,1,1
db 'jns ',1,1,1
db 'jp ',1,1,1
db 'jpe ',1,1,1
db 'jnp ',1,1,1
db 'jpo ',1,1,1
db 'jl ',1,1,1
db 'jnge ',1,1,1
db 'jnl ',1,1,1
db 'jge ',1,1,1
db 'jle ',1,1,1
db 'jng ',1,1,1
db 'jnle ',1,1,1
db 'jg ',1,1,1
db 'daa ',1,1,1
db 0
MNEM_2OP:
;opcode, immediate opcode, immediate opcode extension (+1)
db 'mov ',10001000b,11000110b,001b
db 'toast ',10001000b,11000110b,001b ;bread joke
db 'xor ',00110000b,10000000b,111b
db 'cmp ',00111000b,10000000b,1000b
db 'add ',00000000b,10000000b,001b
db 'or ',00001000b,10000000b,010b
db 'adc ',00010000b,10000000b,011b
db 'sbb ',00011000b,10000000b,100b
db 'and ',00100000b,10000000b,101b
db 'sub ',00101000b,10000000b,110b
db 'das ',1,1,1
db 'aaa ',1,1,1
db 'aas ',1,1,1
db 'ins ',1,1,1
db 'insb ',1,1,1
db 'insw ',1,1,1
db 'outs ',1,1,1
db 'outsb ',1,1,1
db 'ouisw ',1,1,1
db 'test ',10000100b,10000100b,1
db 'xchg ',1,1,1
db 'lea ',1,1,1
db 'rol ',1,11000000b,001b
db 'ror ',1,11000000b,010b
db 'rcl ',1,11000000b,011b
db 'rcr ',1,11000000b,100b
db 'shl ',1,11000000b,101b
db 'sal ',1,11000000b,111b
db 'shr ',1,11000000b,110b
db 'sar ',1,11000000b,1000b
db 0
REGISTERS:
;all +1 because yeah null terms
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
db 'cs ', 00000010b
db 'ds ', 00000100b
db 'es ', 00000001b
db 'fs ', 00000101b
db 'gs ', 00000110b
db 'ss ', 00000011b
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
db 'cs ', 00000010b
db 'ds ', 00000100b
db 'es ', 00000001b
db 'fs ', 00000101b
db 'gs ', 00000110b
db 'ss ', 00000011b
db 0
SIZE_DEF:
db 'by ', 1
db 'wo ', 2
db 'byte ', 1
db 'word ', 2
db 0
DEFINE_TYPES:
db 'db '
dw dasm.defineByte ;proc address eventually
db ': '
dw dasm.defineProc
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
INST_FLAG_PROC:

dw 1111111111111111b
LBL_DEF:
    times 100 db 0
LBL_OP1:
    times 32 db 0
LBL_OP2:
    times 32 db 0
SYMBOL_TABLE:
    times 100 db 0
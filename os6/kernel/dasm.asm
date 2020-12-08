dasm:

;ds:si - start of string
;es:di - token output
.tokenize:
mov al, byte [si]

;al - char
.ischar:
    cmp al, 122
    jl .mayBeChar

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
    ret
.setcharflag:
    or [TOKEN_FLAG], byte 10000000b
ret

;mov dh, byte 11010101b (flag)
;mov dl, 3 (bit #)
.clearBit:
pusha
push dx
    mov al, 7
    sub al, dl
    mov cl, al
    shl dh, cl
    shr dh, 7
    cmp dh, byte 0
    jz .alreadyZero
    mov cl, dl
    shl dh, cl
    pop ax
    xor ah, dh
    jmp .endClearBit
    .alreadyZero:
    pop ax
    .endClearBit:
popa
ret

TOKEN_FLAG db 00000000b
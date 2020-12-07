irq:
    .driver:
        cli
            mov al, 0x36 ;enable pit
            out 0x43, al

            mov al, 0xFF ;freq
            out 0x40, al
            mov al, 0xFF
            out 0x40, al

            ;set kernel ivt
            call irq.MAP_KERNEL

            mov bl, [IRQ_MASKS]
            mov dx, 0
            call .ENABLE_IRQx

            mov bl, [IRQ_MASKS+1]
            mov dx, 0
            call .ENABLE_IRQx

            call .ENABLE_MASTER_PIC
            call .ENABLE_SLAVE_PIC
        sti
    ret

    .ENABLE_MASTER_PIC:
        push ax
        mov al, [IRQ_FLAGS] ;enable pic

        out 0x21, al
        pop ax
    ret

    .ENABLE_SLAVE_PIC:
        push ax
        mov al, [IRQ_SLAVE_FLAGS] ;enable pic
        out 0xa1, al

        pop ax
    ret

    .MAP_KERNEL:
        mov ax, word .irq0
        mov bx, word irq0_ivt
        call irq.MAP_IRQx

        mov ax, word .irq1
        mov bx, word irq1_ivt
        call irq.MAP_IRQx

        mov ax, word .programList
        mov bx, word irq20_ivt
        call irq.MAP_IRQx

        mov ax, word keyboard.ScancodeToASCII
        mov bx, word irq21_ivt
        call irq.MAP_IRQx

        mov ax, word .loadprogramIRQ
        mov bx, word irq22_ivt
        call irq.MAP_IRQx

        mov si, MAP_KERNEL_STR
        call sprint
        call newLine
    ret

    .printEnabledIRQ:
        push ax
        mov si, IRQ_FLAGS_STR
        call sprint

        in al, 0x21
        xor ah, ah
        call hprep
        call hprint
        call newLine
        pop ax
    ret

    .irq0:
        pusha
            ;scheduler
            ;maybe next year

            mov al, 0x20
            out PIC0, al  
        popa
    iret

    ;mov ax, word .irq#
    ;mov bx, word irq # (ivt offset based)
.MAP_IRQx:
    mov [bx], word ax
    mov [bx+2], word ds
ret

.programList:
push ds
mov ax, 0
mov ds, ax
    call pdt.print
pop ds
iret
    ;mov bl, irq mask
    ;mov dx, 0 or 1 (pic)
    .ENABLE_IRQx:
        push ax
        push bx
            mov si, ENABLE_IRQ_STR
            call sprint

            mov al, bl
            xor ah, ah
            call hprep
            call hprint
            call newLine
        pop bx
        pop ax
        cmp dx, 1
        je .isSlave
        jne .isMaster

        .isMaster:
        mov al, [IRQ_FLAGS]
        xor al, bl ;BOOL!

        mov [IRQ_FLAGS], al

    ret
        .isSlave:
        mov al, [IRQ_SLAVE_FLAGS]
        xor al, bl ;BOOL!

        mov [IRQ_SLAVE_FLAGS], al
    ret

    ;mov bl, irq mask
    .DISABLE_IRQx:
        push ax
        push bx
            mov si, DISABLE_IRQ_STR
            call sprint

            mov al, bl
            xor ah, ah
            call hprep
            call hprint
            call newLine
        pop bx
        pop ax

        mov al, [IRQ_FLAGS]

        or al, bl ;BOOL!
        
        mov [IRQ_FLAGS], al
    ret

.irq1:
    push ds
    push ax
    xor ax, ax
    mov ds, ax

    in al, 01100000b

    test al, 10000000b
    jnz .inputEnd
    mov [INPUT_FLAG], byte 1

    cmp al, byte 0x2A ;shift
    jne .isReturn
    mov [SHIFT_FLAG], byte 1
    jmp .contirq1
    .isReturn:
        cmp al, byte 0x1C ;return
        jne .contirq1
        mov [RETURN_FLAG], byte 1
        jmp .contirq1
    .contirq1:
    xor ah, ah
    push ax

    mov ax, PDT_START
    .findCurrentProgram:
    push ax; save start

    add ax, 0x0F
    
    mov bx, ax
    cmp [bx], byte 1
    je .isCurrentProgram
    pop ax
    add ax, PDT_OFFSET
    jmp .findCurrentProgram

    .isCurrentProgram:
    pop ax

    add ax, 0x0B

    mov cl, [INPUT_FLAG]
    push cx
    mov cl, [SHIFT_FLAG]
    mov ch, [RETURN_FLAG]
    push cx

    mov cx, .returnToIRQ1
    push cx
    mov cx, ds
    push cx

    mov bx, ax
    mov bx, word [bx]; program segment
    mov dx, bx
    push bx
    inc ax
    inc ax
    mov bx, ax
    mov bx, word [bx] ;program input handler offset
    push bx
    mov ds, dx
    retf

    .returnToIRQ1:
    xor ax, ax
    mov ds, ax
    jmp .irq1end
    ;scancode should get popped off in program

    .inputEnd:
    mov [INPUT_FLAG], byte 0
    cmp al, byte 0xAA ;shift
    jne .isEndReturn
    mov [SHIFT_FLAG], byte 0
    jmp .contirq1
    .isEndReturn:
        cmp al, byte 0x9C ;return
        jne .contirq1
        mov [RETURN_FLAG], byte 0
        jmp .contirq1

    .irq1end:
    mov al, 01100001b
    out 0x20, al
    pop ax
    pop ds
iret

.loadprogramIRQ:
push ds
push ax
xor ax, ax
mov ds, ax
pop ax
    call pmalloc
    ;error handler here
    mov es, bx
    call getPDTEntryByName
    ;error handler here
    mov cl, byte [bx]
    mov dh, byte [bx+1]
    mov al, byte [bx+0x10]
    xor bx, bx
    call [loadProgram]
    add bx, 0x0020
pop ds
iret


%include '../driver/keyboard.asm'
irq0_ivt equ 0x0020
irq1_ivt equ 0x0024
irq20_ivt equ 0x0080
irq21_ivt equ 0x0084
irq22_ivt equ 0x0088
IRQ_MASKS:
    db 00000001b
    db 00000010b
IRQ_FLAGS:
    db 00000011b
IRQ_SLAVE_FLAGS:
    db 00000000b
IRQ_FLAGS_STR db 'IRQ FLAG WORD STATUS ', 0 
ENABLE_IRQ_STR db 'ENABLE IRQ MASK ', 0
DISABLE_IRQ_STR db 'DISABLE IRQ MASK ', 0
MAP_KERNEL_STR db 'MAPPED KERNEL IVT ', 0
charCount dw 0
PIC0 equ 0x20 ;also 
PIC1 equ 0xa0 ;command ports
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
            mov [ds:irq0_ivt], word .irq0
            mov [ds:irq0_ivt+2], word 0x00

            mov [ds:irq1_ivt], word .irq1
            mov [ds:irq1_ivt+2], word 0x00

            mov al, 00000000b ;enable pic
            out 0xa1, al
            out 0x21, al
        sti
    ret

    .printEnabledIRQ:
        in al, 0x21
        xor ah, ah
        call hprep
        call hprint
    ret

    .irq0:
        pusha
            ;mov ah, 0x0e
            ;mov al, byte 'e'
            ;int 0x10
            
            mov al, 0x20
            out 0x20, al  
        popa
    iret

    .disable_irq0:

    .irq1:
        push ax

        in al, 01100000b

        test al, 10000000b
        jnz .inputEnd
        
        push ax
        call SCANCODE_TO_ASCII
        call charInt
        pop ax
        mov ah, 0

        call hprep
        call hprint
        call newLine

        .inputEnd:
            mov al, 01100001b
            out 0x20, al
        pop ax
    iret

%include '../keymap.asm'
irq0_ivt equ 0x0020
irq1_ivt equ 0x0024

PIC0 equ 0x20
PIC1 equ 0xa0
PIC0_COM equ 0x20
PIC1_COM equ 0xa0
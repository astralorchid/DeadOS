[org 0x7e00]
xor ax, ax
mov ds, ax

pop dx
mov [DRIVE], dl



call getInitVideoMode


mov si, welc 
call sprint
call newLine

mov si, DriveStr
call sprint

mov ax, [DRIVE]
mov dx, ax
xor cx, cx
xor bx, bx
call hprint
call newLine

mov si, kbStr
call sprint
call newLine

call newProgram
call newProgram





cli
    mov al, 0x36
    out 0x43, al    ;tell the PIT which channel we're setting

    mov al, 0xFF
    out 0x40, al    ;send low byte
    mov al, 0xFF
    out 0x40, al    ;send high byte

    mov al, 0x00
    out 0xa1, al
    out 0x21, al

    mov al, 0x36
    out 0x43, al    ;tell the PIT which channel we're setting

    mov al, 0xFF
    out 0x40, al    ;send low byte
    mov al, 0xFF
    out 0x40, al    ;send high byte

    mov [ds:irq1_ivt], word readChar 
    mov [ds:irq1_ivt+2], word 0x00

    mov [ds:irq0_ivt], word IRQ0Handler
    mov [ds:irq0_ivt+2], word 0x00
sti

jmp $

newProgram:
    call pmalloc

    mov es, ax

    mov ah, 0x02 ;read
    mov al, 0x04 ;#sectors
    mov ch, 0x00 ;cyl
    mov cl, 0x0A ;start from sector
    mov dh, 0x00 ;head
    mov dl, [DRIVE] ;drive
    mov bx, 0x0000 ;offset dest

    int 0x13
    
    push ds ;save jmp segment
    push fromProgram
 
    mov ax, es
    mov ds, ax

    push es
    push bx
retf

    fromProgram:
        mov ax, 0
        mov ds, ax

        mov si, msg
        call sprint
        call newLine
    ret
    
pmalloc:
    mov ax, [loopSeg]
    push ax ;save segment
    cmp ax, [maxSeg]
    je .segDone
    
    mov es, ax
    mov bx, [es:0x0000]

    cmp bx, 0x70
        ;program descriptor table
        ;eventually
    je .hasProgram

    pop ax

    mov bx, [minSeg]
    mov [loopSeg], bx
    ret

    .hasProgram:
        pop ax
        add ax, [segmentSize]
        mov [loopSeg], ax
        jmp pmalloc

    .segDone:
    pop ax
ret


readChar:
    push ax

    in al, 01100000b

    test al, 10000000b
    jnz .inputEnd
    
    push ax
    call SCANCODE_TO_ASCII
    call charInt
    pop ax

    mov ah, 0
    mov dx, ax
    xor cx, cx
    xor bx, bx
    call hprint
    call newLine

    .inputEnd:
        mov al, 01100001b
        out 0x20, al
    pop ax
iret

IRQ0Handler:
pusha

mov ah, 0x0e
mov al, byte 'e'
int 0x10
times 20 nop
    mov al, 0x20
    out 0x20, al  
popa
iret

SetVGASettings:
    pusha
    push ds
        mov ax, 0xb800
        mov ds, ax

        ;xor cx, cx ;vga Y
        xor bx, bx ;vga X

        .storeMem:
        mov [ds:bx], cx

        cmp bx, SCREEN_WIDTH

        jge .done

        add bx, VGA_INC
        jmp .storeMem
    .done:
    pop ds
    popa

%include 'print16.asm'
%include 'keymap.asm'

msg db 'RETURNED TO KERNEL', 0
keyPressStr db 'Key Press', 0
pallocMsg db 'Program allocated at ', 0
welc db 'DeadOS x86 build 0', 0
DriveStr db 'Hard disk port ', 0
kbStr db 'Intialized custom IRQ1 handler', 0
segmentSize dw 0x1000
minSeg dw 0x1000
maxSeg dw 0x8000
loopSeg dw 0x1000

freeSeg dw 0

irq0_ivt equ 0x0020
irq1_ivt equ 0x0024

keymap equ 0x9000
keymap_size equ 0x5F*2

SCREEN_WIDTH equ 0x9E*26
SCREEN_LENGTH equ 20
VGA_INC equ 0x02
DRIVE db 0
times 4096-($-$$) db 0
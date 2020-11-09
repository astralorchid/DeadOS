[org 0x7e00]
xor ax, ax
mov ds, ax

call getInitVideoMode
call setInitVideoMode
call clearScreen

call newProgram

jmp $

newProgram:
    call pmalloc

    mov es, ax

    mov ah, 0x02 ;read
    mov al, 0x04 ;#sectors
    mov ch, 0x00 ;cyl
    mov cl, 0x01 ;start from sector
    mov dh, 0x00 ;head
    mov dl, 0x01 ;drive
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

%include 'print16.asm'
msg db 'returned to kernel', 0
pallocMsg db 'Program allocated at ', 0
freespaceMsg db 'Free segment at ', 0

segmentSize dw 0x1000
minSeg dw 0x1000
maxSeg dw 0x8000
loopSeg dw 0x1000

freeSeg dw 0

times 2048-($-$$) db 0
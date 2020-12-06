[org 0x7e00]

xor ax, ax
mov ds, ax

pop ax
mov [loadProgram], ax

pop ax
mov [readProgram], ax

pop ax
mov [KERNEL_SIZE], byte al

pop dx ;transferred from boot
mov [DRIVE], dl

call getInitVideoMode
call setInitVideoMode

call [readProgram]

mov si, DRIVE_STR
call sprint
call hprint.drive
call newLine

mov si, KERNEL_SIZE_STR
call sprint
xor ah, ah
mov al, byte [KERNEL_SIZE]
call hprep
call hprint
call newLine

call irq.driver

call irq.printEnabledIRQ

call pdt.map
call pdt.print
;start terminal using program loading procedures
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

    mov ax, mapProgramInput
    push ax
    push ds

    mov ax, es
    mov ds, ax

    push es
    push bx
    retf

mapProgramInput: ;intial program kernel communication
    xor ax, ax
    mov ds, ax

    pop ax
    mov [inputName], ax 
    pop ax ;input table offset
    mov [inputOff], ax
    pop ax
    mov [inputSeg], ax
    pop ax
    mov [mainOff], ax

    .getProgramName:
        push ds
        push es
        mov ax, [inputName]
        push ax
            mov ax, [inputSeg]
            mov ds, ax
            xor ax, ax
            mov es, ax
        pop ax
        
            mov si, ax
            mov di, programName
            mov cx, 8
            rep movsb
        pop es
        pop ds

    ;set pdt running segment & current program
    push es ;to use si and di properly
    xor ax, ax
    mov es, ax

        mov ax, PDT_START
        .findPDTEntry:
        push ax ;save start
        inc ax
        inc ax

        mov si, ax
        mov di, programName
        mov cx, 8
        rep cmpsb

        cmp cx, 0
        jz .foundEntry
        pop ax
        add ax, PDT_OFFSET
        jmp .findPDTEntry
        .foundEntry:
        pop ax
        mov bx, ax

        mov ax, [inputSeg]
        add bx, 11
        mov [bx], ax ;write running segment into pdt entry
        add bx, 2
        mov ax, [inputOff]
        mov [bx], ax ;write input handler offset into pdt entry
        add bx, 2
        
        ;clear all offset 0x000F of pdt entries here
        call pdt.clearAllCurrent
        mov [bx], byte 1 ;set as current program
        mov ax, word [bx]

    pop es

    mov ax, [inputSeg]
    push ax
    mov ax, [mainOff]
    push ax

    mov ax, [inputSeg]
    mov ds, ax
retf

respone_msg db 'INPUT MAP REQUEST FROM ', 0
inputSeg dw 0
mainOff dw 0
inputOff dw 0
inputName dw 0
programName:
times 9 db 0

%include '../kernel/kernel_data.asm'
%include '../kernel/irq.asm'
%include '../kernel/pdt.asm'
%include '../kernel/pmalloc.asm'

times 5120-($-$$) db 0
[org 0x7c00]
xor ax, ax
mov ds, ax

mov ax, 0x7000 ;dont go past this lol
mov ss, ax

mov bp, 0xFFFF
mov sp, bp

mov [DRIVE], dl
xor dh, dh
push dx ;save boot drive

push ds
push start
ret

start:
    ;too lazy to make macro :)
    mov ah, 0x02 ;read
    mov al, KERNEL_RESERVE_SECTORS ;#sectors
    push ax ;save kernel sectors
    mov ch, 0 ;cyl
    mov cl, 0x02 ;start from sector
    mov dh, 0x00 ;head
    mov dl, [DRIVE] ;drive
    mov bx, KERNEL_START ;offset dest

    int 0x13

    mov ax, readProgram
    push ax
    
    jmp KERNEL_START

readProgram:
    ;bx = sector offset
    ;dh = head
    add bx, KERNEL_RESERVE_SECTORS
    inc bx

    mov ah, 0x02 ;read
        mov al, 0x01  ;#sectors
        mov ch, 0 ;cyl
        mov cl, bl ;start from sector
        mov dh, 0x00 ;head
        mov dl, [DRIVE] ;drive
        mov bx, 0x1000;offset dest
    int 0x13
ret

jmp $

DRIVE db 0
KERNEL_RESERVE_SECTORS equ 10
KERNEL_START equ 0x7e00
READ_OFFSET db 0
times 510-($-$$) db 0
db 0x55
db 0xAA
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
    mov ch, 0 ;cyl
    mov cl, 0x02 ;start from sector
    mov dh, 0x00 ;head
    mov dl, [DRIVE] ;drive
    mov bx, KERNEL_START ;offset dest

    int 0x13


    jmp KERNEL_START


jmp $

DRIVE db 0
KERNEL_RESERVE_SECTORS equ 0x08
KERNEL_START equ 0x7e00
times 510-($-$$) db 0
db 0x55
db 0xAA
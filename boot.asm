[org 0x7c00]
xor ax, ax
mov ds, ax

mov ax, 0x9000
mov ss, ax

mov bp, 0xFFFF
mov sp, bp

push ds
push start
ret

start:
    mov ah, 0x02 ;read
    mov al, 0x08 ;#sectors
    mov ch, 0 ;cyl
    mov cl, 0x02 ;start from sector
    mov dh, 0x00 ;head
    mov dl, 0x00 ;drive
    mov bx, 0x7e00 ;offset dest

    int 0x13

    jmp 0x7e00
jmp $

times 510-($-$$) db 0
db 0x55
db 0xAA
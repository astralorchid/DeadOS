[bits 16]
[org 0x7e00]

DisableNMI:
    in al, 0x70
    or al, 0x80
    out 0x70, al ;disable nmi

OpenA20:
    in al, 0xD0
    or al, 10b
    out 0xD1, al ;open a20

cli
lgdt [GDT_TABLE_ENTRY]
mov eax, cr0
or al, 1
mov cr0, eax

mov ax, 0x08
mov ds, ax
jmp start32

dq 0
dd 0
dw 0
GDT_TABLE_ENTRY:
    dw 0 ;base 0:15
    dw 0xFFFF ;limit 0:15
    db 0x01 ;base 24:31
    db 01001111b
    db 10001010b
    db 0

[bits 32]

start32:
mov ax, 0x0
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

mov ebx, dword 0xb800
mov al, byte 'E'
mov byte [ebx], al
jmp $
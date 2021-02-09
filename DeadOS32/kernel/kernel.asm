[bits 16]
[org 0x7e00]

DisableNMI:
    in al, 0x70
    or al, 0x80
    out 0x70, al ;disable nmi

OpenA20:
    in al, 0xD0
    or al, 2
    out 0xD1, al ;open a20
    in al, 0x92
    or al, 2
    out 0x92, al ;open a20

LoadInitalGDT:
    cli
    lgdt [GDT_DESCRIPTOR]
    mov eax, cr0
    or al, 1
    mov cr0, eax

    jmp CODESEG:start32

GDT_NULL_DESC:
    dd 0
    dd 0
GDT_CODE_ENTRY:
    dw 0xFFFF ;LIMIT 0:15
    dw 0x0000 ;BASE 0:15
    db 0x00 ;BASE 16:23
    db 10011010b ;ACCESS BYTE
    db 01001111b ;LOW BITS LIMIT 16:19, HIGH BITS FLAGS
    db 00 ;BASE 24:31
GDT_DATA_ENTRY:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 01001111b
    db 00
GDT_END:

GDT_DESCRIPTOR:
    dw GDT_END - GDT_NULL_DESC - 1
    dd GDT_NULL_DESC

CODESEG equ GDT_CODE_ENTRY - GDT_NULL_DESC
DATASEG equ GDT_DATA_ENTRY - GDT_NULL_DESC

[bits 32]

start32:
mov ax, DATASEG
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ss, ax

jmp $
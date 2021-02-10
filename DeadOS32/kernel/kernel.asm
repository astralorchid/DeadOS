[bits 16]
[org 0x7e00]

DisableVGACursor:
    mov ah, 0x01
    mov cx, 0x2607
    int 0x10

DisableNMI:
    in al, 0x70
    or al, 0x80
    out 0x70, al

OpenA20:
    in al, 0xD0
    or al, 2
    out 0xD1, al
    in al, 0x92
    or al, 2
    out 0x92, al

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
    db 11001111b ;LOW BITS LIMIT 16:19, HIGH BITS FLAGS
    db 00 ;BASE 24:31
GDT_DATA_ENTRY:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 00
GDT_END:

GDT_DESCRIPTOR:
    dw GDT_END - GDT_NULL_DESC - 1
    dd GDT_NULL_DESC

CODESEG equ GDT_CODE_ENTRY - GDT_NULL_DESC
DATASEG equ GDT_DATA_ENTRY - GDT_NULL_DESC

[bits 32] ;PROTECTED MODE ENTRY POINT
;LEO MORACOLLI
start32:
    mov ax, DATASEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, dword 0x7c00
    mov esp, ebp
EnableNMI:
    in al, 0x70
    and al, 0x7F
    out 0x70, al
    call ClearVGATextMode
    call UpdateCursor
jmp $

ClearVGATextMode:
    mov eax, VGA_TXT_MODE_SIZE_X
    mov ecx, VGA_TXT_MODE_SIZE_Y
    mul ecx
    mov ecx, eax
    mov ax, 0x0F00
    mov edi, VGA_MEMORY
    rep stosw
ret

UpdateCursor:
    mov eax, dword [CURSOR_POS_X]
    mov ebx, dword VGA_MEMORY
    mov ecx, dword [CURSOR_POS_Y]
    mul ecx
    add eax, eax
    add ebx, eax
    times 2 dec ebx
    cmp [ebx], byte 0
    jnz .byteOccupied
    mov [ebx], byte '_'
    mov [ebx+1], byte 00001111b
    jmp .end
.byteOccupied:
    mov [ebx+1], byte 10000000b
.end:
ret

VGA_MEMORY equ 0xB8000
VGA_TXT_MODE_SIZE_X equ 80
VGA_TXT_MODE_SIZE_Y equ 25
CURSOR_POS_X dd 1
CURSOR_POS_Y dd 1
LAST_CURSOR_POS_X dd 0
LAST_CURSOR_POS_Y dd 0
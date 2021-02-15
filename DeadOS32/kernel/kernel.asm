[bits 16]
[org 0x7e00]

call getInitVideoMode
call setInitVideoMode

call DetectMemory
call GetMemoryMap

pusha
mov ax, word [MEM_MAP_SIZE]
call hprep
call hprint16
popa
call newLine16

mov esi, MEM_MAP_START
xor eax, eax
mov ax, word [MEM_MAP_SIZE] 
add eax, esi
call PrintMemoryMap
jmp $
call DisableVGACursor
call DisableNMI
call OpenA20

LoadInitalGDT:
    cli
    lgdt [GDT_DESCRIPTOR]
    mov eax, cr0
    or al, 1
    mov cr0, eax

    mov ax, TSSSEG
    ltr ax

    jmp 0x8:start32 ;end of real mode


DisableVGACursor:
    mov ah, 0x01
    mov cx, 0x2607
    int 0x10
ret
DisableNMI:
    in al, 0x70
    or al, 0x80
    out 0x70, al
ret
OpenA20:
    in al, 0xD0
    or al, 2
    out 0xD1, al
    in al, 0x92
    or al, 2
    out 0x92, al
ret

;ax
;bx
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
GDT_DATA_ENTRY_2:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 00
GDT_USER_CODE_ENTRY:
    dw 0xFFFF ;LIMIT 0:15
    dw 0x0000 ;BASE 0:15
    db 0x00 ;BASE 16:23
    db 11111010b ;ACCESS BYTE
    db 11001111b ;LOW BITS LIMIT 16:19, HIGH BITS FLAGS
    db 00 ;BASE 24:31
GDT_USER_DATA_ENTRY:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 11110010b
    db 11001111b
    db 00
GDT_TSS_ENTRY:
    dw 0x64
    dw GDT_TSS
    db 0x00
    db 10000001b
    db 11000000b
    db 00
GDT_END:

GDT_DESCRIPTOR:
    dw GDT_END - GDT_NULL_DESC - 1
    dd GDT_NULL_DESC

GDT_TSS:
dd 0
dd 0x7c00
dd DATASEG
times 28 dd 0
dd 0x00640000

IDT_START:
IDT_ENTRY_1:
    dw int0 ;isr entry offset 0-15
    dw CODESEG ;selector
    db 0 ;0
    db 10001110b ;attributes
    dw 0 ;isr entry offset 16-31

    times 2040 db 0
IDT_END:

IDT_DESCRIPTOR:
    dw IDT_END - IDT_START - 1
    dd IDT_START

CODESEG equ GDT_CODE_ENTRY - GDT_NULL_DESC
DATASEG equ GDT_DATA_ENTRY - GDT_NULL_DESC
DATASEG2 equ GDT_DATA_ENTRY_2 - GDT_NULL_DESC
TSSSEG equ GDT_TSS_ENTRY - GDT_NULL_DESC

%include '..\kernel\print16.asm'
%include '..\kernel\memorymap.asm'
[bits 32] ;PROTECTED MODE ENTRY POINT
start32:
    
    mov ax, DATASEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, dword 0x7c00
    mov esp, ebp
    
    lidt [IDT_DESCRIPTOR]

mov edi, 0x100000
mov dword [edi], 0x3
mov eax, 4
xor edi, edi
xor ecx, ecx
PageTable:
    cmp ecx, 1024
    je .end
    push eax
    mul ecx
    mov edi, eax
    mov eax, 0x1000
    mul ecx
    or eax, 3
    mov dword [edi], eax
    pop eax
    inc ecx
    jmp PageTable
.end:



mov eax, 0x100000
mov cr3, eax
 
mov eax, cr0
or eax, 0x80000001
mov cr0, eax

EnableNMI:
    in al, 0x70
    and al, 0x7F
    out 0x70, al

    call ClearVGATextMode
pusha
mov esi, hello
call sprint
popa
int 0

jmp $

int0:
    pusha
    mov esi, teststr
    call sprint
    popa
iret

%include '..\kernel\print32.asm'
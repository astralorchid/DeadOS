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

DetectMemory:
    mov eax, 0xE820
    mov di, MEM_MAP_START
    xor ebx, ebx
    mov edx, 0x534D4150
    mov ecx, 24
    int 0x15
    jc MemMapErr
    cmp eax, dword 0x534D4150
    jne MemMapErr
    add word [MEM_MAP_SIZE], 24
ret

GetMemoryMap:
    cmp ebx, 0
    jz .end
    add di, 24
    mov eax, 0xE820
    mov ecx, 24
    int 0x15
    jc MemMapErr
    cmp eax, dword 0x534D4150
    jne MemMapErr
    add word [MEM_MAP_SIZE], 24
    jmp GetMemoryMap
.end:
ret

PrintMemoryMap:
    cmp esi, eax
    jge .end
    push eax
    mov eax, dword [esi]
    mov dword [MEM_MAP_ENTRY_BASE], eax
    call Print64BitMemMapEntry
    add esi, 8
    mov eax, dword [esi]
    mov dword [MEM_MAP_ENTRY_SIZE], eax
    call Print64BitMemMapEntry
    add esi, 8
    mov eax, dword [esi]
    mov dword [MEM_MAP_ENTRY_TYPE], eax
    call MemMapHprint
    add esi, 8
    call newLine16
    pop eax
    jmp PrintMemoryMap
.end:
ret


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

MEM_MAP_SIZE dw 0
MEM_MAP_START equ 0x0500
MEM_MAP_ENTRY_BASE dd 0
MEM_MAP_ENTRY_SIZE dd 0
MEM_MAP_ENTRY_TYPE dd 0

%include '..\kernel\print16.asm'

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

AllocatePageDirectory:
    xor esi, esi
    xor edi, edi
    xor eax, eax
    mov ecx, 1024
    mov edx, 000000010b
    inc eax
.allocatePageDir:
    cmp eax, ecx
    jg .end
    push eax
    shl eax, 14
    or eax, edx
    mov dword [esi], eax
    push es
        push eax
        mov ax, DATASEG2
        mov es, ax
        pop eax
    mov dword [edi], eax
    pop es
    pop eax
    inc eax
    add esi, 4
    add edi, 4
    jmp .allocatePageDir
.end:

;xor eax, eax
;mov cr3, eax
; 
;mov eax, cr0
;or eax, 0x80000001
;mov cr0, eax
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
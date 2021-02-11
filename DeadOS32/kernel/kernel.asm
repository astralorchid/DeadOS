[bits 16]
[org 0x7e00]

call getInitVideoMode
call setInitVideoMode

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

    jmp 0x8:start32 ;end of real mode

%include '..\kernel\print16.asm'
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
TSSSEG equ GDT_TSS_ENTRY - GDT_NULL_DESC

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

    mov ax, TSSSEG
    ltr ax

    lidt [IDT_DESCRIPTOR]

EnableNMI:
    in al, 0x70
    and al, 0x7F
    out 0x70, al

    call ClearVGATextMode
pusha
mov esi, hello
call sprint
popa

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

GetCursorPos:
    mov eax, dword [CURSOR_POS_X]
    mov ebx, dword VGA_MEMORY
    mov ecx, dword [CURSOR_POS_Y]
    .compare:
    cmp ecx, 0
    jne .addY
    jmp .end
    .addY:
    add eax, 80
    dec ecx
    jmp .compare
    .end:
    add eax, eax
    add ebx, eax
ret

UpdateCursor:
    pusha
    call GetCursorPos
    mov cx, word 00001111b
    mov dx, word 10000000b
    cmp [ebx], byte 0
    cmovnz ax, dx
    cmovz ax, cx
    jnz .byteOccupied
    mov [ebx], byte '_'
.byteOccupied:
    mov [ebx+1], al
    popa
ret

cprint:
    pusha
    push eax
    call GetCursorPos
    pop eax
    mov [ebx], al
    mov edx, 1
    xor eax, eax
    mov ecx, dword [CURSOR_POS_X]
    xor ebx, ebx
    cmp ecx, VGA_TXT_MODE_SIZE_X
    cmovge eax, edx
    cmove ecx, ebx
    add dword [CURSOR_POS_Y], eax
    inc ecx
    mov dword [CURSOR_POS_X], ecx
    call UpdateCursor
    popa
ret

;newline procedure?

;si - char*
sprint:
    xor eax, eax
    xor ebx, ebx
    inc eax
    inc ebx
    cmp [esi], byte 0
    jz .end
    cmovnz eax, dword [esi]
    cmovnz ecx, ebx
    push esi
    call cprint
    add esi, ecx
    pop edx
    cmp esi, edx
    je .end
    jmp sprint
.end:
ret

hprint:
ret

int0:
pusha
mov esi, teststr
call sprint
popa
iret

VGA_MEMORY equ 0xB8000
VGA_BUFFER equ 0x100000
VGA_BUFFER_SIZE equ 8000
VGA_TXT_MODE_SIZE_X equ 80
VGA_TXT_MODE_SIZE_Y equ 25
CURSOR_POS_X dd 0
CURSOR_POS_Y dd 0
LAST_CURSOR_POS_X dd 0
LAST_CURSOR_POS_Y dd 0
hello db 'Hello world!', 0
teststr db 'Interrupt 0', 0
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

PrintMemoryMap: ;first procedure saves memory
    xor edx, edx
    xor ebx, ebx
    inc ebx

    cmp esi, eax
    jge .next
    push eax
        mov eax, dword [esi]
        mov dword [MEM_MAP_ENTRY_BASE], eax
        call Filter64BitRAM
        mov eax, dword [esi]
        mov dword [MEM_MAP_ENTRY_SIZE], eax
        call Filter64BitRAM
        mov eax, dword [esi]
        mov dword [MEM_MAP_ENTRY_TYPE], eax
        add esi, 8
    pop eax
    cmp edx, 0
    jnz PrintMemoryMap
    cmp dword [MEM_MAP_ENTRY_TYPE], 1
    je AllocateMemoryMap
    jmp PrintMemoryMap
.next: ;prints the memory map
    mov esi, MEM_MAP_START
    xor ecx, ecx
.loop:
    cmp esi, dword [MEM_MAP_PTR]
    jge .end
    lea eax, [esi + ecx]
    mov esi, eax
    call MemMapHprint
    call newLine16
    lea eax, [esi + ecx + 4]
    mov esi, eax
    call MemMapHprint
    call newLine16
    lea eax, [esi + ecx + 4]
    mov esi, eax
    mov ax, word [esi]
    call h16
    call newLine16
    inc esi
    jmp .loop
.end:
ret

Filter64BitRAM:
        add esi, 4
        cmp dword [esi], 0
        cmovnz edx, ebx
        add esi, 4
ret

AllocateMemoryMap:
    push esi
    push eax
    mov eax, dword [MEM_MAP_ENTRY_BASE]
    mov esi, dword [MEM_MAP_PTR]
    mov dword [esi], eax
    add esi, 4
    mov eax, dword [MEM_MAP_ENTRY_SIZE]
    mov dword [esi], eax
    add esi, 4
    mov byte [esi], 0
    inc esi
    mov dword [MEM_MAP_PTR], esi
.OL:
    ;sub esi, 4
    pop eax
    pop esi
jmp PrintMemoryMap

Print64BitMemMapEntry:
    add esi, 4
    call MemMapHprint

    sub esi, 4
    call MemMapHprint
    call newLine16
ret

MemMapHprint:
    mov eax, dword [esi]
    ror eax, 16
    call h16
    ror eax, 16
    call h16
ret

MemMapErr:
    mov si, MEM_MAP_ERR
    call sprint16
    jmp $

;see docs for setup
FindMemMapEntry:
    xor ebx, ebx
    xor ecx, ecx
    xor edi, edi
    bt dx, 0
    cmovc bx, [CMOV_SIZE_OFFSET]
    mov si, MEM_MAP_START
.findLoop:
    push si
    add esi, ebx
    bt dx, 1
    cmovc di, [JE_OPCODE]
    cmp di, 0
    jnz .startTest
    bt dx, 2
    jc .equalTo
    bt dx, 3
    cmovc di, [JL_OPCODE]
    cmovnc di, [JG_OPCODE]
    cmp di, 0
    jnz .startTest
.equalTo:
    bt dx, 3
    cmovc di, [JLE_OPCODE]
    cmovnc di, [JGE_OPCODE]
    cmp di, 0
    jnz .startTest
.startTest:
    ;mov word [.jmpOpcode], di
    [bits 32]
    cmp eax, dword [esi]
    [bits 16]
    db 0x0f, 0x84
    dw .testPass
    .testFail:
    pop si
    add esi, 9
    cmp esi, [MEM_MAP_PTR]
    jge .endFail
    jmp .findLoop
    .testPass:
    sub esi, ebx
    add esi, 8
    cmp [si], byte 0
    jnz .testFail
    pop si
    xor dx, dx

    mov al, byte 'e'
    call charInt
ret
.endFail:
    xor dx, dx
    inc dx
        mov al, byte 'f'
    call charInt
ret
CMOV_SIZE_OFFSET dw 4
JE_OPCODE dw 0x0F84
JG_OPCODE dw 0x0F8F
JL_OPCODE dw 0x0F8C
JGE_OPCODE dw 0x0F8D
JLE_OPCODE dw 0x0F8E
MEM_MAP_SIZE dw 0
MEM_MAP_START equ 0x2000
MEM_MAP_ENTRY_BASE dd 0
MEM_MAP_ENTRY_SIZE dd 0
MEM_MAP_ENTRY_TYPE dd 0
MEM_MAP_ERR db 'Error building memory map', 0
MEM_MAP_PTR dd MEM_MAP_START ;points to the end of the memory map
KERNEL_MEM_PTR dd 0

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

    cmp dword [MEM_MAP_ENTRY_TYPE], 1
    je AllocateFreeMemory
.continue:
    jmp PrintMemoryMap
.end:
ret

AllocateFreeMemory:
    add esi, 4
    cmp dword [esi], 0
    jnz .OL ;don't allocate memory past the 32bit limit

.OL:
jmp PrintMemoryMap.continue

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


MEM_MAP_SIZE dw 0
MEM_MAP_START equ 0x0500
MEM_MAP_ENTRY_BASE dd 0
MEM_MAP_ENTRY_SIZE dd 0
MEM_MAP_ENTRY_TYPE dd 0
MEM_MAP_ERR db 'Error building memory map', 0
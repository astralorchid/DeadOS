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
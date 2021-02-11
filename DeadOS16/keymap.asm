;scancode in al
keyboard:
.ScancodeToASCII:
    push ds
    push ax
    xor ax, ax
    mov ds, ax
    pop ax

    cmp bl, 0
    jz .unshifted
    push bx
    mov bh, 0
    mov bl, al
    mov al, [SHIFT_KEYMAP+bx]
    pop bx
    jmp .endScancodeToASCII

    .unshifted:
    push bx
    mov bh, 0
    mov bl, al
    mov al, [KEYMAP+bx]
    pop bx

    .endScancodeToASCII:
    pop ds
iret

SHIFT_FLAG db 0
RETURN_FLAG db 0
INPUT_FLAG db 0

KEYMAP:
db 0x00
db 0x1B
db '1'
db '2'
db '3'
db '4'
db '5'
db '6'
db '7'
db '8'
db '9'
db '0'
db '-'
db '='
db 0x00
db 0x00
db 'q'
db 'w'
db 'e'
db 'r'
db 't'
db 'y'
db 'u'
db 'i'
db 'o'
db 'p'
db '['
db ']'
db 0x00
db 0x00
db 'a'
db 's'
db 'd'
db 'f'
db 'g'
db 'h'
db 'j'
db 'k'
db 'l'
db 0x3B ;
db 0x27 ; '
db 0x00
db 0x00
db '\'
db 'z'
db 'x'
db 'c'
db 'v'
db 'b'
db 'n'
db 'm'
db ','
db '.'
db '/'
times 126-($-KEYMAP) db 0
SHIFT_KEYMAP:
db 0x00
db 0x1B
db '!'
db '@'
db '#'
db '$'
db '%'
db '^'
db '&'
db '*'
db '('
db ')'
db '_'
db '+'
db 0x00
db 0x00
db 'Q'
db 'W'
db 'E'
db 'R'
db 'T'
db 'Y'
db 'U'
db 'I'
db 'O'
db 'P'
db '{'
db '}'
db 0x00
db 0x00
db 'A'
db 'S'
db 'D'
db 'F'
db 'G'
db 'H'
db 'J'
db 'K'
db 'L'
db ':'
db 0x22 ; "
db 0x00
db 0x00
db '|'
db 'Z'
db 'X'
db 'C'
db 'V'
db 'B'
db 'N'
db 'M'
db '<'
db '>'
db '?'
times 126-($-SHIFT_KEYMAP) db 0
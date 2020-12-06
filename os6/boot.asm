[org 0x7c00]

JMP start          ;BS_jmpBoot
NOP                                                                                                  
BS_OEMName      DB "HARIBOTE"
BPB_BytsPerSec  DW 0x0200
BPB_SecPerClus  DB 0x01
BPB_RsvdSecCnt  DW 0x0001
BPB_NumFATs     DB 0x02
BPB_RootEntCnt  DW 0x0000
BPB_TotSec16    DW 0x0000
BPB_Media       DB 0xf8
BPB_FATSz16     DW 0x0000
BPB_SecPerTrk   DW 0xffff
BPB_NumHeads    DW 0x0001
BPB_HiDDSec     DD 0x00000000
BPB_TotSec32    DD 0x00ee5000
BPB_FATSz32     DD 0x000000ed
BPB_ExtFlags    DW 0x0000
BPB_FSVer       DW 0x0000
BPB_RootClus    DD 0x00000000
BPB_FSInfo      DW 0x0001
BPB_BkBootSec   DW 0x0000
        times   12      DB 0    ;BPB_Reserverd                                                                                               
BS_DrvNum       DB 0x80
BS_Reserved1    DB 0x00
BS_BootSig      DB 0x29
BS_VolID        DD 0xa0a615c
BS_VolLab       DB "ISHIHA BOOT"
BS_FileSysType  DB "FAT32   "

start:
xor ax, ax
mov ds, ax

mov ax, 0x7000 ;dont go past this lol
mov ss, ax

mov bp, 0xFFFF
mov sp, bp

mov [DRIVE], dl
xor dh, dh
push dx ;save boot drive

    ;too lazy to make macro :)
    mov ah, 0x02 ;read
    mov al, KERNEL_RESERVE_SECTORS ;#sectors
    push ax ;save kernel sectors
    mov ch, 0 ;cyl
    mov cl, 0x02 ;start from sector
    mov dh, 0x00 ;head
    mov dl, [DRIVE] ;drive
    mov bx, KERNEL_START ;offset dest

    int 0x13

    mov ax, readProgram
    push ax
    mov ax, loadProgram
    push ax
    
    jmp KERNEL_START

readProgram:
    ;bx = sector offset
    ;dh = head
    cmp ah, 0
    je .addKernelSize 
    jmp .readSector

    .addKernelSize:
    add bl, KERNEL_RESERVE_SECTORS
    inc bl

    .readSector:
    mov ah, 0x02 ;read
        mov al, 0x01  ;#sectors
        mov ch, 0 ;cyl
        mov cl, bl ;start from sector
        ;mov dh, 0x00 ;head
        mov dl, [DRIVE] ;drive
        mov bx, 0x1000;offset dest
    int 0x13
ret

loadProgram:
    mov ah, 0x02 ;read
    ;mov al, 0x02 ;#sectors (Un-hardcode)
    mov ch, 0 ;cyl
    ;mov cl start from sector
    ;mov dh head
    mov dl, [DRIVE] ;drive
    int 0x13
ret

jmp $

DRIVE db 0
KERNEL_RESERVE_SECTORS equ 10
KERNEL_START equ 0x7e00
READ_OFFSET db 0
times 510-($-$$) db 0
db 0x55
db 0xAA
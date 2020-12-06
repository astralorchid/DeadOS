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

    mov ah, 0x42 ;read
    mov dl, [DRIVE] ;drive
    mov si, DAP
    int 0x13

    mov ax, KERNEL_RESERVE_SECTORS
    push ax
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
    ;inc bl

    .readSector:
    mov ah, 0x42 ;read
    mov dl, [DRIVE] ;drive
    mov [DAP.sectors], word 0x01  ;#sectors
    xor bh, bh
    mov [DAP.word1], word bx ;start from sector
    mov [DAP.offset], word 0x1000;offset dest
    mov [DAP.segment], word 0
    mov si, DAP
    int 0x13

ret

loadProgram:
    mov ah, 0x42 ;read
    mov dl, [DRIVE] ;drive
    push ax
    xor ah, ah
    mov [DAP.sectors], word ax  ;#sectors
    pop ax
    xor ch, ch
    dec cx
    mov [DAP.word1], word cx ;start from sector
    mov [DAP.offset], word bx;offset dest
    mov [DAP.segment], word es
    mov si, DAP
    int 0x13
ret

jmp $

DRIVE db 0
KERNEL_RESERVE_SECTORS equ 10
KERNEL_START equ 0x7e00
READ_OFFSET db 0
DAP:
.size db 0x10
.null db 0
.sectors dw KERNEL_RESERVE_SECTORS
.offset dw KERNEL_START
.segment dw 0x0000
.word1 dw 0x0001
.word2 dw 0x0000
.word3 dw 0x0000
.word4 dw 0x0000
times 510-($-$$) db 0
db 0x55
db 0xAA
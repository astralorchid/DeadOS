[org 0x7c00]
jmp start
nop
BPB:                                                                                                  
.OEMName db "DEADBOOT"
.BytsPerSec dw 0x0200
.SecPerClus db 0x01
.RsvdSecCnt dw 0x0001
.NumFATs db 0x02
.RootEntCnt dw 0x0000
.TotSec16 dw 0x0000
.Media db 0xf8
.FATSz16 dw 0x0000
.SecPerTrk dw 0xffff
.NumHeads dw 0x0001
.HiDDSec dd 0x00000000
.TotSec32 dd 0x00ee5000
.FATSz32 dd 0x000000ed
.ExtFlags dw 0x0000
.FSVer dw 0x0000
.RootClus dd 0x00000000
.FSInfo dw 0x0001
.BkBootSec dw 0x0000
times 12 db 0  
BS:                                                                                           
.DrvNum       dd 0x80
.Reserved1    db 0x00
.BootSig      db 0x29
.VolID        dd 0xa0a615c
.VolLab       db "DEADBOOT"
.FileSysType  db "FAT32   "

start:
xor ax, ax
mov ds, ax
mov ss, ax
mov bp, ax
mov sp, bp

mov [DRIVE], dl
mov [BS.DrvNum], dl
xor dh, dh

    mov ah, 0x42 ;read
    mov dl, [DRIVE] ;drive
    mov si, DAP
    int 0x13
    
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
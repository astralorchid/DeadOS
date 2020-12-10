isPROGRAM db 'program', 0
prgmNAME db 'hello   ', 0
MAX_SECTORS equ 0x04
prgmSec db MAX_SECTORS, 0
times 32-(prgmSec-$$) db 0

times (512*MAX_SECTORS)-($-$$) db 0

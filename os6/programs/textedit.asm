isPROGRAM db 'program', 0
prgmNAME db 'TestPrgm', 0
MAX_SECTORS equ 0x02
prgmSec db MAX_SECTORS, 0
times 31-($-prgmSec) db 0

times (512)-($-$$) db 0
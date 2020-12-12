MNEMONIC:
db 'add', ' '
db 'or', ' '
db 'adc', ' '
db 'sbb', ' '
db 'and', ' '
db 'xor', ' '
db 'cmp', ' '
db 0
db 'rm8,r8', ' ', 0x01 ;-1 eventually
db 'rm16,r16', ' ', 0x02
db 'r8,rm8', ' ', 0x03
db 'r16,rm16', ' ', 0x04
db 'al,im8', ' ', 0x05
db 'ax,im16', ' ', 0x06
db 0xFF
db 'mov', ' '
db 'rm8, r8'


; === MEMORY MAP ===
MEM_GENCODE      = $0900   ; Generated code starts here
MEM_GENCODE_END  = $2FFF   ; Generated code ends here
MEM_VARS         = $3800   ; Variable storage (512 x 16-bit = 1K)
MEM_VARS_END     = $3BFF
MEM_RUNTIME      = $3C00   ; Runtime library (math, compare, I/O)
MEM_RUNTIME_END  = $3FFF   ; End of runtime library space
MEM_COMPILER     = $4000   ; Compiler code starts here
MEM_COMPILER_END = $5FFF
MEM_SOURCE       = $6000   ; Source code buffer
MEM_SOURCE_END   = $9FFF
MEM_SYMTAB       = $A000   ; Symbol table (256 entries x 32 bytes = 8K)
MEM_SYMTAB_END   = $BEFF
MEM_PRODOS_GP    = $BF00   ; ProDOS global page (DO NOT TOUCH)
MEM_IO           = $C000   ; I/O soft switches

; Symbol table entry structure
SYM_ENTRY_SIZE   = 32
SYM_HASH_OFF     = 0       ; Hash byte
SYM_TYPE_OFF     = 1       ; Type (0=var, 1=func)
SYM_ADDR_OFF     = 2       ; Address low
SYM_ADDR_H_OFF   = 3       ; Address high
SYM_NAME_OFF     = 4       ; Name string (28 bytes, null-terminated)

SYM_TYPE_VAR     = $00
SYM_TYPE_FUNC    = $01
SYM_MAX_ENTRIES  = 256

; ProDOS MLI
PRODOS_MLI       = $BF00
MLI_OPEN         = $C8
MLI_READ         = $CA
MLI_CLOSE        = $CC
MLI_WRITE        = $CB
MLI_QUIT         = $65

; Apple II I/O
COUT             = $FDED   ; Character output
RDKEY            = $FD0C   ; Read key
CROUT            = $FD8E   ; Carriage return

; Language Card soft switches (kept for reference, but not used)
LC_BANK1_RW      = $C083   ; Read RAM bank 1, write enable (read twice)

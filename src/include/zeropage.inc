; === ZERO PAGE ALLOCATION MAP ===
; $00-$3F: ProDOS reserved (DO NOT TOUCH)

; === Compiler State ($40-$7F) ===
ZP_CODEGEN_PTR   = $40   ; Code generation pointer (16-bit, low/high)
ZP_CODEGEN_PTR_H = $41
ZP_SRC_PTR       = $42   ; Source parse pointer (16-bit)
ZP_SRC_PTR_H     = $43
ZP_SYM_PTR       = $44   ; Symbol table pointer (16-bit)
ZP_SYM_PTR_H     = $45
ZP_TOKEN         = $46   ; Current token type
ZP_TOKEN_VAL     = $47   ; Token value low (identifier hash or number)
ZP_TOKEN_VAL_H   = $48   ; Token value high
ZP_TMP0          = $49   ; Compiler temporary 0 (16-bit)
ZP_TMP0_H        = $4A
ZP_TMP1          = $4B   ; Compiler temporary 1 (16-bit)
ZP_TMP1_H        = $4C
ZP_LOOP_START    = $4D   ; While loop start address (16-bit)
ZP_LOOP_START_H  = $4E
ZP_LOOP_PATCH    = $4F   ; Loop exit patch address (16-bit)
ZP_LOOP_PATCH_H  = $50
ZP_IF_PATCH      = $51   ; If branch patch address (16-bit)
ZP_IF_PATCH_H    = $52

; === Virtual Registers ($80-$9F) - used by compiled code ===
R0       = $80   ; Primary accumulator (16-bit)
R0_H     = $81
R1       = $82   ; Secondary register
R1_H     = $83
R2       = $84   ; Tertiary register
R2_H     = $85
R3       = $86   ; Quaternary register
R3_H     = $87
PTR0     = $88   ; Pointer register 0
PTR0_H   = $89
PTR1     = $8A   ; Pointer register 1
PTR1_H   = $8B
PTR2     = $8C
PTR2_H   = $8D
PTR3     = $8E
PTR3_H   = $8F
RTMP0    = $90   ; Runtime temporary 0
RTMP0_H  = $91
RTMP1    = $92
RTMP1_H  = $93
RTMP2    = $94
RTMP2_H  = $95
RTMP3    = $96
RTMP3_H  = $97
MULR     = $98   ; Multiply result
MULR_H   = $99
DIVR     = $9A   ; Divide result
DIVR_H   = $9B
IOPTR    = $9C   ; I/O pointer
IOPTR_H  = $9D
EXPR_STACK   = $9E   ; Expression stack pointer
EXPR_STACK_H = $9F

; === Runtime Workspace ($A0-$FF) ===
ZP_MLI_PARAMS = $A0  ; ProDOS MLI parameter block area
; $C0-$FF: Additional runtime scratch

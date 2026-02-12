; === RUNTIME LIBRARY FUNCTION ADDRESSES ===
; Runtime library is built separately and loaded at MEM_RUNTIME ($3C00)
; These addresses must match the actual addresses in runtime.bin
; To update: build runtime.bin and check runtime.lst

MUL16            = $3C00   ; 16-bit multiply
SHL16            = $3C33   ; 16-bit shift left
SHR16            = $3C40   ; 16-bit shift right
CMP_EQ16         = $3C69   ; Compare equal
CMP_NE16         = $3C79   ; Compare not equal
CMP_LT16         = $3C89   ; Compare less than (signed)
CMP_LE16         = $3CAB   ; Compare less than or equal (signed)
CMP_GT16         = $3CBD   ; Compare greater than (signed)
CMP_GE16         = $3CE3   ; Compare greater than or equal (signed)

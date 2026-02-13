; === CODE GENERATOR ===
; Emit 65C02 machine code

!source "src/include/zeropage.inc"
!source "src/include/memory.inc"
!source "src/include/tokens.inc"

; --- codegen_init ---
; Initialize code generation
; Reserve 3 bytes at start for JMP to main
codegen_init:
    lda #<(MEM_GENCODE+3)
    sta ZP_CODEGEN_PTR
    lda #>(MEM_GENCODE+3)
    sta ZP_CODEGEN_PTR_H
    rts

; --- emit_byte ---
; Emit single byte to generated code
; Input: A = byte to emit
emit_byte:
    ldy #0
    sta (ZP_CODEGEN_PTR),y
    inc ZP_CODEGEN_PTR
    bne emit_byte_no_carry
    inc ZP_CODEGEN_PTR_H
emit_byte_no_carry:
    rts

; --- emit_word ---
; Emit 16-bit word (little-endian)
; Input: A = low byte, X = high byte
emit_word:
    jsr emit_byte
    txa
    jsr emit_byte
    rts

; --- emit_load_imm ---
; Emit code to load immediate 16-bit value into R0
; Input: ZP_TOKEN_VAL = 16-bit immediate value
; Emits: LDA #lo / STA R0 / LDA #hi / STA R0+1
emit_load_imm:
    lda #$A9           ; LDA #imm
    jsr emit_byte
    lda ZP_TOKEN_VAL   ; Low byte value
    jsr emit_byte
    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0            ; R0 address
    jsr emit_byte

    lda #$A9           ; LDA #imm
    jsr emit_byte
    lda ZP_TOKEN_VAL_H ; High byte value
    jsr emit_byte
    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0_H          ; R0+1 address
    jsr emit_byte
    rts

; --- emit_load_var ---
; Generate code to load variable into R0
; Input: A = var address low, X = var address high
; Emits: LDA addr / STA R0 / LDA addr+1 / STA R0+1
emit_load_var:
    ; Save address in zero page temporaries
    sta ZP_TMP0        ; Low byte
    stx ZP_TMP0_H      ; High byte

    ; Emit: LDA addr
    lda #$AD           ; LDA abs
    jsr emit_byte
    lda ZP_TMP0        ; Low byte
    ldx ZP_TMP0_H      ; High byte
    jsr emit_word

    ; Emit: STA R0
    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    ; Emit: LDA addr+1
    lda #$AD           ; LDA abs
    jsr emit_byte
    lda ZP_TMP0        ; Low byte
    clc
    adc #1             ; Increment for addr+1
    ldx ZP_TMP0_H      ; High byte
    bcc load_var_no_carry
    inx                ; Increment high if low overflowed
load_var_no_carry:
    jsr emit_word

    ; Emit: STA R0_H
    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte
    rts

; --- emit_store_var ---
; Generate code to store R0 into variable
; Input: A = var address low, X = var address high
; Emits: LDA R0 / STA addr / LDA R0+1 / STA addr+1
emit_store_var:
    ; Save address in zero page temporaries
    sta ZP_TMP0        ; Low byte
    stx ZP_TMP0_H      ; High byte

    ; Emit: LDA R0
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    ; Emit: STA addr
    lda #$8D           ; STA abs
    jsr emit_byte
    lda ZP_TMP0        ; Low byte
    ldx ZP_TMP0_H      ; High byte
    jsr emit_word

    ; Emit: LDA R0_H
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    ; Emit: STA addr+1
    lda #$8D           ; STA abs
    jsr emit_byte
    lda ZP_TMP0        ; Low byte
    clc
    adc #1             ; Increment for addr+1
    ldx ZP_TMP0_H      ; High byte
    bcc store_var_no_carry
    inx                ; Increment high if low overflowed
store_var_no_carry:
    jsr emit_word
    rts

; --- emit_push_r0_to_r1 ---
; Emit code to copy R0 to R1
; Emits: LDA R0 / STA R1 / LDA R0+1 / STA R1+1
emit_push_r0_to_r1:
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R1
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R1_H
    jsr emit_byte
    rts

; --- emit_push_r1_stack ---
; Emit code to push R1 onto hardware stack
; Emits: LDA R1_H / PHA / LDA R1 / PHA
emit_push_r1_stack:
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R1_H
    jsr emit_byte

    lda #$48           ; PHA
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R1
    jsr emit_byte

    lda #$48           ; PHA
    jsr emit_byte
    rts

; --- emit_pop_r1_stack ---
; Emit code to pop from hardware stack into R1
; Emits: PLA / STA R1 / PLA / STA R1_H
emit_pop_r1_stack:
    lda #$68           ; PLA
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R1
    jsr emit_byte

    lda #$68           ; PLA
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R1_H
    jsr emit_byte
    rts

; --- emit_add16 ---
; Emit inline 16-bit add (R0 = R1 + R0)
; Emits: CLC / LDA R0 / ADC R1 / STA R0 / LDA R0+1 / ADC R1+1 / STA R0+1
emit_add16:
    lda #$18           ; CLC
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$65           ; ADC zp
    jsr emit_byte
    lda #R1
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    lda #$65           ; ADC zp
    jsr emit_byte
    lda #R1_H
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte
    rts

; --- emit_sub16 ---
; Emit inline 16-bit subtract (R0 = R1 - R0)
; Emits: SEC / LDA R1 / SBC R0 / STA R0 / LDA R1+1 / SBC R0+1 / STA R0+1
emit_sub16:
    lda #$38           ; SEC
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R1
    jsr emit_byte

    lda #$E5           ; SBC zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R1_H
    jsr emit_byte

    lda #$E5           ; SBC zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte
    rts

; --- emit_and16 ---
; Emit inline 16-bit AND (R0 = R0 AND R1)
emit_and16:
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$25           ; AND zp
    jsr emit_byte
    lda #R1
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    lda #$25           ; AND zp
    jsr emit_byte
    lda #R1_H
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte
    rts

; --- emit_or16 ---
; Emit inline 16-bit OR (R0 = R0 OR R1)
emit_or16:
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$05           ; ORA zp
    jsr emit_byte
    lda #R1
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    lda #$05           ; ORA zp
    jsr emit_byte
    lda #R1_H
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte
    rts

; --- emit_xor16 ---
; Emit inline 16-bit XOR (R0 = R0 XOR R1)
emit_xor16:
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$45           ; EOR zp
    jsr emit_byte
    lda #R1
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    lda #$45           ; EOR zp
    jsr emit_byte
    lda #R1_H
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte
    rts

; --- emit_jsr ---
; Emit JSR to absolute address
; Input: A = address low, X = address high
emit_jsr:
    pha
    txa
    pha

    lda #$20           ; JSR abs
    jsr emit_byte

    pla
    tax
    pla
    jsr emit_word
    rts

; --- emit_jmp ---
; Emit JMP to absolute address
; Input: A = address low, X = address high
emit_jmp:
    pha
    txa
    pha

    lda #$4C           ; JMP abs
    jsr emit_byte

    pla
    tax
    pla
    jsr emit_word
    rts

; --- emit_rts ---
; Emit RTS instruction
emit_rts:
    lda #$60           ; RTS
    jsr emit_byte
    rts

; --- emit_test_r0_zero ---
; Emit code to test if R0 is zero
; Emits: LDA R0 / ORA R0+1 / BNE +3
; After this, if R0 was zero, next instruction executes
; If R0 was non-zero, skips next 3 bytes
emit_test_r0_zero:
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$05           ; ORA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    lda #$D0           ; BNE rel
    jsr emit_byte
    lda #$03           ; Skip 3 bytes (JMP instruction)
    jsr emit_byte
    rts

; --- emit_jmp_placeholder ---
; Emit JMP with placeholder address
; Returns: Current codegen ptr (pointing to operand) in ZP_TMP0
emit_jmp_placeholder:
    lda #$4C           ; JMP abs
    jsr emit_byte

    ; Save address of operand for patching
    lda ZP_CODEGEN_PTR
    sta ZP_TMP0
    lda ZP_CODEGEN_PTR_H
    sta ZP_TMP0_H

    ; Emit placeholder
    lda #$00
    jsr emit_byte
    lda #$00
    jsr emit_byte
    rts

; --- patch_jmp ---
; Patch a JMP instruction's operand
; Input: ZP_TMP0 = address of JMP operand (2 bytes)
;        ZP_CODEGEN_PTR = target address (current position)
patch_jmp:
    ; Save current codegen pointer
    lda ZP_CODEGEN_PTR
    pha
    lda ZP_CODEGEN_PTR_H
    pha

    ; Write target address to patch location
    ldy #0
    lda ZP_CODEGEN_PTR
    sta (ZP_TMP0),y
    iny
    lda ZP_CODEGEN_PTR_H
    sta (ZP_TMP0),y

    ; Restore codegen pointer
    pla
    sta ZP_CODEGEN_PTR_H
    pla
    sta ZP_CODEGEN_PTR
    rts

; --- emit_comparison ---
; Emit comparison code
; Input: A = comparison token (TOK_EQEQ, TOK_LT, etc_)
; Assumes: R1 = left operand, R0 = right operand
; Output: R0 = 0 or 1 (boolean result)
emit_comparison:
    pha                ; Save comparison type

    ; NOTE: Parser puts left operand in R1, right in R0.
    ; CMP_xx16 routines test R0 vs R1.
    ; So for asymmetric ops we swap: TOK_LT emits CMP_GT16, etc.

    ; Emit JSR to appropriate comparison function
    cmp #TOK_EQEQ
    bne emit_comparison_not_eq
    lda #<CMP_EQ16
    ldx #>CMP_EQ16
    jsr emit_jsr
    jmp emit_comparison_convert_carry

emit_comparison_not_eq:
    pla
    pha
    cmp #TOK_NE
    bne emit_comparison_not_ne
    lda #<CMP_NE16
    ldx #>CMP_NE16
    jsr emit_jsr
    jmp emit_comparison_convert_carry

emit_comparison_not_ne:
    pla
    pha
    cmp #TOK_LT
    bne emit_comparison_not_lt
    lda #<CMP_GT16         ; Swapped: left < right ≡ right > left
    ldx #>CMP_GT16
    jsr emit_jsr
    jmp emit_comparison_convert_carry

emit_comparison_not_lt:
    pla
    pha
    cmp #TOK_LE
    bne emit_comparison_not_le
    lda #<CMP_GE16         ; Swapped: left <= right ≡ right >= left
    ldx #>CMP_GE16
    jsr emit_jsr
    jmp emit_comparison_convert_carry

emit_comparison_not_le:
    pla
    pha
    cmp #TOK_GT
    bne emit_comparison_not_gt
    lda #<CMP_LT16         ; Swapped: left > right ≡ right < left
    ldx #>CMP_LT16
    jsr emit_jsr
    jmp emit_comparison_convert_carry

emit_comparison_not_gt:
    pla
    pha
    cmp #TOK_GE
    bne emit_comparison_done_cmp
    lda #<CMP_LE16         ; Swapped: left >= right ≡ right <= left
    ldx #>CMP_LE16
    jsr emit_jsr

emit_comparison_convert_carry:
    ; Convert Carry flag to R0 = 0 or 1
    ; Emit: LDA #0 / ROL A / STA R0 / STZ R0+1
    lda #$A9           ; LDA #imm
    jsr emit_byte
    lda #$00
    jsr emit_byte

    lda #$2A           ; ROL A
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$64           ; STZ zp (65C02)
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

emit_comparison_done_cmp:
    pla                ; Clean up stack
    rts

; --- emit_dereference ---
; Emit pointer dereference code
; Input: R0 = pointer address
; Output: R0 = value at address
; Emits: Copy R0 to PTR0, then LDA (PTR0),Y / STA R0
emit_dereference:
    ; Copy R0 to PTR0
    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #PTR0
    jsr emit_byte

    lda #$A5           ; LDA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte

    lda #$85           ; STA zp
    jsr emit_byte
    lda #PTR0_H
    jsr emit_byte

    ; LDY #0
    lda #$A0           ; LDY #imm
    jsr emit_byte
    lda #$00
    jsr emit_byte

    ; LDA (PTR0),Y
    lda #$B1           ; LDA (zp),Y
    jsr emit_byte
    lda #PTR0
    jsr emit_byte

    ; STA R0
    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0
    jsr emit_byte

    ; INY
    lda #$C8           ; INY
    jsr emit_byte

    ; LDA (PTR0),Y
    lda #$B1           ; LDA (zp),Y
    jsr emit_byte
    lda #PTR0
    jsr emit_byte

    ; STA R0+1
    lda #$85           ; STA zp
    jsr emit_byte
    lda #R0_H
    jsr emit_byte
    rts

; --- patch_main_jmp ---
; Patch the initial JMP to main at MEM_GENCODE
; Input: A = main address low, X = main address high
patch_main_jmp:
    pha
    txa
    pha

    ; Point ZP_TMP0 to MEM_GENCODE
    lda #<MEM_GENCODE
    sta ZP_TMP0
    lda #>MEM_GENCODE
    sta ZP_TMP0_H

    ; Write JMP opcode
    ldy #0
    lda #$4C           ; JMP abs
    sta (ZP_TMP0),y

    ; Write address
    iny
    pla
    tax
    pla
    sta (ZP_TMP0),y
    iny
    txa
    sta (ZP_TMP0),y

    rts

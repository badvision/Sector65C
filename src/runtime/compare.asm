; === RUNTIME COMPARISON LIBRARY ===
; Signed and unsigned comparisons
; All functions use Carry flag for output: C=1 means TRUE, C=0 means FALSE

; --- CMP_EQ16 ---
; Compare R0 == R1
; Input: R0, R1 (16-bit)
; Output: Carry = 1 if equal, 0 if not equal
CMP_EQ16:
    lda R0
    cmp R1
    bne .eq_not_equal
    lda R0_H
    cmp R1_H
    bne .eq_not_equal
    ; Equal - set carry
    sec
    rts
.eq_not_equal:
    ; Not equal - clear carry
    clc
    rts

; --- CMP_NE16 ---
; Compare R0 != R1
; Input: R0, R1 (16-bit)
; Output: Carry = 1 if not equal, 0 if equal
CMP_NE16:
    lda R0
    cmp R1
    bne .ne_not_equal
    lda R0_H
    cmp R1_H
    bne .ne_not_equal
    ; Equal - clear carry (not equal is false)
    clc
    rts
.ne_not_equal:
    ; Not equal - set carry (not equal is true)
    sec
    rts

; --- CMP_LT16 ---
; Compare R0 < R1 (signed)
; Input: R0, R1 (16-bit signed)
; Output: Carry = 1 if R0 < R1, 0 otherwise
CMP_LT16:
    ; Check if signs differ by XORing high bytes
    lda R0_H
    eor R1_H
    bpl .lt_same_sign      ; If bit 7 is clear, signs are the same

    ; Signs differ - check which is negative
    lda R0_H
    bmi .lt_r0_negative    ; If R0 is negative, R0 < R1

    ; R0 is positive, R1 is negative: R0 > R1
    clc                 ; Less-than is false
    rts

.lt_r0_negative:
    ; R0 is negative, R1 is positive: R0 < R1
    sec                 ; Less-than is true
    rts

.lt_same_sign:
    ; Same sign - do unsigned comparison
    ; Compare high bytes first
    lda R0_H
    cmp R1_H
    bne .lt_high_diff      ; If high bytes differ, result is determined

    ; High bytes equal, compare low bytes
    lda R0
    cmp R1
    bcc .lt_less_than      ; If R0 < R1 (unsigned), return true
    ; R0 >= R1
    clc
    rts

.lt_high_diff:
    bcc .lt_less_than      ; If R0_H < R1_H (unsigned), return true
    ; R0_H >= R1_H
    clc
    rts

.lt_less_than:
    sec
    rts

; --- CMP_LE16 ---
; Compare R0 <= R1 (signed)
; Input: R0, R1 (16-bit signed)
; Output: Carry = 1 if R0 <= R1, 0 otherwise
CMP_LE16:
    ; R0 <= R1 is true if R0 < R1 OR R0 == R1
    ; First check equality
    lda R0
    cmp R1
    bne .le_check_lt
    lda R0_H
    cmp R1_H
    bne .le_check_lt
    ; Equal - return true
    sec
    rts

.le_check_lt:
    ; Not equal - check if less than
    jsr CMP_LT16
    rts

; --- CMP_GT16 ---
; Compare R0 > R1 (signed)
; Input: R0, R1 (16-bit signed)
; Output: Carry = 1 if R0 > R1, 0 otherwise
CMP_GT16:
    ; Check if signs differ
    lda R0_H
    eor R1_H
    bpl .gt_same_sign

    ; Signs differ - check which is negative
    lda R0_H
    bmi .gt_r0_negative    ; If R0 is negative, R0 < R1 (GT is false)

    ; R0 is positive, R1 is negative: R0 > R1 (GT is true)
    sec
    rts

.gt_r0_negative:
    ; R0 is negative, R1 is positive: R0 < R1 (GT is false)
    clc
    rts

.gt_same_sign:
    ; Same sign - do unsigned comparison
    ; Compare high bytes first
    lda R0_H
    cmp R1_H
    bne .gt_high_diff

    ; High bytes equal, compare low bytes
    lda R0
    cmp R1
    beq .gt_equal          ; If equal, GT is false
    bcc .gt_less_than      ; If R0 < R1, GT is false
    ; R0 > R1
    sec
    rts

.gt_high_diff:
    beq .gt_equal
    bcc .gt_less_than
    ; R0_H > R1_H
    sec
    rts

.gt_equal:
.gt_less_than:
    clc
    rts

; --- CMP_GE16 ---
; Compare R0 >= R1 (signed)
; Input: R0, R1 (16-bit signed)
; Output: Carry = 1 if R0 >= R1, 0 otherwise
CMP_GE16:
    ; R0 >= R1 is true if R0 > R1 OR R0 == R1
    ; First check equality
    lda R0
    cmp R1
    bne .ge_check_gt
    lda R0_H
    cmp R1_H
    bne .ge_check_gt
    ; Equal - return true
    sec
    rts

.ge_check_gt:
    ; Not equal - check if greater than
    jsr CMP_GT16
    rts

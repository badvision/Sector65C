; === RUNTIME MATH LIBRARY ===
; 16-bit arithmetic operations

; --- MUL16 ---
; Multiply R1 by R0, result in R0 (low 16 bits)
; Input: R1 = multiplicand (16-bit, $82-$83)
;        R0 = multiplier (16-bit, $80-$81)
; Output: R0 = result (16-bit, low 16 bits only)
; Destroys: RTMP0, RTMP1, RTMP2
; Algorithm: Binary shift-and-add multiplication
MUL16:
    ; Clear result accumulator in RTMP0/RTMP1
    lda #0
    sta RTMP0
    sta RTMP0_H

    ; Copy R1 (multiplicand) to RTMP2 for shifting
    lda R1
    sta RTMP2
    lda R1_H
    sta RTMP2_H

    ; Loop counter: 16 iterations
    ldx #16

.mul_loop:
    ; Check LSB of R0 (multiplier)
    lsr R0_H        ; Shift R0 right
    ror R0          ; Carry goes into bit 7 of low byte
    bcc .skip_add   ; If carry clear, bit was 0, skip addition

    ; Add RTMP2 (shifted multiplicand) to result
    clc
    lda RTMP0
    adc RTMP2
    sta RTMP0
    lda RTMP0_H
    adc RTMP2_H
    sta RTMP0_H

.skip_add:
    ; Shift multiplicand left for next iteration
    asl RTMP2
    rol RTMP2_H

    ; Decrement counter and loop
    dex
    bne .mul_loop

    ; Copy result to R0
    lda RTMP0
    sta R0
    lda RTMP0_H
    sta R0_H

    rts

; --- SHL16 ---
; Shift R1 left by R0 bits, result in R0
; Input: R1 = value (16-bit)
;        R0 = shift count (8-bit, only low byte used, 0-15)
; Output: R0 = result
SHL16:
    ; Load shift count, copy value to R0
    lda R0
    tax                  ; X = shift count
    lda R1
    sta R0
    lda R1_H
    sta R0_H

    ; Check if shift count is zero
    cpx #0
    beq .shl_done

.shl_loop:
    asl R0
    rol R0_H
    dex
    bne .shl_loop

.shl_done:
    rts

; --- SHR16 ---
; Shift R1 right by R0 bits (logical shift), result in R0
; Input: R1 = value (16-bit)
;        R0 = shift count (8-bit, only low byte used, 0-15)
; Output: R0 = result
SHR16:
    ; Load shift count, copy value to R0
    lda R0
    tax                  ; X = shift count
    lda R1
    sta R0
    lda R1_H
    sta R0_H

    ; Check if shift count is zero
    cpx #0
    beq .shr_done

.shr_loop:
    lsr R0_H
    ror R0
    dex
    bne .shr_loop

.shr_done:
    rts

; --- ADD16 ---
; Add R1 to R0
; Input: R0, R1 (16-bit)
; Output: R0 = R0 + R1
ADD16:
    ; TODO: 16-bit addition with carry
    clc
    lda R0
    adc R1
    sta R0
    lda R0_H
    adc R1_H
    sta R0_H
    rts

; --- SUB16 ---
; Subtract R1 from R0
; Input: R0, R1 (16-bit)
; Output: R0 = R0 - R1
SUB16:
    sec
    lda R0
    sbc R1
    sta R0
    lda R0_H
    sbc R1_H
    sta R0_H
    rts

; --- NEG16 ---
; Negate R0 (two's complement: R0 = 0 - R0)
; Input: R0 (16-bit)
; Output: R0 = -R0
NEG16:
    sec
    lda #0
    sbc R0
    sta R0
    lda #0
    sbc R0_H
    sta R0_H
    rts

; --- DIVMOD16 ---
; Unsigned 16-bit division with result cache
; Input: R1 = dividend, R0 = divisor
; Output: R1 = quotient, RTMP0/RTMP0_H = remainder
; Cache: If inputs match previous call, returns cached results
DIVMOD16:
    ; Check cache - compare inputs with last call
    lda R1
    cmp div_cache_dividend
    bne .div_cache_miss
    lda R1_H
    cmp div_cache_dividend+1
    bne .div_cache_miss
    lda R0
    cmp div_cache_divisor
    bne .div_cache_miss
    lda R0_H
    cmp div_cache_divisor+1
    bne .div_cache_miss

    ; Cache hit - restore cached results
    lda div_cache_quotient
    sta R1
    lda div_cache_quotient+1
    sta R1_H
    lda div_cache_remainder
    sta RTMP0
    lda div_cache_remainder+1
    sta RTMP0_H
    rts

.div_cache_miss:
    ; Save inputs to cache
    lda R1
    sta div_cache_dividend
    lda R1_H
    sta div_cache_dividend+1
    lda R0
    sta div_cache_divisor
    lda R0_H
    sta div_cache_divisor+1

    ; Clear remainder
    lda #0
    sta RTMP0
    sta RTMP0_H

    ; 16-bit binary long division
    ldx #16

.div_loop:
    ; Shift dividend left, MSB goes to carry
    asl R1
    rol R1_H
    ; Shift carry into remainder
    rol RTMP0
    rol RTMP0_H
    ; Trial subtraction: remainder - divisor
    sec
    lda RTMP0
    sbc R0
    tay                     ; Save tentative low byte
    lda RTMP0_H
    sbc R0_H
    bcc .div_skip           ; remainder < divisor, skip

    ; Remainder >= divisor: commit subtraction, set quotient bit
    sta RTMP0_H
    sty RTMP0
    inc R1                  ; Set LSB of quotient

.div_skip:
    dex
    bne .div_loop

    ; Cache results
    lda R1
    sta div_cache_quotient
    lda R1_H
    sta div_cache_quotient+1
    lda RTMP0
    sta div_cache_remainder
    lda RTMP0_H
    sta div_cache_remainder+1
    rts

; Division cache storage
div_cache_dividend:  !word $FFFF     ; Init to unlikely value
div_cache_divisor:   !word $FFFF
div_cache_quotient:  !word $0000
div_cache_remainder: !word $0000

; --- DIV16 ---
; Unsigned 16-bit division: R0 = R1 / R0
; Input: R1 = dividend, R0 = divisor
; Output: R0 = quotient
DIV16:
    jsr DIVMOD16
    ; Quotient is in R1, copy to R0
    lda R1
    sta R0
    lda R1_H
    sta R0_H
    rts

; --- MOD16 ---
; Unsigned 16-bit modulo: R0 = R1 % R0
; Input: R1 = dividend, R0 = divisor
; Output: R0 = remainder
MOD16:
    jsr DIVMOD16
    ; Remainder is in RTMP0, copy to R0
    lda RTMP0
    sta R0
    lda RTMP0_H
    sta R0_H
    rts

; --- LAND16 ---
; Logical AND: R0 = (R1 != 0) && (R0 != 0) ? 1 : 0
; Input: R1, R0 (16-bit)
; Output: R0 = 0 or 1
LAND16:
    lda R1
    ora R1_H
    beq .land_false         ; R1 == 0 → false
    lda R0
    ora R0_H
    beq .land_false         ; R0 == 0 → false
    lda #1
    sta R0
    lda #0
    sta R0_H
    rts
.land_false:
    lda #0
    sta R0
    sta R0_H
    rts

; --- LOR16 ---
; Logical OR: R0 = (R1 != 0) || (R0 != 0) ? 1 : 0
; Input: R1, R0 (16-bit)
; Output: R0 = 0 or 1
LOR16:
    lda R1
    ora R1_H
    bne .lor_true           ; R1 != 0 → true
    lda R0
    ora R0_H
    bne .lor_true           ; R0 != 0 → true
    lda #0
    sta R0
    sta R0_H
    rts
.lor_true:
    lda #1
    sta R0
    lda #0
    sta R0_H
    rts

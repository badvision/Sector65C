; === TEST HARNESS FRAMEWORK ===
; Provides macros for unit testing 65C02 code

!cpu 65c02

!source "src/include/zeropage.inc"
!source "src/include/memory.inc"

; === Test Counter Variables ===
test_count = $0300
pass_count = $0301
fail_count = $0302

; === Macros ===

; Print test name and initialize
!macro test_start .name {
    lda #0
    sta test_count
    sta pass_count
    sta fail_count
    
    ; Print test name
    ldx #0
.print_loop:
    lda .name,x
    beq .done
    jsr COUT
    inx
    bne .print_loop
.done:
    jsr CROUT
}

; Assert 8-bit memory value equals expected
!macro assert_eq_8 .addr, .expected {
    inc test_count
    lda .addr
    cmp #.expected
    beq .pass
    inc fail_count
    jmp .done
.pass:
    inc pass_count
.done:
}

; Assert 16-bit memory value equals expected (lo, hi)
!macro assert_eq_16 .addr, .expected_lo, .expected_hi {
    inc test_count
    lda .addr
    cmp #.expected_lo
    bne .fail
    lda .addr+1
    cmp #.expected_hi
    beq .pass
.fail:
    inc fail_count
    jmp .done
.pass:
    inc pass_count
.done:
}

; Print pass marker
!macro test_pass {
    lda #'P'
    jsr COUT
    lda #'A'
    jsr COUT
    lda #'S'
    jsr COUT
    lda #'S'
    jsr COUT
    jsr CROUT
}

; Print fail marker
!macro test_fail {
    lda #'F'
    jsr COUT
    lda #'A'
    jsr COUT
    lda #'I'
    jsr COUT
    lda #'L'
    jsr COUT
    jsr CROUT
}

; Print test summary
!macro test_summary {
    ; Print "Tests: "
    lda #'T'
    jsr COUT
    lda #'e'
    jsr COUT
    lda #'s'
    jsr COUT
    lda #'t'
    jsr COUT
    lda #'s'
    jsr COUT
    lda #':'
    jsr COUT
    lda #' '
    jsr COUT
    
    ; Print total count
    lda test_count
    jsr print_decimal
    jsr CROUT
    
    ; Print "Pass: "
    lda #'P'
    jsr COUT
    lda #'a'
    jsr COUT
    lda #'s'
    jsr COUT
    lda #'s'
    jsr COUT
    lda #':'
    jsr COUT
    lda #' '
    jsr COUT
    
    lda pass_count
    jsr print_decimal
    jsr CROUT
    
    ; Print "Fail: "
    lda #'F'
    jsr COUT
    lda #'a'
    jsr COUT
    lda #'i'
    jsr COUT
    lda #'l'
    jsr COUT
    lda #':'
    jsr COUT
    lda #' '
    jsr COUT
    
    lda fail_count
    jsr print_decimal
    jsr CROUT
    jmp .end_summary

; Helper: Print decimal number in A register
print_decimal:
    pha
    cmp #10
    bcc .single_digit
    ; Two digits
    ldx #0
.div10:
    sec
    sbc #10
    inx
    cmp #10
    bcs .div10
    pha
    txa
    ora #'0'
    jsr COUT
    pla
.single_digit:
    ora #'0'
    jsr COUT
    pla
    rts

.end_summary:
}

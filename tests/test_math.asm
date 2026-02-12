; === TEST: Runtime Math Library ===

!cpu 65c02

!source "tests/harness.asm"

* = $4000

!source "src/runtime/math.asm"

start:
    +test_start test_name

    ; === MUL16 Tests ===

    ; Test 1: 6 * 7 = 42
    lda #6
    sta R1
    lda #0
    sta R1_H
    lda #7
    sta R0
    lda #0
    sta R0_H
    jsr MUL16
    +assert_eq_16 R0, $2A, $00  ; 42 = $2A

    ; Test 2: 0 * 100 = 0
    lda #0
    sta R1
    sta R1_H
    lda #100
    sta R0
    lda #0
    sta R0_H
    jsr MUL16
    +assert_eq_16 R0, $00, $00

    ; Test 3: 1 * 12345 = 12345
    lda #1
    sta R1
    lda #0
    sta R1_H
    lda #<12345
    sta R0
    lda #>12345
    sta R0_H
    jsr MUL16
    +assert_eq_16 R0, $39, $30  ; 12345 = $3039

    ; Test 4: 100 * 100 = 10000
    lda #100
    sta R1
    lda #0
    sta R1_H
    lda #100
    sta R0
    lda #0
    sta R0_H
    jsr MUL16
    +assert_eq_16 R0, $10, $27  ; 10000 = $2710

    ; Test 5: 255 * 255 = 65025
    lda #255
    sta R1
    lda #0
    sta R1_H
    lda #255
    sta R0
    lda #0
    sta R0_H
    jsr MUL16
    +assert_eq_16 R0, $01, $FE  ; 65025 = $FE01

    ; === SHL16 Tests ===

    ; Test 6: 1 << 0 = 1
    lda #1
    sta R0
    lda #0
    sta R0_H
    lda #0
    sta R1
    jsr SHL16
    +assert_eq_16 R0, $01, $00

    ; Test 7: 1 << 1 = 2
    lda #1
    sta R0
    lda #0
    sta R0_H
    lda #1
    sta R1
    jsr SHL16
    +assert_eq_16 R0, $02, $00

    ; Test 8: 1 << 8 = 256
    lda #1
    sta R0
    lda #0
    sta R0_H
    lda #8
    sta R1
    jsr SHL16
    +assert_eq_16 R0, $00, $01  ; 256 = $0100

    ; Test 9: $FF << 4 = $0FF0
    lda #$FF
    sta R0
    lda #0
    sta R0_H
    lda #4
    sta R1
    jsr SHL16
    +assert_eq_16 R0, $F0, $0F  ; $0FF0

    ; === SHR16 Tests ===

    ; Test 10: 256 >> 1 = 128
    lda #$00
    sta R0
    lda #$01
    sta R0_H
    lda #1
    sta R1
    jsr SHR16
    +assert_eq_16 R0, $80, $00  ; 128 = $0080

    ; Test 11: $8000 >> 15 = 1
    lda #$00
    sta R0
    lda #$80
    sta R0_H
    lda #15
    sta R1
    jsr SHR16
    +assert_eq_16 R0, $01, $00

    ; Test 12: 0 >> 5 = 0
    lda #0
    sta R0
    sta R0_H
    lda #5
    sta R1
    jsr SHR16
    +assert_eq_16 R0, $00, $00

    +test_summary

    rts

test_name:
    !text "Math Tests", 0

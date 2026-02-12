; === TEST: Runtime Comparison Library ===

!cpu 65c02

!source "tests/harness.asm"

* = $4000

!source "src/runtime/compare.asm"

; Test result storage for carry flag checks
test_result = $0303

start:
    +test_start test_name

    ; === CMP_EQ16 Tests ===

    ; Test 1: 42 == 42 → true
    lda #42
    sta R0
    lda #0
    sta R0_H
    lda #42
    sta R1
    lda #0
    sta R1_H
    jsr CMP_EQ16
    ; Carry should be set (1)
    lda #0
    rol             ; Shift carry into bit 0
    sta test_result
    +assert_eq_8 test_result, 1

    ; Test 2: 42 == 43 → false
    lda #42
    sta R0
    lda #0
    sta R0_H
    lda #43
    sta R1
    lda #0
    sta R1_H
    jsr CMP_EQ16
    ; Carry should be clear (0)
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 0

    ; === CMP_NE16 Tests ===

    ; Test 3: 42 != 43 → true
    lda #42
    sta R0
    lda #0
    sta R0_H
    lda #43
    sta R1
    lda #0
    sta R1_H
    jsr CMP_NE16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 1

    ; Test 4: 42 != 42 → false
    lda #42
    sta R0
    lda #0
    sta R0_H
    lda #42
    sta R1
    lda #0
    sta R1_H
    jsr CMP_NE16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 0

    ; === CMP_LT16 Tests ===

    ; Test 5: 5 < 10 → true
    lda #5
    sta R0
    lda #0
    sta R0_H
    lda #10
    sta R1
    lda #0
    sta R1_H
    jsr CMP_LT16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 1

    ; Test 6: 10 < 5 → false
    lda #10
    sta R0
    lda #0
    sta R0_H
    lda #5
    sta R1
    lda #0
    sta R1_H
    jsr CMP_LT16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 0

    ; Test 7: 5 < 5 → false
    lda #5
    sta R0
    lda #0
    sta R0_H
    lda #5
    sta R1
    lda #0
    sta R1_H
    jsr CMP_LT16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 0

    ; Test 8: -1 < 0 → true (signed! $FFFF < $0000)
    lda #$FF
    sta R0
    lda #$FF
    sta R0_H
    lda #0
    sta R1
    sta R1_H
    jsr CMP_LT16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 1

    ; Test 9: -100 < 100 → true
    ; -100 = $FF9C (two's complement)
    lda #$9C
    sta R0
    lda #$FF
    sta R0_H
    lda #100
    sta R1
    lda #0
    sta R1_H
    jsr CMP_LT16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 1

    ; === CMP_GT16 Tests ===

    ; Test 10: 10 > 5 → true
    lda #10
    sta R0
    lda #0
    sta R0_H
    lda #5
    sta R1
    lda #0
    sta R1_H
    jsr CMP_GT16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 1

    ; Test 11: -1 > 0 → false (signed)
    lda #$FF
    sta R0
    lda #$FF
    sta R0_H
    lda #0
    sta R1
    sta R1_H
    jsr CMP_GT16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 0

    ; === CMP_LE16 Tests ===

    ; Test 12: 5 <= 5 → true
    lda #5
    sta R0
    lda #0
    sta R0_H
    lda #5
    sta R1
    lda #0
    sta R1_H
    jsr CMP_LE16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 1

    ; === CMP_GE16 Tests ===

    ; Test 13: 5 >= 5 → true
    lda #5
    sta R0
    lda #0
    sta R0_H
    lda #5
    sta R1
    lda #0
    sta R1_H
    jsr CMP_GE16
    lda #0
    rol
    sta test_result
    +assert_eq_8 test_result, 1

    +test_summary

    rts

test_name:
    !text "Comparison Tests", 0

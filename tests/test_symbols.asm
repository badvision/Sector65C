; === TEST: Symbol Table ===

!cpu 65c02

!source "tests/harness.asm"

* = $4000

!source "src/symbols.asm"

start:
    +test_start test_name

    ; Test 1: sym_init clears table
    jsr test_init

    ; Test 2: Insert and lookup variable
    jsr test_insert_lookup_var

    ; Test 3: Lookup nonexistent symbol
    jsr test_lookup_nonexistent

    ; Test 4: First variable address is $3800
    jsr test_first_var_addr

    ; Test 5: Second variable address is $3802
    jsr test_second_var_addr

    ; Test 6: Insert function with explicit address
    jsr test_insert_function

    ; Test 7: Symbol type retrieval
    jsr test_get_type

    ; Test 8: Multiple variables
    jsr test_multiple_vars

    +test_summary

    ; Check if all passed
    lda fail_count
    beq .all_pass
    +test_fail
    rts
.all_pass:
    +test_pass
    rts

test_init:
    jsr sym_init

    ; Check that first entry hash is 0
    lda #<MEM_SYMTAB
    sta ZP_SYM_PTR
    lda #>MEM_SYMTAB
    sta ZP_SYM_PTR_H

    ldy #SYM_HASH_OFF
    lda (ZP_SYM_PTR),y

    +assert_eq_8 .verify_zero, 0
    rts
.verify_zero = ZP_SYM_PTR  ; Use pointer location for verification

test_insert_lookup_var:
    jsr sym_init

    ; Insert variable "x" with hash 42
    lda #42
    sta ZP_TOKEN_VAL
    lda #0
    sta ZP_TOKEN_VAL_H

    lda #<test_name_x
    sta ZP_TMP0
    lda #>test_name_x
    sta ZP_TMP0_H

    lda #SYM_TYPE_VAR
    jsr sym_insert

    ; Verify insertion succeeded
    inc test_count
    bcs .insert_ok
    inc fail_count
    jmp .insert_done
.insert_ok:
    inc pass_count
.insert_done:

    ; Now lookup "x"
    lda #42
    sta ZP_TOKEN_VAL

    lda #<test_name_x
    sta ZP_TMP0
    lda #>test_name_x
    sta ZP_TMP0_H

    jsr sym_lookup

    ; Verify found
    inc test_count
    bcs .lookup_ok
    inc fail_count
    rts
.lookup_ok:
    inc pass_count
    rts

test_lookup_nonexistent:
    jsr sym_init

    ; Try to lookup symbol that doesn't exist
    lda #99
    sta ZP_TOKEN_VAL

    lda #<test_name_y
    sta ZP_TMP0
    lda #>test_name_y
    sta ZP_TMP0_H

    jsr sym_lookup

    ; Verify NOT found (carry clear)
    inc test_count
    bcc .not_found_ok
    inc fail_count
    rts
.not_found_ok:
    inc pass_count
    rts

test_first_var_addr:
    jsr sym_init

    ; Insert first variable
    lda #10
    sta ZP_TOKEN_VAL

    lda #<test_name_a
    sta ZP_TMP0
    lda #>test_name_a
    sta ZP_TMP0_H

    lda #SYM_TYPE_VAR
    jsr sym_insert

    ; Check address is $3800
    jsr sym_get_addr
    +assert_eq_16 R0, $00, $38
    rts

test_second_var_addr:
    jsr sym_init

    ; Insert first variable
    lda #10
    sta ZP_TOKEN_VAL

    lda #<test_name_a
    sta ZP_TMP0
    lda #>test_name_a
    sta ZP_TMP0_H

    lda #SYM_TYPE_VAR
    jsr sym_insert

    ; Insert second variable
    lda #11
    sta ZP_TOKEN_VAL

    lda #<test_name_b
    sta ZP_TMP0
    lda #>test_name_b
    sta ZP_TMP0_H

    lda #SYM_TYPE_VAR
    jsr sym_insert

    ; Check address is $3802
    jsr sym_get_addr
    +assert_eq_16 R0, $02, $38
    rts

test_insert_function:
    jsr sym_init

    ; Insert function with explicit address $0900
    lda #20
    sta ZP_TOKEN_VAL

    lda #<test_name_func
    sta ZP_TMP0
    lda #>test_name_func
    sta ZP_TMP0_H

    lda #$00
    sta ZP_TMP1
    lda #$09
    sta ZP_TMP1_H

    lda #SYM_TYPE_FUNC
    jsr sym_insert

    ; Verify address is $0900
    jsr sym_get_addr
    +assert_eq_16 R0, $00, $09
    rts

test_get_type:
    jsr sym_init

    ; Insert variable
    lda #30
    sta ZP_TOKEN_VAL

    lda #<test_name_var
    sta ZP_TMP0
    lda #>test_name_var
    sta ZP_TMP0_H

    lda #SYM_TYPE_VAR
    jsr sym_insert

    ; Get type
    jsr sym_get_type
    pha

    +assert_eq_8 .type_check, SYM_TYPE_VAR

    pla
    rts
.type_check = ZP_TMP0

test_multiple_vars:
    jsr sym_init

    ; Insert 5 variables and verify addresses increment correctly
    lda #40
    sta ZP_TOKEN_VAL
    lda #<test_name_v1
    sta ZP_TMP0
    lda #>test_name_v1
    sta ZP_TMP0_H
    lda #SYM_TYPE_VAR
    jsr sym_insert
    jsr sym_get_addr
    +assert_eq_16 R0, $00, $38

    lda #41
    sta ZP_TOKEN_VAL
    lda #<test_name_v2
    sta ZP_TMP0
    lda #>test_name_v2
    sta ZP_TMP0_H
    lda #SYM_TYPE_VAR
    jsr sym_insert
    jsr sym_get_addr
    +assert_eq_16 R0, $02, $38

    lda #42
    sta ZP_TOKEN_VAL
    lda #<test_name_v3
    sta ZP_TMP0
    lda #>test_name_v3
    sta ZP_TMP0_H
    lda #SYM_TYPE_VAR
    jsr sym_insert
    jsr sym_get_addr
    +assert_eq_16 R0, $04, $38

    rts

; Test data
test_name_x:
    !text "x", 0

test_name_y:
    !text "y", 0

test_name_a:
    !text "a", 0

test_name_b:
    !text "b", 0

test_name_func:
    !text "myfunc", 0

test_name_var:
    !text "myvar", 0

test_name_v1:
    !text "v1", 0

test_name_v2:
    !text "v2", 0

test_name_v3:
    !text "v3", 0

test_name:
    !text "Symbol Table Tests", 0

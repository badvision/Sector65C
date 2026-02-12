; === TEST: Tokenizer ===

!cpu 65c02

!source "tests/harness.asm"
!source "src/include/tokens.inc"

* = $4000

!source "src/tokenizer.asm"

start:
    +test_start test_name

    ; Test 1: "int" keyword
    jsr test_int_keyword

    ; Test 2: "void" keyword
    jsr test_void_keyword

    ; Test 3: "if" keyword
    jsr test_if_keyword

    ; Test 4: "while" keyword
    jsr test_while_keyword

    ; Test 5: "42" number
    jsr test_number_42

    ; Test 6: "+" operator
    jsr test_plus_operator

    ; Test 7: "==" operator
    jsr test_eqeq_operator

    ; Test 8: "!=" operator
    jsr test_ne_operator

    ; Test 9: Whitespace skipping
    jsr test_whitespace_skip

    ; Test 10: Comment skipping
    jsr test_comment_skip

    ; Test 11: Identifier "x"
    jsr test_identifier_x

    ; Test 12: Sequence "int x ;"
    jsr test_sequence

    ; Test 13: Hex number 0x2A
    jsr test_hex_number

    ; Test 14: All single-char operators
    jsr test_all_single_ops

    ; Test 15: Block comment
    jsr test_block_comment

    +test_summary

    ; Check if all passed
    lda fail_count
    beq .all_pass
    +test_fail
    rts
.all_pass:
    +test_pass
    rts

test_int_keyword:
    ; Set up source "int"
    lda #<src_int
    sta ZP_SRC_PTR
    lda #>src_int
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_INT
    rts

test_void_keyword:
    lda #<src_void
    sta ZP_SRC_PTR
    lda #>src_void
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_VOID
    rts

test_if_keyword:
    lda #<src_if
    sta ZP_SRC_PTR
    lda #>src_if
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_IF
    rts

test_while_keyword:
    lda #<src_while
    sta ZP_SRC_PTR
    lda #>src_while
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_WHILE
    rts

test_number_42:
    lda #<src_42
    sta ZP_SRC_PTR
    lda #>src_42
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_NUM
    +assert_eq_16 ZP_TOKEN_VAL, 42, 0
    rts

test_plus_operator:
    lda #<src_plus
    sta ZP_SRC_PTR
    lda #>src_plus
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_PLUS
    rts

test_eqeq_operator:
    lda #<src_eqeq
    sta ZP_SRC_PTR
    lda #>src_eqeq
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_EQEQ
    rts

test_ne_operator:
    lda #<src_ne
    sta ZP_SRC_PTR
    lda #>src_ne
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_NE
    rts

test_whitespace_skip:
    lda #<src_whitespace
    sta ZP_SRC_PTR
    lda #>src_whitespace
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_INT
    rts

test_comment_skip:
    lda #<src_comment
    sta ZP_SRC_PTR
    lda #>src_comment
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_INT
    rts

test_identifier_x:
    lda #<src_ident_x
    sta ZP_SRC_PTR
    lda #>src_ident_x
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_IDENT
    ; Just verify hash is non-zero
    lda ZP_TOKEN_VAL
    beq .fail
    inc pass_count
    jmp .done
.fail:
    inc fail_count
.done:
    inc test_count
    rts

test_sequence:
    lda #<src_sequence
    sta ZP_SRC_PTR
    lda #>src_sequence
    sta ZP_SRC_PTR_H

    ; Token 1: int
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_INT

    ; Token 2: x
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_IDENT

    ; Token 3: ;
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_SEMI

    ; Token 4: EOF
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_EOF

    rts

test_hex_number:
    lda #<src_hex
    sta ZP_SRC_PTR
    lda #>src_hex
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_NUM
    +assert_eq_16 ZP_TOKEN_VAL, $2A, 0
    rts

test_all_single_ops:
    lda #<src_all_ops
    sta ZP_SRC_PTR
    lda #>src_all_ops
    sta ZP_SRC_PTR_H

    ; (
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_LPAREN

    ; )
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_RPAREN

    ; {
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_LBRACE

    ; }
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_RBRACE

    ; ;
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_SEMI

    ; ,
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_COMMA

    ; *
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_STAR

    ; &
    jsr tokenize
    +assert_eq_8 ZP_TOKEN, TOK_AMP

    rts

test_block_comment:
    lda #<src_block_comment
    sta ZP_SRC_PTR
    lda #>src_block_comment
    sta ZP_SRC_PTR_H

    jsr tokenize

    +assert_eq_8 ZP_TOKEN, TOK_VOID
    rts

; Test data
src_int:
    !text "int", 0

src_void:
    !text "void", 0

src_if:
    !text "if", 0

src_while:
    !text "while", 0

src_42:
    !text "42", 0

src_plus:
    !text "+", 0

src_eqeq:
    !text "==", 0

src_ne:
    !text "!=", 0

src_whitespace:
    !text "  ", $0A, "  int", 0

src_comment:
    !text "// This is a comment", $0A, "int", 0

src_ident_x:
    !text "x", 0

src_sequence:
    !text "int x ;", 0

src_hex:
    !text "0x2A", 0

src_all_ops:
    !text "(){};,*&", 0

src_block_comment:
    !text "/* multi", $0A, "line", $0A, "comment */void", 0

test_name:
    !text "Tokenizer Tests", 0

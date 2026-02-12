; === TOKENIZER ===
; Breaks source code into tokens

!source "src/include/zeropage.inc"
!source "src/include/tokens.inc"

; Identifier buffer for parsing identifiers
ident_buffer = MEM_COMPILER  ; Use first 32 bytes of compiler memory

; --- tokenize ---
; Parse next token from source buffer
; Input: ZP_SRC_PTR points to current position
; Output: ZP_TOKEN = token type
;         ZP_TOKEN_VAL = token value (hash or number)
;         ZP_SRC_PTR updated
tokenize:
tok_restart:
    jsr skip_whitespace

    ; Check for EOF
    ldy #0
    lda (ZP_SRC_PTR),y
    bne tok_not_eof
    jmp tok_eof
tok_not_eof:

    ; Check for comments
    cmp #'/'
    bne tok_not_comment

    ; Peek at next character
    iny
    lda (ZP_SRC_PTR),y
    cmp #'/'
    beq tok_line_comment
    cmp #'*'
    beq tok_block_comment

    ; Not a comment, treat as potential operator
    dey
    lda (ZP_SRC_PTR),y
    jmp tok_not_comment

tok_line_comment:
    ; Skip to end of line
    ldy #2
tok_line_comment_loop:
    lda (ZP_SRC_PTR),y
    bne tok_line_not_eof
    jmp tok_eof  ; EOF in comment
tok_line_not_eof:
    cmp #$0A  ; LF
    beq tok_line_comment_done
    cmp #$0D  ; CR
    beq tok_line_comment_done
    iny
    bne tok_line_comment_loop
tok_line_comment_done:
    tya
    clc
    adc ZP_SRC_PTR
    sta ZP_SRC_PTR
    bcc tok_restart
    inc ZP_SRC_PTR_H
    jmp tok_restart

tok_block_comment:
    ; Skip to */
    ldy #2
tok_block_comment_loop:
    lda (ZP_SRC_PTR),y
    bne tok_block_not_eof
    jmp tok_eof  ; EOF in comment (error but tolerate)
tok_block_not_eof:
    cmp #'*'
    bne tok_block_comment_cont
    iny
    lda (ZP_SRC_PTR),y
    bne tok_block_star_not_eof
    jmp tok_eof
tok_block_star_not_eof:
    cmp #'/'
    beq tok_block_comment_done
    dey
tok_block_comment_cont:
    iny
    bne tok_block_comment_loop
    ; Handle 256 byte boundary crossing
    lda ZP_SRC_PTR
    clc
    adc #$FF
    sta ZP_SRC_PTR
    inc ZP_SRC_PTR_H
    ldy #0
    jmp tok_block_comment_loop
tok_block_comment_done:
    iny
    tya
    clc
    adc ZP_SRC_PTR
    sta ZP_SRC_PTR
    bcc tok_restart
    inc ZP_SRC_PTR_H
    jmp tok_restart

tok_not_comment:
    ; Check for two-character operators
    ldy #0
    lda (ZP_SRC_PTR),y
    ldx #0
tok_check_two_char:
    cmp two_char_ops,x
    beq tok_found_two_char_first
    inx
    inx
    inx
    cpx #(two_char_ops_end - two_char_ops)
    bcc tok_check_two_char
    jmp tok_check_single_char

tok_found_two_char_first:
    ; Check second character
    iny
    lda (ZP_SRC_PTR),y
    inx
    cmp two_char_ops,x
    bne tok_check_single_char_restore
    ; Found two-character operator
    inx
    lda two_char_ops,x
    sta ZP_TOKEN
    lda #2
    clc
    adc ZP_SRC_PTR
    sta ZP_SRC_PTR
    bcc tok_done
    inc ZP_SRC_PTR_H
    jmp tok_done

tok_check_single_char_restore:
    dey                         ; Y back to 0
    lda (ZP_SRC_PTR),y         ; Reload first char
    inx                        ; Skip second char in table entry
    inx                        ; Skip token byte; X now at start of next entry
    cpx #(two_char_ops_end - two_char_ops)
    bcc tok_check_two_char     ; Continue scanning two-char ops table

tok_check_single_char:
    ; Check single-character operators
    ldy #0
    lda (ZP_SRC_PTR),y
    ldx #0
tok_check_single_loop:
    cmp single_char_ops,x
    beq tok_found_single_char
    inx
    inx
    cpx #(single_char_ops_end - single_char_ops)
    bcc tok_check_single_loop
    jmp tok_check_digit

tok_found_single_char:
    inx
    lda single_char_ops,x
    sta ZP_TOKEN
    inc ZP_SRC_PTR
    bne tok_done
    inc ZP_SRC_PTR_H
    jmp tok_done

tok_check_digit:
    ldy #0
    lda (ZP_SRC_PTR),y
    cmp #'0'
    bcc tok_check_alpha
    cmp #'9'+1
    bcs tok_check_alpha
    jmp parse_number

tok_check_alpha:
    ldy #0
    lda (ZP_SRC_PTR),y
    cmp #'_'
    beq tok_is_alpha
    cmp #'A'
    bcc tok_unknown
    cmp #'Z'+1
    bcc tok_is_alpha
    cmp #'a'
    bcc tok_unknown
    cmp #'z'+1
    bcs tok_unknown
tok_is_alpha:
    jmp parse_identifier

tok_unknown:
    ; Unknown character, treat as EOF
    lda #TOK_EOF
    sta ZP_TOKEN
    rts

tok_eof:
    lda #TOK_EOF
    sta ZP_TOKEN
tok_done:
    rts

; Two-character operators: char1, char2, token
two_char_ops:
    !byte '<', '<', TOK_LSHIFT
    !byte '>', '>', TOK_RSHIFT
    !byte '=', '=', TOK_EQEQ
    !byte '!', '=', TOK_NE
    !byte '<', '=', TOK_LE
    !byte '>', '=', TOK_GE
    !byte '&', '&', TOK_LAND
    !byte '|', '|', TOK_LOR
two_char_ops_end:

; Single-character operators: char, token
single_char_ops:
    !byte '(', TOK_LPAREN
    !byte ')', TOK_RPAREN
    !byte '{', TOK_LBRACE
    !byte '}', TOK_RBRACE
    !byte ';', TOK_SEMI
    !byte ',', TOK_COMMA
    !byte '*', TOK_STAR
    !byte '&', TOK_AMP
    !byte '+', TOK_PLUS
    !byte '-', TOK_MINUS
    !byte '<', TOK_LT
    !byte '>', TOK_GT
    !byte '=', TOK_ASSIGN
    !byte '|', TOK_OR
    !byte '^', TOK_XOR
    !byte '/', TOK_SLASH
    !byte '%', TOK_PERCENT
single_char_ops_end:

; --- skip_whitespace ---
; Skip spaces, tabs, newlines
skip_whitespace:
    ldy #0
skip_ws_loop:
    lda (ZP_SRC_PTR),y
    beq skip_ws_done  ; End of string
    cmp #' '
    beq skip_ws_skip
    cmp #$09  ; Tab
    beq skip_ws_skip
    cmp #$0A  ; LF
    beq skip_ws_skip
    cmp #$0D  ; CR
    beq skip_ws_skip
    rts  ; Not whitespace, done
skip_ws_skip:
    inc ZP_SRC_PTR
    bne skip_ws_loop
    inc ZP_SRC_PTR_H
    jmp skip_ws_loop
skip_ws_done:
    rts

; --- parse_identifier ---
; Parse identifier starting at ZP_SRC_PTR
; Output: ZP_TOKEN_VAL = hash of identifier
parse_identifier:
    ; Copy identifier to buffer
    ldy #0
ident_copy_loop:
    lda (ZP_SRC_PTR),y
    cmp #'_'
    beq ident_is_char
    cmp #'0'
    bcc ident_copy_done
    cmp #'9'+1
    bcc ident_is_char      ; 0-9 → valid in identifier (not first char)
    cmp #'A'
    bcc ident_copy_done    ; between '9'+1 and 'A'-1 → not ident char
    cmp #'Z'+1
    bcc ident_is_char      ; A-Z
    cmp #'a'
    bcc ident_check_digit  ; between 'Z'+1 and 'a'-1 → check further
    cmp #'z'+1
    bcc ident_is_char      ; a-z
ident_check_digit:
    ; Characters between '[' and '`' that aren't '_' - not valid
    jmp ident_copy_done
ident_is_char:
    sta ident_buffer,y
    iny
    cpy #28  ; Max identifier length
    bcc ident_copy_loop
ident_copy_done:
    lda #0
    sta ident_buffer,y  ; Null terminate

    ; Update source pointer
    tya
    clc
    adc ZP_SRC_PTR
    sta ZP_SRC_PTR
    bcc ident_no_carry
    inc ZP_SRC_PTR_H
ident_no_carry:

    ; Compute hash
    jsr compute_hash
    sta ZP_TOKEN_VAL
    lda #0
    sta ZP_TOKEN_VAL_H

    ; Check for keywords
    ldx #0
ident_keyword_loop:
    ldy #0
ident_compare_loop:
    lda ident_buffer,y
    cmp keywords,x
    bne ident_next_keyword
    inx
    beq ident_not_keyword  ; Safety check
    cmp #0
    beq ident_found_keyword  ; Both strings ended
    iny
    jmp ident_compare_loop

ident_found_keyword:
    ; X already points at token byte (moved by inx in compare loop)
    lda keywords,x
    sta ZP_TOKEN
    rts

ident_next_keyword:
    ; Skip to next keyword (find two nulls)
    lda keywords,x
    beq ident_found_first_null
    inx
    bne ident_next_keyword
    jmp ident_not_keyword  ; Safety: end of table
ident_found_first_null:
    inx
    lda keywords,x
    beq ident_not_keyword  ; Found second null (end marker), not a keyword
    ; X points at token byte, skip it and the following null
    inx  ; Skip token byte
    inx  ; Skip separator null, now at start of next keyword
    jmp ident_keyword_loop

ident_not_keyword:
    lda #TOK_IDENT
    sta ZP_TOKEN
    rts

; Keywords table: "keyword", 0, token, 0
keywords:
    !text "int", 0
    !byte TOK_INT, 0
    !text "void", 0
    !byte TOK_VOID, 0
    !text "if", 0
    !byte TOK_IF, 0
    !text "while", 0
    !byte TOK_WHILE, 0
    !text "return", 0
    !byte TOK_RETURN, 0
    !text "asm", 0
    !byte TOK_ASM, 0
    !byte 0, 0  ; End marker

; --- parse_number ---
; Parse decimal number
; Output: ZP_TOKEN_VAL = 16-bit number
parse_number:
    lda #0
    sta ZP_TOKEN_VAL
    sta ZP_TOKEN_VAL_H

    ; Check for 0x prefix
    ldy #0
    lda (ZP_SRC_PTR),y
    cmp #'0'
    bne num_decimal
    iny
    lda (ZP_SRC_PTR),y
    cmp #'x'
    beq num_hex
    cmp #'X'
    beq num_hex
    dey

num_decimal:
    ; Parse decimal digits
    ldy #0
num_decimal_loop:
    lda (ZP_SRC_PTR),y
    cmp #'0'
    bcc num_decimal_done
    cmp #'9'+1
    bcs num_decimal_done

    ; value = value * 10 + digit
    ; value * 10 = value * 8 + value * 2
    pha  ; Save digit

    ; Multiply by 2 (value * 2)
    lda ZP_TOKEN_VAL
    asl
    sta ZP_TMP0
    lda ZP_TOKEN_VAL_H
    rol
    sta ZP_TMP0_H

    ; Multiply by 8 (value * 8) - must use memory ASL/ROL pairs
    ; to properly propagate carry on each shift
    asl ZP_TOKEN_VAL
    rol ZP_TOKEN_VAL_H
    asl ZP_TOKEN_VAL
    rol ZP_TOKEN_VAL_H
    asl ZP_TOKEN_VAL
    rol ZP_TOKEN_VAL_H

    ; Add value*8 + value*2
    lda ZP_TOKEN_VAL
    clc
    adc ZP_TMP0
    sta ZP_TOKEN_VAL
    lda ZP_TOKEN_VAL_H
    adc ZP_TMP0_H
    sta ZP_TOKEN_VAL_H

    ; Add digit
    pla
    sec
    sbc #'0'
    clc
    adc ZP_TOKEN_VAL
    sta ZP_TOKEN_VAL
    bcc num_no_carry_dec
    inc ZP_TOKEN_VAL_H
num_no_carry_dec:
    iny
    jmp num_decimal_loop

num_decimal_done:
    tya
    clc
    adc ZP_SRC_PTR
    sta ZP_SRC_PTR
    bcc num_done
    inc ZP_SRC_PTR_H
    jmp num_done

num_hex:
    ; Skip 0x prefix
    ldy #2
num_hex_loop:
    lda (ZP_SRC_PTR),y
    cmp #'0'
    bcc num_hex_done
    cmp #'9'+1
    bcc num_is_hex_digit
    cmp #'A'
    bcc num_hex_done
    cmp #'F'+1
    bcc num_is_hex_alpha
    cmp #'a'
    bcc num_hex_done
    cmp #'f'+1
    bcs num_hex_done
num_is_hex_alpha:
    ; Convert A-F or a-f to 10-15
    and #$0F
    clc
    adc #9
    jmp num_add_hex_digit
num_is_hex_digit:
    sec
    sbc #'0'
num_add_hex_digit:
    pha
    ; Shift value left 4 bits
    lda ZP_TOKEN_VAL_H
    asl ZP_TOKEN_VAL
    rol
    asl ZP_TOKEN_VAL
    rol
    asl ZP_TOKEN_VAL
    rol
    asl ZP_TOKEN_VAL
    rol
    sta ZP_TOKEN_VAL_H
    ; Add digit
    pla
    clc
    adc ZP_TOKEN_VAL
    sta ZP_TOKEN_VAL
    bcc num_no_carry_hex
    inc ZP_TOKEN_VAL_H
num_no_carry_hex:
    iny
    jmp num_hex_loop

num_hex_done:
    tya
    clc
    adc ZP_SRC_PTR
    sta ZP_SRC_PTR
    bcc num_done
    inc ZP_SRC_PTR_H

num_done:
    lda #TOK_NUM
    sta ZP_TOKEN
    rts

; --- compute_hash ---
; Compute 8-bit hash of identifier in ident_buffer
; Output: A = hash value
compute_hash:
    lda #0
    sta ZP_TMP0  ; Hash accumulator
    ldy #0
hash_loop:
    lda ident_buffer,y
    beq hash_done

    ; Rotate left 1 bit: (hash << 1) | (hash >> 7)
    lda ZP_TMP0
    asl
    bcc hash_no_rotate_carry
    ora #1
hash_no_rotate_carry:
    ; XOR with character
    eor ident_buffer,y
    sta ZP_TMP0

    iny
    cpy #28
    bcc hash_loop

hash_done:
    lda ZP_TMP0
    bne hash_ok
    lda #1  ; Never return 0
hash_ok:
    rts

; === PARSER ===
; Recursive descent parser

!source "src/include/zeropage.inc"
!source "src/include/memory.inc"
!source "src/include/tokens.inc"

; External references
ident_buffer = MEM_COMPILER

; Main address storage (for patching initial JMP)
main_addr:
    !word $0000

; --- parse_program ---
; Parse entire program (declarations)
parse_program:
program_loop:
    lda ZP_TOKEN
    cmp #TOK_EOF
    bne program_not_eof
    jmp program_done
program_not_eof:
    jsr parse_declaration
    jmp program_loop
program_done:
    ; Patch the initial JMP to main
    lda main_addr
    ldx main_addr+1
    jsr patch_main_jmp
    rts

; --- parse_declaration ---
; Parse variable or function declaration
parse_declaration:
    lda ZP_TOKEN
    cmp #TOK_INT
    bne decl_check_void
    lda #SYM_TYPE_VAR
    pha
    jsr tokenize
    jmp decl_check_ident
decl_check_void:
    cmp #TOK_VOID
    beq decl_is_func
    jmp parse_error
decl_is_func:
    lda #SYM_TYPE_FUNC
    pha
    jsr tokenize
decl_check_ident:
    ; Check for identifier
    lda ZP_TOKEN
    cmp #TOK_IDENT
    beq decl_have_ident
    jmp parse_error
decl_have_ident:
    lda ZP_TOKEN_VAL
    pha
    lda #<ident_buffer
    sta ZP_TMP0
    lda #>ident_buffer
    sta ZP_TMP0_H
    jsr tokenize

    lda ZP_TOKEN
    cmp #TOK_LPAREN
    beq decl_function
    cmp #TOK_SEMI
    beq decl_have_semi
    jmp parse_error
decl_have_semi:
    ; Variable declaration
    pla
    sta ZP_TOKEN_VAL
    pla
    jsr sym_insert
    bcs decl_insert_ok
    jmp parse_error
decl_insert_ok:
    jsr tokenize
    rts

decl_function:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_RPAREN
    beq func_have_rparen
    jmp parse_error
func_have_rparen:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_LBRACE
    beq func_have_lbrace
    jmp parse_error
func_have_lbrace:
    lda ZP_CODEGEN_PTR
    sta ZP_TMP1
    lda ZP_CODEGEN_PTR_H
    sta ZP_TMP1_H

    pla
    sta ZP_TOKEN_VAL
    pla
    jsr sym_insert
    bcs func_insert_ok
    jmp parse_error
func_insert_ok:
    ; Check if main
    lda ident_buffer
    cmp #'m'
    bne func_not_main
    lda ident_buffer+1
    cmp #'a'
    bne func_not_main
    lda ident_buffer+2
    cmp #'i'
    bne func_not_main
    lda ident_buffer+3
    cmp #'n'
    bne func_not_main
    lda ident_buffer+4
    bne func_not_main
    lda ZP_TMP1
    sta main_addr
    lda ZP_TMP1_H
    sta main_addr+1
func_not_main:
    jsr tokenize
    jsr parse_compound_body
    jsr emit_rts
    rts

; --- parse_compound_body ---
parse_compound_body:
compound_loop:
    lda ZP_TOKEN
    cmp #TOK_RBRACE
    beq compound_done
    cmp #TOK_EOF
    bne compound_not_eof
    jmp parse_error
compound_not_eof:
    jsr parse_statement
    jmp compound_loop
compound_done:
    jsr tokenize
    rts

; --- parse_statement ---
parse_statement:
    lda ZP_TOKEN
    cmp #TOK_IF
    bne stmt_not_if
    jmp parse_if
stmt_not_if:
    cmp #TOK_WHILE
    bne stmt_not_while
    jmp parse_while
stmt_not_while:
    cmp #TOK_RETURN
    bne stmt_not_return
    jmp parse_return
stmt_not_return:
    cmp #TOK_ASM
    bne stmt_not_asm
    jmp parse_asm
stmt_not_asm:
    cmp #TOK_LBRACE
    bne stmt_try_expr
    jsr tokenize
    jsr parse_compound_body
    rts
stmt_try_expr:
    jsr parse_expression
    lda ZP_TOKEN
    cmp #TOK_SEMI
    beq stmt_have_semi
    jmp parse_error
stmt_have_semi:
    jsr tokenize
    rts

; --- parse_if ---
parse_if:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_LPAREN
    beq if_have_lparen
    jmp parse_error
if_have_lparen:
    jsr tokenize
    jsr parse_expression
    lda ZP_TOKEN
    cmp #TOK_RPAREN
    beq if_have_rparen
    jmp parse_error
if_have_rparen:
    jsr tokenize
    jsr emit_test_r0_zero
    jsr emit_jmp_placeholder
    lda ZP_TMP0
    sta ZP_IF_PATCH
    lda ZP_TMP0_H
    sta ZP_IF_PATCH_H
    lda ZP_TOKEN
    cmp #TOK_LBRACE
    beq if_have_lbrace
    jmp parse_error
if_have_lbrace:
    jsr tokenize
    jsr parse_compound_body
    lda ZP_IF_PATCH
    sta ZP_TMP0
    lda ZP_IF_PATCH_H
    sta ZP_TMP0_H
    jsr patch_jmp
    rts

; --- parse_while ---
parse_while:
    jsr tokenize
    lda ZP_CODEGEN_PTR
    sta ZP_LOOP_START
    lda ZP_CODEGEN_PTR_H
    sta ZP_LOOP_START_H
    lda ZP_TOKEN
    cmp #TOK_LPAREN
    beq while_have_lparen
    jmp parse_error
while_have_lparen:
    jsr tokenize
    jsr parse_expression
    lda ZP_TOKEN
    cmp #TOK_RPAREN
    beq while_have_rparen
    jmp parse_error
while_have_rparen:
    jsr tokenize
    jsr emit_test_r0_zero
    jsr emit_jmp_placeholder
    lda ZP_TMP0
    sta ZP_LOOP_PATCH
    lda ZP_TMP0_H
    sta ZP_LOOP_PATCH_H
    lda ZP_TOKEN
    cmp #TOK_LBRACE
    beq while_have_lbrace
    jmp parse_error
while_have_lbrace:
    jsr tokenize
    jsr parse_compound_body
    lda ZP_LOOP_START
    ldx ZP_LOOP_START_H
    jsr emit_jmp
    lda ZP_LOOP_PATCH
    sta ZP_TMP0
    lda ZP_LOOP_PATCH_H
    sta ZP_TMP0_H
    jsr patch_jmp
    rts

; --- parse_return ---
parse_return:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_SEMI
    beq return_have_semi
    jmp parse_error
return_have_semi:
    jsr tokenize
    jsr emit_rts
    rts

; --- parse_asm ---
parse_asm:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_NUM
    beq asm_have_num
    jmp parse_error
asm_have_num:
    lda ZP_TOKEN_VAL
    jsr emit_byte
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_SEMI
    beq asm_have_semi
    jmp parse_error
asm_have_semi:
    jsr tokenize
    rts

; --- parse_expression ---
parse_expression:
    jmp parse_assignment

; Temporary storage for assignment left-hand side
assign_lhs_name:
    !fill 28, 0  ; Space to save identifier name

; --- parse_assignment ---
parse_assignment:
    lda ZP_TOKEN
    cmp #TOK_IDENT
    bne parse_logical_or

    ; Save identifier name to temporary storage before ident_buffer gets overwritten
    ldx #0
assign_save_name_loop:
    lda ident_buffer,x
    sta assign_lhs_name,x
    beq assign_save_name_done
    inx
    cpx #28
    bcc assign_save_name_loop
assign_save_name_done:

    ; Save identifier hash
    lda ZP_TOKEN_VAL
    sta ZP_TMP1

    ; Save source pointer for potential rollback (speculative lookahead)
    lda ZP_SRC_PTR
    pha
    lda ZP_SRC_PTR_H
    pha

    ; Tokenize to check for '='
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_ASSIGN
    bne assign_not_assign

    ; It IS an assignment - discard saved source pointer
    pla
    pla

    ; Look up the identifier using saved name
    lda #<assign_lhs_name
    sta ZP_TMP0
    lda #>assign_lhs_name
    sta ZP_TMP0_H
    lda ZP_TMP1
    sta ZP_TOKEN_VAL
    jsr sym_lookup
    bcs assign_lookup_ok
    jmp parse_error
assign_lookup_ok:
    jsr sym_get_addr
    ; Save variable address on stack
    lda R0
    pha
    lda R0_H
    pha

    ; Tokenize to get first token of expression
    jsr tokenize

    ; Parse the right-hand side expression
    jsr parse_logical_or

    ; Emit store to variable
    pla  ; Pop address high
    tax
    pla  ; Pop address low
    jsr emit_store_var
    rts

assign_not_assign:
    ; Not an assignment - rollback source pointer (undo speculative tokenize)
    pla
    sta ZP_SRC_PTR_H
    pla
    sta ZP_SRC_PTR
    ; Restore identifier token
    lda ZP_TMP1
    sta ZP_TOKEN_VAL
    lda #TOK_IDENT
    sta ZP_TOKEN
    jmp parse_logical_or

; --- parse_logical_or ---
; Handles || (lowest precedence binary operator)
parse_logical_or:
    jsr parse_logical_and
logical_or_loop:
    lda ZP_TOKEN
    cmp #TOK_LOR
    bne logical_or_done
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_logical_and
    lda #<LOR16
    ldx #>LOR16
    jsr emit_jsr
    jmp logical_or_loop
logical_or_done:
    rts

; --- parse_logical_and ---
; Handles &&
parse_logical_and:
    jsr parse_bitwise_or
logical_and_loop:
    lda ZP_TOKEN
    cmp #TOK_LAND
    bne logical_and_done
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_bitwise_or
    lda #<LAND16
    ldx #>LAND16
    jsr emit_jsr
    jmp logical_and_loop
logical_and_done:
    rts

; --- parse_bitwise_or ---
; Handles | and ^ (bitwise OR/XOR)
parse_bitwise_or:
    jsr parse_bitand
logical_loop:
    lda ZP_TOKEN
    cmp #TOK_OR
    beq logical_is_or
    cmp #TOK_XOR
    beq logical_is_xor
    rts
logical_is_or:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_bitand
    jsr emit_or16
    jmp logical_loop
logical_is_xor:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_bitand
    jsr emit_xor16
    jmp logical_loop

; --- parse_bitand ---
parse_bitand:
    jsr parse_comparison
bitand_loop:
    lda ZP_TOKEN
    cmp #TOK_AMP
    bne bitand_done
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_comparison
    jsr emit_and16
    jmp bitand_loop
bitand_done:
    rts

; --- parse_comparison ---
parse_comparison:
    jsr parse_shift
    lda ZP_TOKEN
    cmp #TOK_EQEQ
    beq cmp_is_cmp
    cmp #TOK_NE
    beq cmp_is_cmp
    cmp #TOK_LT
    beq cmp_is_cmp
    cmp #TOK_GT
    beq cmp_is_cmp
    cmp #TOK_LE
    beq cmp_is_cmp
    cmp #TOK_GE
    bne cmp_no_cmp
cmp_is_cmp:
    pha
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_shift
    pla
    jsr emit_comparison
cmp_no_cmp:
    rts

; --- parse_shift ---
parse_shift:
    jsr parse_additive
shift_loop:
    lda ZP_TOKEN
    cmp #TOK_LSHIFT
    beq shift_is_lshift
    cmp #TOK_RSHIFT
    beq shift_is_rshift
    rts
shift_is_lshift:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_additive
    lda #<SHL16
    ldx #>SHL16
    jsr emit_jsr
    jmp shift_loop
shift_is_rshift:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_additive
    lda #<SHR16
    ldx #>SHR16
    jsr emit_jsr
    jmp shift_loop

; --- parse_additive ---
parse_additive:
    jsr parse_multiplicative
additive_loop:
    lda ZP_TOKEN
    cmp #TOK_PLUS
    beq additive_is_plus
    cmp #TOK_MINUS
    beq additive_is_minus
    rts
additive_is_plus:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_multiplicative
    jsr emit_add16
    jmp additive_loop
additive_is_minus:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_multiplicative
    jsr emit_sub16
    jmp additive_loop

; --- parse_multiplicative ---
parse_multiplicative:
    jsr parse_unary
mult_loop:
    lda ZP_TOKEN
    cmp #TOK_STAR
    beq mult_is_star
    cmp #TOK_SLASH
    beq mult_is_slash
    cmp #TOK_PERCENT
    beq mult_is_percent
    rts
mult_is_star:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_unary
    lda #<MUL16
    ldx #>MUL16
    jsr emit_jsr
    jmp mult_loop
mult_is_slash:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_unary
    lda #<DIV16
    ldx #>DIV16
    jsr emit_jsr
    jmp mult_loop
mult_is_percent:
    jsr emit_push_r0_to_r1
    jsr tokenize
    jsr parse_unary
    lda #<MOD16
    ldx #>MOD16
    jsr emit_jsr
    jmp mult_loop

; --- parse_unary ---
parse_unary:
    lda ZP_TOKEN
    cmp #TOK_STAR
    beq unary_deref
    cmp #TOK_AMP
    beq unary_addr
    cmp #TOK_MINUS
    beq unary_negate
    jmp parse_postfix

unary_negate:
    jsr tokenize
    jsr parse_unary          ; Recursive: handles -(-x), etc.
    lda #<NEG16
    ldx #>NEG16
    jsr emit_jsr
    rts

unary_deref:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_LPAREN
    beq deref_have_lparen
    jmp parse_error
deref_have_lparen:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_INT
    beq deref_have_int
    jmp parse_error
deref_have_int:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_STAR
    beq deref_have_star
    jmp parse_error
deref_have_star:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_RPAREN
    beq deref_have_rparen
    jmp parse_error
deref_have_rparen:
    jsr tokenize
    jsr parse_unary
    jsr emit_dereference
    rts

unary_addr:
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_IDENT
    beq addr_have_ident
    jmp parse_error
addr_have_ident:
    lda #<ident_buffer
    sta ZP_TMP0
    lda #>ident_buffer
    sta ZP_TMP0_H
    jsr sym_lookup
    bcs addr_lookup_ok
    jmp parse_error
addr_lookup_ok:
    jsr sym_get_addr
    lda R0
    sta ZP_TOKEN_VAL
    lda R0_H
    sta ZP_TOKEN_VAL_H
    jsr emit_load_imm
    jsr tokenize
    rts

; --- parse_postfix ---
parse_postfix:
    jsr parse_primary
    lda ZP_TOKEN
    cmp #TOK_LPAREN
    bne postfix_done
    lda R0
    pha
    lda R0_H
    pha
    jsr tokenize
    lda ZP_TOKEN
    cmp #TOK_RPAREN
    beq postfix_have_rparen
    jmp parse_error
postfix_have_rparen:
    jsr tokenize
    pla
    tax
    pla
    jsr emit_jsr
postfix_done:
    rts

; --- parse_primary ---
parse_primary:
    lda ZP_TOKEN
    cmp #TOK_IDENT
    beq primary_ident
    cmp #TOK_NUM
    beq primary_num
    cmp #TOK_LPAREN
    beq primary_paren
    jmp parse_error

primary_ident:
    lda #<ident_buffer
    sta ZP_TMP0
    lda #>ident_buffer
    sta ZP_TMP0_H
    jsr sym_lookup
    bcs prim_ident_lookup_ok
    jmp parse_error
prim_ident_lookup_ok:
    jsr sym_get_type
    cmp #SYM_TYPE_FUNC
    beq prim_ident_is_func
    jsr sym_get_addr
    lda R0
    ldx R0_H
    jsr emit_load_var
    jsr tokenize
    rts
prim_ident_is_func:
    jsr sym_get_addr
    lda R0
    sta ZP_TOKEN_VAL
    lda R0_H
    sta ZP_TOKEN_VAL_H
    jsr emit_load_imm
    jsr tokenize
    rts

primary_num:
    jsr emit_load_imm
    jsr tokenize
    rts

primary_paren:
    jsr tokenize
    jsr parse_expression
    lda ZP_TOKEN
    cmp #TOK_RPAREN
    beq prim_paren_have_rparen
    jmp parse_error
prim_paren_have_rparen:
    jsr tokenize
    rts

; --- parse_error ---
parse_error:
    jsr error_syntax
parse_error_halt:
    jmp parse_error_halt

parse_error_jmp:
    jmp parse_error

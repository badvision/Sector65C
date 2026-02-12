; === ERROR HANDLING ===
; Display error messages and halt

; --- error_syntax ---
; Report syntax error
!zone error_syntax {
error_syntax:
    ldx #0
err_syntax_loop:
    lda syntax_error_msg,x
    beq err_syntax_done
    jsr COUT
    inx
    jmp err_syntax_loop
err_syntax_done:
    jsr CROUT
err_syntax_hang:
    jmp err_syntax_hang
}

; --- error_symbol ---
; Report undefined symbol error
!zone error_symbol {
error_symbol:
    ldx #0
err_symbol_loop:
    lda symbol_error_msg,x
    beq err_symbol_done
    jsr COUT
    inx
    jmp err_symbol_loop
err_symbol_done:
    jsr CROUT
err_symbol_hang:
    jmp err_symbol_hang
}

; --- error_type ---
; Report type error
!zone error_type {
error_type:
    ldx #0
err_type_loop:
    lda type_error_msg,x
    beq err_type_done
    jsr COUT
    inx
    jmp err_type_loop
err_type_done:
    jsr CROUT
err_type_hang:
    jmp err_type_hang
}

; --- error_memory ---
; Report out of memory error
!zone error_memory {
error_memory:
    ldx #0
err_memory_loop:
    lda memory_error_msg,x
    beq err_memory_done
    jsr COUT
    inx
    jmp err_memory_loop
err_memory_done:
    jsr CROUT
err_memory_hang:
    jmp err_memory_hang
}

; --- Error messages ---
syntax_error_msg:
    !text "?SYNTAX ERROR", 0

symbol_error_msg:
    !text "?UNDEFINED SYMBOL", 0

type_error_msg:
    !text "?TYPE ERROR", 0

memory_error_msg:
    !text "?MEMORY FULL", 0

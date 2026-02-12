; === SECTORC65 - C COMPILER FOR 65C02 ===
; Main entry point and master assembly file

!cpu 65c02

; === Include Constants ===
!source "src/include/zeropage.inc"
!source "src/include/memory.inc"
!source "src/include/tokens.inc"

; === Compiler Code at $4000 ===
* = MEM_COMPILER

; --- Entry Point ---
compiler_start:
    ; Print banner
    ldx #0
.banner_loop:
    lda banner_msg,x
    beq .banner_done
    jsr COUT
    inx
    jmp .banner_loop
.banner_done:
    jsr CROUT

    ; Initialize compiler
    jsr sym_init          ; Clear symbol table
    jsr codegen_init      ; Initialize code generation pointer

    ; Set up source pointer to embedded test program
    lda #<test_source
    sta ZP_SRC_PTR
    lda #>test_source
    sta ZP_SRC_PTR_H

    ; Get first token
    jsr tokenize

    ; Parse the program
    jsr parse_program

    ; Execute compiled code (JSR so RTS returns here)
    jsr MEM_GENCODE

; --- After compiled program returns ---
execution_done:
    ; Display completion message
    ldx #0
.done_loop:
    lda done_msg,x
    beq .done_done
    jsr COUT
    inx
    jmp .done_loop
.done_done:
    jsr CROUT

    ; Halt (no ProDOS in terminal mode)
.halt:
    jmp .halt

; --- Data ---
banner_msg:
    !text "SECTORC65 V1.0", 0

done_msg:
    !text "DONE", 0

; --- Embedded test program ---
; Test div cache + combined features
test_source:
    !text "int q;", $0A
    !text "int r;", $0A
    !text "int n;", $0A
    !text "int d;", $0A
    !text "int e;", $0A
    !text "int f;", $0A
    !text "void main() {", $0A
    !text "  q = 1000 / 7;", $0A
    !text "  r = 1000 % 7;", $0A
    !text "  n = -42;", $0A
    !text "  d = 0;", $0A
    !text "  if (n < 0 && 1) { d = 1; }", $0A
    !text "  e = 0;", $0A
    !text "  if (q > 100 || r == 6) { e = 1; }", $0A
    !text "  f = (q * 7) + r;", $0A
    !text "}", $0A
    !byte 0  ; null terminator

; === Include Compiler Modules ===
!source "src/tokenizer.asm"
!source "src/symbols.asm"
!source "src/parser.asm"
!source "src/codegen.asm"
!source "src/error.asm"

; === Runtime Library (inline, no Language Card needed) ===
!source "src/runtime/math.asm"
!source "src/runtime/compare.asm"
!source "src/runtime/io.asm"

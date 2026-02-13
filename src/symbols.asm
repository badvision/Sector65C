; === SYMBOL TABLE ===
; Manages variables and functions

!source "src/include/zeropage.inc"
!source "src/include/memory.inc"

; Variable address allocator
var_next_addr:
    !word MEM_VARS

; Temporary storage for string operations
str_temp_ptr = ZP_TMP0  ; Points to string being processed
str_temp_idx = ZP_TMP0_H  ; Byte: current index in string

; --- sym_init ---
; Initialize symbol table
; Sets all entries to empty
sym_init:
    ; Clear symbol table memory ($A000-$BFFF = 8K for 256 entries)
    lda #<MEM_SYMTAB
    sta ZP_SYM_PTR
    lda #>MEM_SYMTAB
    sta ZP_SYM_PTR_H

    lda #0
    tay

sym_init_clear_page:
    ; Clear one page (256 bytes)
    lda #0            ; FIX: Reset A to 0 for clearing (gets corrupted by page check)
sym_init_clear_loop:
    sta (ZP_SYM_PTR),y
    iny
    bne sym_init_clear_loop

    ; Move to next page
    inc ZP_SYM_PTR_H
    lda ZP_SYM_PTR_H
    cmp #>(MEM_SYMTAB_END + 1)
    bcc sym_init_clear_page

    ; Reset variable address allocator
    lda #<MEM_VARS
    sta var_next_addr
    lda #>MEM_VARS
    sta var_next_addr+1

    rts

; --- compute_slot_address ---
; Helper: Compute symbol table slot address
; Input: A = slot number (0-255)
; Output: ZP_SYM_PTR = address of slot
compute_slot_address:
    ; Compute slot address: MEM_SYMTAB + (slot * 32)
    sta ZP_SYM_PTR_H  ; High byte temporarily holds slot
    lda #0
    sta ZP_SYM_PTR    ; Low byte = 0

    ; Shift right by 3 (slot * 256 / 8 = slot * 32)
    lsr ZP_SYM_PTR_H
    ror ZP_SYM_PTR
    lsr ZP_SYM_PTR_H
    ror ZP_SYM_PTR
    lsr ZP_SYM_PTR_H
    ror ZP_SYM_PTR

    ; Add base address $A000
    lda ZP_SYM_PTR
    clc
    adc #<MEM_SYMTAB
    sta ZP_SYM_PTR
    lda ZP_SYM_PTR_H
    adc #>MEM_SYMTAB
    sta ZP_SYM_PTR_H
    rts

; --- compare_strings ---
; Helper: Compare two strings
; Input: str_temp_ptr = pointer to string 1
;        ZP_SYM_PTR = pointer to symbol entry (string 2 at offset SYM_NAME_OFF)
; Output: Z flag set if equal, clear if different
compare_strings:
    ldy #SYM_NAME_OFF
    ldx #0
cmp_str_loop:
    ; Load char from string 1
    lda (str_temp_ptr),y
    sta ZP_TMP1  ; Save it
    ; Adjust Y for string 2 offset
    tya
    sec
    sbc #SYM_NAME_OFF
    tay
    ; Load char from string 1
    lda (str_temp_ptr),y
    ; Compare with string 2
    ldy #SYM_NAME_OFF
    cmp (ZP_SYM_PTR),y
    bne cmp_str_not_equal
    ; Check for null terminator
    cmp #0
    beq cmp_str_equal
    ; Next character
    inc str_temp_ptr
    bne cmp_str_no_carry
    inc str_temp_ptr+1
cmp_str_no_carry:
    iny
    cpy #(SYM_NAME_OFF + 28)
    bcc cmp_str_loop
cmp_str_not_equal:
    lda #1  ; Clear Z flag
    rts
cmp_str_equal:
    lda #0  ; Set Z flag
    rts

; --- sym_lookup ---
; Look up symbol by hash and name
; Input: ZP_TOKEN_VAL = hash value (low byte)
;        ZP_TMP0 = pointer to identifier string (will be preserved)
; Output: Carry set if found, ZP_SYM_PTR points to entry
;         Carry clear if not found
sym_lookup:
    ; Save string pointer (will be modified by compare_strings)
    lda ZP_TMP0
    pha
    lda ZP_TMP0_H
    pha

    ; Start at hash index
    lda ZP_TOKEN_VAL
    sta ZP_TMP1  ; Save starting slot

sym_lookup_compute_addr:
    lda ZP_TMP1  ; Current slot to check
    jsr compute_slot_address

sym_lookup_check_slot:
    ; Check if slot is empty
    ldy #SYM_HASH_OFF
    lda (ZP_SYM_PTR),y
    beq sym_lookup_not_found  ; Hash = 0 means empty slot

    ; Check if hash matches
    cmp ZP_TOKEN_VAL
    bne sym_lookup_next_slot

    ; Hash matches, compare name strings
    ; Restore string pointer
    pla
    sta str_temp_ptr+1
    pla
    sta str_temp_ptr
    pha
    lda str_temp_ptr+1
    pha

    ; Compare strings character by character
    ldy #SYM_NAME_OFF
    ldx #0
sym_lookup_cmp_loop:
    lda (str_temp_ptr,x)
    cmp (ZP_SYM_PTR),y
    bne sym_lookup_next_slot
    cmp #0
    beq sym_lookup_found
    ; Increment both pointers
    inc str_temp_ptr
    bne sym_lookup_no_carry
    inc str_temp_ptr+1
sym_lookup_no_carry:
    iny
    cpy #(SYM_NAME_OFF + 28)
    bcc sym_lookup_cmp_loop
    jmp sym_lookup_next_slot

sym_lookup_found:
    ; Clean up stack
    pla
    pla
    sec  ; Set carry = found
    rts

sym_lookup_next_slot:
    ; Linear probing: try next slot
    inc ZP_TMP1
    lda ZP_TMP1

    ; Check if we've wrapped around to starting slot
    cmp ZP_TOKEN_VAL
    beq sym_lookup_not_found

    jmp sym_lookup_compute_addr

sym_lookup_not_found:
    ; Clean up stack
    pla
    pla
    clc  ; Clear carry = not found
    rts

; --- sym_insert ---
; Insert new symbol
; Input: ZP_TOKEN_VAL = hash value (low byte)
;        A = symbol type (SYM_TYPE_VAR or SYM_TYPE_FUNC)
;        ZP_TMP0 = pointer to identifier string
;        ZP_TMP1 = address (for functions, ignored for variables)
; Output: Carry set if success, ZP_SYM_PTR points to new entry
;         Carry clear if table full
sym_insert:
    ; Save type and address on stack
    pha  ; Type
    lda ZP_TMP1
    pha  ; Address low
    lda ZP_TMP1_H
    pha  ; Address high

    ; Find empty slot using linear probing
    lda ZP_TOKEN_VAL
    sta ZP_TMP1  ; Current slot

sym_insert_find_slot:
    lda ZP_TMP1
    jsr compute_slot_address

    ; Check if slot is empty
    ldy #SYM_HASH_OFF
    lda (ZP_SYM_PTR),y
    beq sym_insert_found_empty_slot

    ; Try next slot
    inc ZP_TMP1
    lda ZP_TMP1

    ; Check if we've wrapped around
    cmp ZP_TOKEN_VAL
    beq sym_insert_table_full

    jmp sym_insert_find_slot

sym_insert_table_full:
    ; Clean up stack
    pla
    pla
    pla
    clc  ; Clear carry = failure
    rts

sym_insert_found_empty_slot:
    ; Write hash
    ldy #SYM_HASH_OFF
    lda ZP_TOKEN_VAL
    sta (ZP_SYM_PTR),y

    ; Restore and write type
    pla  ; Address high
    sta ZP_TMP1_H
    pla  ; Address low
    sta ZP_TMP1
    pla  ; Type
    pha  ; Save again
    ldy #SYM_TYPE_OFF
    sta (ZP_SYM_PTR),y

    ; Check type for address assignment
    cmp #SYM_TYPE_VAR
    beq sym_insert_auto_assign_addr

    ; Function: use provided address from ZP_TMP1
    ldy #SYM_ADDR_OFF
    lda ZP_TMP1
    sta (ZP_SYM_PTR),y
    iny
    lda ZP_TMP1_H
    sta (ZP_SYM_PTR),y
    jmp sym_insert_write_name

sym_insert_auto_assign_addr:
    ; Variable: auto-assign from var_next_addr
    ldy #SYM_ADDR_OFF
    lda var_next_addr
    sta (ZP_SYM_PTR),y
    iny
    lda var_next_addr+1
    sta (ZP_SYM_PTR),y

    ; Increment var_next_addr by 2
    lda var_next_addr
    clc
    adc #2
    sta var_next_addr
    bcc sym_insert_write_name
    inc var_next_addr+1

sym_insert_write_name:
    ; Copy name string from ZP_TMP0
    ldy #SYM_NAME_OFF
    ldx #0
sym_insert_copy_loop:
    lda (ZP_TMP0,x)
    sta (ZP_SYM_PTR),y
    beq sym_insert_done  ; Null terminator copied
    inc ZP_TMP0
    bne sym_insert_no_carry
    inc ZP_TMP0_H
sym_insert_no_carry:
    iny
    cpy #(SYM_NAME_OFF + 28)
    bcc sym_insert_copy_loop

    ; Ensure null termination if name was truncated
    ldy #(SYM_NAME_OFF + 27)
    lda #0
    sta (ZP_SYM_PTR),y

sym_insert_done:
    pla  ; Clean up type from stack
    sec  ; Set carry = success
    rts

; --- sym_get_addr ---
; Get address of symbol
; Input: ZP_SYM_PTR points to entry
; Output: R0 = address (16-bit)
sym_get_addr:
    ldy #SYM_ADDR_OFF
    lda (ZP_SYM_PTR),y
    sta R0
    iny
    lda (ZP_SYM_PTR),y
    sta R0_H
    rts

; --- sym_get_address ---
; Get address of symbol (alternate interface)
; Input: ZP_SYM_PTR points to entry
; Output: A = address low, X = address high
sym_get_address:
    ldy #SYM_ADDR_OFF
    lda (ZP_SYM_PTR),y
    tax
    iny
    lda (ZP_SYM_PTR),y
    rts

; --- sym_get_type ---
; Get type of symbol
; Input: ZP_SYM_PTR points to entry
; Output: A = type (SYM_TYPE_VAR or SYM_TYPE_FUNC)
sym_get_type:
    ldy #SYM_TYPE_OFF
    lda (ZP_SYM_PTR),y
    rts

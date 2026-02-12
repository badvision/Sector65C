; === RUNTIME I/O LIBRARY ===
; Character and file I/O

; --- PUTCHAR ---
; Print single character to console
; Input: A = character to print
!zone putchar {
PUTCHAR:
    jsr COUT
    rts
}

; --- PUTNUM ---
; Print 16-bit unsigned number in decimal
; Input: R0 = 16-bit number
!zone putnum {
PUTNUM:
    ; Simple implementation: print in decimal
    ; For now, just print hex (easier for testing)
    lda R0_H
    jsr .print_hex8
    lda R0
    jsr .print_hex8
    rts

.print_hex8:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr .print_hex_digit
    pla
    and #$0F
    jsr .print_hex_digit
    rts

.print_hex_digit:
    cmp #10
    bcc .digit
    sbc #9
    ora #'@'
    jsr COUT
    rts
.digit:
    ora #'0'
    jsr COUT
    rts
}

; --- prodos_open ---
; Open file via ProDOS MLI
; Input: IOPTR points to filename
; Output: A = file reference number, or error code
!zone prodos_open {
prodos_open:
    ; TODO: Set up MLI parameter block
    ; TODO: Call ProDOS MLI
    ; TODO: Return result
    rts
}

; --- prodos_read ---
; Read from file
; Input: A = file reference
;        IOPTR = buffer address
;        R0 = bytes to read
; Output: R0 = bytes actually read
!zone prodos_read {
prodos_read:
    ; TODO: Set up MLI parameter block
    ; TODO: Call ProDOS MLI
    ; TODO: Return result
    rts
}

; --- prodos_write ---
; Write to file
; Input: A = file reference
;        IOPTR = buffer address
;        R0 = bytes to write
; Output: R0 = bytes actually written
!zone prodos_write {
prodos_write:
    ; TODO: Set up MLI parameter block
    ; TODO: Call ProDOS MLI
    ; TODO: Return result
    rts
}

; --- prodos_close ---
; Close file
; Input: A = file reference
!zone prodos_close {
prodos_close:
    ; TODO: Set up MLI parameter block
    ; TODO: Call ProDOS MLI
    rts
}

; --- print_string ---
; Print null-terminated string to console
; Input: IOPTR points to string
!zone print_string {
print_string:
    ldy #0
.loop:
    lda (IOPTR),y
    beq .done
    jsr COUT
    iny
    bne .loop
.done:
    rts
}

; --- print_hex16 ---
; Print 16-bit value in hex
; Input: R0 = value
!zone print_hex16 {
print_hex16:
    ; TODO: Print high byte then low byte in hex
    lda R0_H
    jsr print_hex8
    lda R0
    jsr print_hex8
    rts
}

; --- print_hex8 ---
; Print 8-bit value in hex
; Input: A = value
!zone print_hex8 {
print_hex8:
    ; TODO: Print two hex digits
    pha
    lsr
    lsr
    lsr
    lsr
    jsr print_hex_digit
    pla
    and #$0F
    jsr print_hex_digit
    rts
}

; --- print_hex_digit ---
; Print single hex digit
; Input: A = digit (0-15)
!zone print_hex_digit {
print_hex_digit:
    cmp #10
    bcc .digit
    ; A-F
    sbc #9
    ora #'@'
    jsr COUT
    rts
.digit:
    ; 0-9
    ora #'0'
    jsr COUT
    rts
}

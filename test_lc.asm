; Test Language Card initialization for JACE
; This minimal test verifies LC switches work correctly

!cpu 65c02

* = $4000

start:
    ; Clear screen
    jsr $FC58

    ; Print "TESTING LC..."
    ldx #0
.print_msg:
    lda msg,x
    beq .msg_done
    ora #$80
    sta $0400,x
    inx
    jmp .print_msg
.msg_done:

    ; Test Language Card Bank 1 read/write enable
    ; $C08B should enable both read and write after 2 reads

    ; First, verify ROM is visible at $D000 (should be $4C or similar)
    lda $D000
    sta test_rom_value

    ; Now enable LC RAM bank 1 (read+write)
    lda $C08B          ; First read - enables read
    lda $C08B          ; Second read - enables write

    ; Try to write a test value to $D000
    lda #$42
    sta $D000

    ; Read it back
    lda $D000
    sta test_lc_value

    ; Display results
    ldx #20
    lda test_rom_value
    jsr display_hex

    ldx #40
    lda test_lc_value
    jsr display_hex

    ; Success message if LC value = $42
    lda test_lc_value
    cmp #$42
    beq .success

    ; Failure
    ldx #60
    lda #'F'
    ora #$80
    sta $0400,x
    lda #'A'
    ora #$80
    sta $0401,x
    lda #'I'
    ora #$80
    sta $0402,x
    lda #'L'
    ora #$80
    sta $0403,x
    jmp .hang

.success:
    ldx #60
    lda #'O'
    ora #$80
    sta $0400,x
    lda #'K'
    ora #$80
    sta $0401,x

.hang:
    jmp .hang

; Display byte in A as hex at screen position X
display_hex:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr .display_digit
    inx
    pla
    and #$0F
    jsr .display_digit
    rts

.display_digit:
    cmp #10
    bcc .is_digit
    sbc #9
    ora #$C0    ; 'A'-'F'
    sta $0400,x
    rts
.is_digit:
    ora #$B0    ; '0'-'9'
    sta $0400,x
    rts

msg:
    !text "TESTING LC...",0

test_rom_value:
    !byte 0
test_lc_value:
    !byte 0

; Minimal Language Card test
; Tests that we can enable LC and write/read from it

!cpu 65c02

* = $4000

start:
    ; Write message directly to screen (no ROM calls)
    ldx #0
.msg_loop:
    lda msg,x
    beq .msg_done
    ora #$80         ; Set high bit for normal text
    sta $0400,x
    inx
    cpx #10
    bne .msg_loop
.msg_done:

    ; Enable Language Card Bank 1 (read+write)
    ; $C08B must be READ twice
    lda $C08B          ; First read: enable read
    lda $C08B          ; Second read: enable write

    ; Write test pattern to $D000
    lda #$42
    sta $D000
    lda #$43
    sta $D001
    lda #$44
    sta $D002

    ; Read back and verify
    lda $D000
    cmp #$42
    bne .fail

    lda $D001
    cmp #$43
    bne .fail

    lda $D002
    cmp #$44
    bne .fail

.success:
    ; Write "OK" at position 15
    lda #'O' | $80
    sta $040F
    lda #'K' | $80
    sta $0410
    jmp .done

.fail:
    ; Write "FAIL" at position 15
    lda #'F' | $80
    sta $040F
    lda #'A' | $80
    sta $0410
    lda #'I' | $80
    sta $0411
    lda #'L' | $80
    sta $0412

.done:
    ; Hang (don't RTS back to ROM)
.hang:
    jmp .hang

msg:
    !text "LC TEST..."

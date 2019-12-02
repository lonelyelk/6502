  .org $8000

reset:
  lda #$ff
  sta $6003
  sta $6002

loop:
  lda #$00
  ldx #$02
  jsr print

  ldx #$38
  jsr print

  ldx #$0f
  jsr print

  ldx #$06
  jsr print

  lda #$20
  ldx #$53
  jsr print

  ldx #$65
  jsr print

  ldx #$72
  jsr print

  ldx #$67
  jsr print

  ldx #$65
  jsr print

  ldx #$79
  jsr print

  jmp loop

print:
  sta $600f
  pha
  ora #$80
  sta $600f
  stx $6000
  pla
  sta $600f
  rts

  .org $fffc
  .word reset
  .word $0000
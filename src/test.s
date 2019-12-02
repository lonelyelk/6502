  .org $8000

reset:
  lda #$ff
  sta $6000

loop:
  lda #$ff
  sta $6000
  jmp loop

  .org $fffc
  .word reset
  .word $0000
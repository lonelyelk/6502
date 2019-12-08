  .org $8000

reset:
  lda #$e1
  sta $6003
  lda #$ff
  sta $6002

  lda $600f
  sta $00
  lda #$02
  sta $01
  lda #$04
  sta $02
  lda #$08
  sta $03
  lda #$10
  sta $04

loop:
  lda #$00
  ldx #$02
  jsr print

  ldx #$38
  jsr print

  ldx #$0c
  jsr print

  ldx #$06
  jsr print

  lda #$20
  ldx #$24
  jsr print

  ldx #$3e
  jsr print

  lda $600f
  cmp $00
  bne type
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

type:
  bit $01
  beq led
  jmp loop

led:
  lda #$01
  sta $600f
  jmp loop

  .org $fffc
  .word reset
  .word $0000
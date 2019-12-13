rwa .equ $600f
rwb .equ $6000
btnstate .equ $3000

  .org $8000

reset:
  lda #$e1
  sta $6003
  lda #$ff
  sta $6002

  lda rwa
  sta btnstate

loop:
  lda #$02
  jsr lcddir

  lda #$38
  jsr lcddir

  lda #$0c
  jsr lcddir

  lda #$06
  jsr lcddir

  lda #$24
  jsr lcdprnt

  lda #$3e
  jsr lcdprnt

  lda rwa
  cmp btnstate
  bne type
  jmp loop

lcddir:
  pha
  pha
  lda lcdsys
  sta rwa
  ora lcde
  sta rwa
  pla
  sta rwb
  lda lcdsys
  sta rwa
  pla
  rts

lcdprnt:
  pha
  pha
  lda lcdtxt
  sta rwa
  ora lcde
  sta rwa
  pla
  sta rwb
  lda lcdtxt
  sta rwa
  pla
  rts

type:
  bit btnup
  beq led
  bit btndown
  beq led
  bit btnleft
  beq led
  bit btnright
  beq led
  jmp loop

led:
  lda #$01
  sta rwa
  jmp loop

lcdsys:
  .byte $00
lcdtxt:
  .byte $20
lcde:
  .byte $80

btnup:
  .byte $02
btndown:
  .byte $04
btnleft:
  .byte $08
btnright:
  .byte $10

  .org $fffc
  .word reset
  .word $0000
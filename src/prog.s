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

  lda #$ff
  jsr waitms
  lda #$38
  jsr lcddir
  lda #$ff
  jsr waitms
  lda #$38
  jsr lcddir
  lda #$ff
  jsr waitms
  lda #$38
  jsr lcddir
  lda #$ff
  jsr waitms

  lda #$0f
  jsr lcddir
  jsr lcdbusy
  lda #$02
  jsr lcddir
  jsr lcdbusy
  lda #$06
  jsr lcddir
  jsr lcdbusy

  lda #$24
  jsr lcdprnt
  jsr lcdbusy

  lda #$3e
  jsr lcdprnt
  jsr lcdbusy

loop:
  lda rwa
  cmp btnstate
  beq loop
  sta btnstate
  bit btnup
  bne nobtn
  lda #$55
  jsr lcdprnt
  jsr lcdbusy
  lda #$01
  sta rwa
  jmp loop
nobtn:
  lda #$00
  sta rwa
  jmp loop

waitms:
  tay
waitloop0:
  ldx #$ff
waitloop1:
  dex
  bne waitloop1
  dey
  bne waitloop0
  rts

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

lcdbusy:
  pha
  lda #$7f
  sta $6002
lcdbusyloop0:
  lda lcdrw
  sta rwa
  ora lcde
  sta rwa
  lda rwb
  and #$80
  bne lcdbusyloop0
  lda #$ff
  sta $6002
  pla
  rts

lcdsys:
  .byte $00
lcdtxt:
  .byte $20
lcde:
  .byte $80
lcdrw:
  .byte $40

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
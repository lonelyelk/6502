rwa .equ $600f
rwb .equ $6000
btnstate .equ $3000

  .org $8000

reset:
  lda #$e1
  sta $6003
  lda #$ff
  sta $6002

  lda #$0f
  jsr waitms
  lda #$38
  jsr lcddir
  lda #$05
  jsr waitms
  lda #$38
  jsr lcddir
  lda #$01
  jsr waitms
  lda #$38
  jsr lcddir
  lda #$01
  jsr waitms

  lda #$01
  jsr lcddir
  lda #$01
  jsr waitms
  jsr lcdbusy
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

  lda #$3e
  jsr lcdprnt

  lda rwa
  and btnmask
  sta btnstate

loop:
  lda rwa
  and btnmask
  cmp btnstate
  beq loop
  sta btnstate
  lda #$09
  jsr waitms
  lda rwa
  and btnmask
  cmp btnstate
  bne loop
  bit btnup
  bne noupbtn
  lda #$55
  jsr lcdprnt
  lda #$01
  sta rwa
  jmp loop
noupbtn:
  bit btndown
  bne nodownbtn
  lda #$44
  jsr lcdprnt
  lda #$01
  sta rwa
  jmp loop
nodownbtn:
  bit btnleft
  bne noleftbtn
  lda #$4c
  jsr lcdprnt
  lda #$01
  sta rwa
  jmp loop
noleftbtn:
  bit btnright
  bne norightbtn
  lda #$52
  jsr lcdprnt
  lda #$01
  sta rwa
  jmp loop
norightbtn:
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
  jsr lcdbusy
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
btnmask:
  .byte $1e

  .org $fffc
  .word reset
  .word $0000
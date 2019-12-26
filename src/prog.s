via_data_a .equ $600f
via_data_b .equ $6000
via_dir_a .equ $6003
via_dir_b .equ $6002
btnstate .equ $3000

  .org $8000

reset:
  lda #%11100001 ; LCD control (E, RW, RS) and LED
  sta via_dir_a
  lda #%11111111 ; LCD data
  sta via_dir_b

  lda #$0f
  jsr waitms
  lda #%00111000 ; 8 bit; 2 lines; 5x8 dots
  jsr lcddir
  lda #$05
  jsr waitms
  lda #%00111000 ; repeat 3 times
  jsr lcddir
  lda #$01
  jsr waitms
  lda #%00111000
  jsr lcddir
  lda #$01
  jsr waitms

  lda #%00000001 ; clear display
  jsr lcddir
  lda #$01
  jsr waitms
  jsr lcdbusy
  lda #%00001111 ; display on; cursor on; blink on
  jsr lcddir
  jsr lcdbusy
  lda #%00000010 ; lcd home
  jsr lcddir
  jsr lcdbusy
  lda #%00000110 ; increment address; no shift display
  jsr lcddir
  jsr lcdbusy

  lda #"$"
  jsr lcdprnt

  lda #">"
  jsr lcdprnt

  lda via_data_a
  and btnmask
  sta btnstate

loop:
  lda via_data_a
  and btnmask
  cmp btnstate
  beq loop
  sta btnstate
  lda #$09
  jsr waitms
  lda via_data_a
  and btnmask
  cmp btnstate
  bne loop
  bit btnup
  bne noupbtn
  lda #"u"
  jsr lcdprnt
  lda #$01
  sta via_data_a
  jmp loop
noupbtn:
  bit btndown
  bne nodownbtn
  lda #"d"
  jsr lcdprnt
  lda #$01
  sta via_data_a
  jmp loop
nodownbtn:
  bit btnleft
  bne noleftbtn
  lda #"l"
  jsr lcdprnt
  lda #$01
  sta via_data_a
  jmp loop
noleftbtn:
  bit btnright
  bne norightbtn
  lda #"r"
  jsr lcdprnt
  lda #$01
  sta via_data_a
  jmp loop
norightbtn:
  lda #$00
  sta via_data_a
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
  sta via_data_a
  ora lcde
  sta via_data_a
  pla
  sta via_data_b
  lda lcdsys
  sta via_data_a
  pla
  rts

lcdprnt:
  pha
  pha
  lda lcdtxt
  sta via_data_a
  ora lcde
  sta via_data_a
  pla
  sta via_data_b
  lda lcdtxt
  sta via_data_a
  jsr lcdbusy
  pla
  rts

lcdbusy:
  pha
  lda #%01111111
  sta via_dir_b
lcdbusyloop0:
  lda lcdrw
  sta via_data_a
  ora lcde
  sta via_data_a
  lda via_data_b
  and lcdbusyflag
  bne lcdbusyloop0
  lda #%11111111
  sta via_dir_b
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
lcdbusyflag:
  .byte $80

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
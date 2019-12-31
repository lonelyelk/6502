via_data_a .equ $600f
via_data_b .equ $6000
via_dir_a .equ $6003
via_dir_b .equ $6002
via_sr .equ $600a
via_acr .equ $600b
via_pcr .equ $600c
via_ifr .equ $600d
via_ier .equ $600e
acia_data .equ $7000
acia_stat .equ $7001
acia_comm .equ $7002
acia_ctrl .equ $7003

btn_state_cache .equ $3000
lcd_address_counter .equ $3001

  .org $8000

reset:
  lda #%11100001 ; LCD control (E, RW, RS) and LED
  sta via_dir_a
  lda #%11111111 ; LCD data
  sta via_dir_b
  lda via_sr ; VIA reset shift register
  lda via_ier
  ora #%00000100 ; VIA enable shift register interrupt
  sta via_ier
  lda via_acr
  ora #%00011000
  and #%11111011 ; VIA shift register mode 110
  sta via_acr

  lda #$0f
  jsr waitms
  lda #%00111000 ; LCD: 8 bit; 2 lines; 5x8 dots
  jsr lcddir
  lda #$05
  jsr waitms
  lda #%00111000 ; LCD: repeat 3 times
  jsr lcddir
  lda #$01
  jsr waitms
  lda #%00111000
  jsr lcddir
  lda #$01
  jsr waitms

  lda #%00000001 ; LCD: clear display
  jsr lcddir
  lda #$01
  jsr waitms
  jsr lcdbusy
  lda #%00001111 ; LCD: display on; cursor on; blink on
  jsr lcddir
  jsr lcdbusy
  lda #%00000010 ; LCD: home
  jsr lcddir
  jsr lcdbusy
  lda #%00000110 ; LCD: increment address; no shift display
  jsr lcddir
  jsr lcdbusy

  lda #"$"
  jsr lcdprnt

  lda #">"
  jsr lcdprnt

  ;;lda #$00
  ;;sta acia_stat
  ;;lda #%00000000 ; ACIA: 1 stop bit; 8 bit words; 16x /(- 9600 baud rate)
  ;;sta acia_ctrl
  ;;lda #%11001111 ; ACIA: no parity; no echo; no irq
  ;;sta acia_comm

  lda via_data_a
  and btnmask
  sta btn_state_cache

loop:
  lda via_data_a
  and btnmask
  cmp btn_state_cache
  beq loop
  sta btn_state_cache
  lda #$09
  jsr waitms
  lda via_data_a
  and btnmask
  cmp btn_state_cache
  bne loop
  bit btnup
  bne noupbtn
  lda #"u"
  ;;sta acia_data
  jsr lcdprnt
  sta via_sr
  ;;lda acia_data
  ;;jsr lcdprntbin
  jmp loop
noupbtn:
  bit btndown
  bne nodownbtn
  lda #"d"
  ;;sta acia_data
  jsr lcdprnt
  sta via_sr
  wai
  lda #$01
  sta via_data_a
  ;;lda acia_stat
  ;;jsr lcdprntbin
  jmp loop
nodownbtn:
  bit btnleft
  bne noleftbtn
  lda #"l"
  ;;sta acia_data
  jsr lcdprnt
  sta via_sr
  ;;lda acia_comm
  ;;jsr lcdprntbin
  jmp loop
noleftbtn:
  bit btnright
  bne norightbtn
  lda #"r"
  ;;sta acia_data
  jsr lcdprnt
  sta via_sr
  ;;lda acia_ctrl
  ;;jsr lcdprntbin
  jmp loop
norightbtn:
  lda #$00
  sta via_data_a
  jmp loop

lcdprntbin:
  pha
  ldx #$08
shiftloop:
  asl
  bcc printzero
  pha
  lda #"1"
  jsr lcdprnt
  pla
  jmp shiftloop0
printzero:
  pha
  lda #"0"
  jsr lcdprnt
  pla
shiftloop0:
  dex
  bne shiftloop
  pla
  rts

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
  lda #%00000000 ; LCD allow read from all pins
  sta via_dir_b
lcdbusyloop0:
  lda lcdrw
  sta via_data_a
  ora lcde
  sta via_data_a
  lda via_data_b
  and lcdbusyflag
  bne lcdbusyloop0
  lda via_data_b
  sta lcd_address_counter
  lda #%11111111 ; LCD make all write only
  sta via_dir_b
  lda lcd_address_counter
  cmp lcdline12
  beq lcdchangeline12
  cmp lcdline23
  beq lcdchangeline23
  cmp lcdline2
  beq lcdchangeline2
  jmp lcdreturn
lcdchangeline12:
  lda lcdline2
  sta lcd_address_counter
  ora lcdbusyflag
  jsr lcddir
  jmp lcdreturn
lcdchangeline23:
  lda lcdline12
  sta lcd_address_counter
  ora lcdbusyflag
  jsr lcddir
  jmp lcdreturn
lcdchangeline2:
  lda lcdline23
  sta lcd_address_counter
  ora lcdbusyflag
  jsr lcddir
  jmp lcdreturn
lcdreturn:
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
lcdline12:
  .byte $14
lcdline2:
  .byte $40
lcdline23:
  .byte $54

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

isr:
  pha
  lda via_ifr
  lda #"i"
  jsr lcdprnt
  lda #$01
  sta via_data_a
  pla
  rti

  .org $fffc
  .word reset
  .word isr
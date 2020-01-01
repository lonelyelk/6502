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

lcd_control_rs .equ $20
lcd_control_e .equ $80
lcd_control_rw .equ $40
lcd_busy_flag .equ $80
lcd_ddram .equ $80
lcd_cgram .equ $40
lcd_address_line1_middle .equ $14
lcd_address_line2_start .equ $40
lcd_address_line2_middle .equ $54
lcd_char_height .equ $08
lcd_chars_number .equ $08

btn_mask .equ $1e

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
  lda #%00000110 ; LCD: increment address; no shift display
  jsr lcddir
  jsr lcdbusy

  lda #lcd_cgram ; LCD: set address counter to CGRAM 00
  jsr lcddir
  jsr lcdbusy
  lda #lcd_chars_number
  ldx #0
setupcharsloop:
  ldy #lcd_char_height
  pha
setupcharloop:
  lda lcdchars, X
  jsr lcdprnt
  inx
  dey
  bne setupcharloop
  pla
  dec
  bne setupcharsloop

  lda #lcd_ddram ; LCD: set address counter to DDRAM 00
  jsr lcddir
  jsr lcdbusy

  lda #%00000010 ; LCD: home
  jsr lcddir
  jsr lcdbusy

  lda #0
  ldx #lcd_chars_number
printcharsloop:
  jsr lcdprnt
  jsr lcdlinesfix
  inc
  dex
  bne printcharsloop

  lda #">"
  jsr lcdprnt
  jsr lcdlinesfix

  ;;lda #$00
  ;;sta acia_stat
  ;;lda #%00000000 ; ACIA: 1 stop bit; 8 bit words; 16x /(- 9600 baud rate)
  ;;sta acia_ctrl
  ;;lda #%11001111 ; ACIA: no parity; no echo; no irq
  ;;sta acia_comm

  lda via_data_a
  and #btn_mask
  sta btn_state_cache

loop:
  lda via_data_a
  and #btn_mask
  cmp btn_state_cache
  beq loop
  sta btn_state_cache
  lda #$09
  jsr waitms
  lda via_data_a
  and #btn_mask
  cmp btn_state_cache
  bne loop
  bit btnup
  bne noupbtn
  lda #"u"
  ;;sta acia_data
  jsr lcdprnt
  jsr lcdlinesfix
  sta via_sr
  wai
  lda #$01
  sta via_data_a
  ;;lda acia_data
  ;;jsr lcdprntbin
  jmp loop
noupbtn:
  bit btndown
  bne nodownbtn
  lda #"d"
  ;;sta acia_data
  jsr lcdprnt
  jsr lcdlinesfix
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
  jsr lcdlinesfix
  sta via_sr
  wai
  lda #$01
  sta via_data_a
  ;;lda acia_comm
  ;;jsr lcdprntbin
  jmp loop
noleftbtn:
  bit btnright
  bne norightbtn
  lda #"r"
  ;;sta acia_data
  jsr lcdprnt
  jsr lcdlinesfix
  sta via_sr
  wai
  lda #$01
  sta via_data_a
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
  jsr lcdlinesfix
  pla
  jmp shiftloop0
printzero:
  pha
  lda #"0"
  jsr lcdprnt
  jsr lcdlinesfix
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
  lda #0
  sta via_data_a
  ora #lcd_control_e
  sta via_data_a
  pla
  sta via_data_b
  lda #0
  sta via_data_a
  pla
  rts

lcdprnt:
  pha
  pha
  lda #lcd_control_rs
  sta via_data_a
  ora #lcd_control_e
  sta via_data_a
  pla
  sta via_data_b
  lda #lcd_control_rs
  sta via_data_a
  jsr lcdbusy
  pla
  rts

lcdbusy:
  pha
  lda #%00000000 ; LCD allow read from all pins
  sta via_dir_b
lcdbusyloop0:
  lda #lcd_control_rw
  sta via_data_a
  ora #lcd_control_e
  sta via_data_a
  lda via_data_b
  and #lcd_busy_flag
  bne lcdbusyloop0
  lda via_data_b
  sta lcd_address_counter
  lda #%11111111 ; LCD make all write only
  sta via_dir_b
  pla
  rts

lcdlinesfix:
  pha
  lda lcd_address_counter
  cmp #lcd_address_line1_middle
  beq lcdchangeline12
  cmp #lcd_address_line2_middle
  beq lcdchangeline23
  cmp #lcd_address_line2_start
  beq lcdchangeline2
  jmp lcdreturn
lcdchangeline12:
  lda #lcd_address_line2_start
  sta lcd_address_counter
  ora #lcd_ddram
  jsr lcddir
  jmp lcdreturn
lcdchangeline23:
  lda #lcd_address_line1_middle
  sta lcd_address_counter
  ora #lcd_ddram
  jsr lcddir
  jmp lcdreturn
lcdchangeline2:
  lda #lcd_address_line2_middle
  sta lcd_address_counter
  ora #lcd_ddram
  jsr lcddir
  jmp lcdreturn
lcdreturn:
  pla
  rts

lcdchars:
  .byte %10100 ;; elk
  .byte %10100
  .byte %01000
  .byte %10111
  .byte %00101
  .byte %00101
  .byte %00101
  .byte %00101
  .byte %01110 ;; ktulhu
  .byte %11111
  .byte %10101
  .byte %11111
  .byte %11111
  .byte %11111
  .byte %10101
  .byte %10101
  .byte %00100 ;; penis
  .byte %01010
  .byte %01110
  .byte %01010
  .byte %01010
  .byte %10101
  .byte %10101
  .byte %01110
  .byte %01110 ;; vagina
  .byte %10001
  .byte %10101
  .byte %10101
  .byte %10101
  .byte %10101
  .byte %10101
  .byte %01110
  .byte %10001 ;; lion
  .byte %11111
  .byte %10001
  .byte %11011
  .byte %10001
  .byte %10101
  .byte %01110
  .byte %00000
  .byte %10001 ;; cat
  .byte %11111
  .byte %10001
  .byte %11011
  .byte %10001
  .byte %01110
  .byte %00000
  .byte %00000
  .byte %11000 ;; goose
  .byte %10100
  .byte %11110
  .byte %10000
  .byte %10001
  .byte %11111
  .byte %10001
  .byte %01110
  .byte %10101 ;; babaka
  .byte %01110
  .byte %00100
  .byte %01110
  .byte %10001
  .byte %11111
  .byte %01001
  .byte %11011

btnup:
  .byte $02
btndown:
  .byte $04
btnleft:
  .byte $08
btnright:
  .byte $10

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
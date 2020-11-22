via_data_a .equ $600f
via_data_b .equ $6000
via_dir_a .equ $6003
via_dir_b .equ $6002
via_sr .equ $600a
via_acr .equ $600b
via_pcr .equ $600c
via_ifr .equ $600d
via_ier .equ $600e

via_lcd_write .equ %11111110 ; LCD data (4 most significant bits) E, RW, RS
via_lcd_read .equ %00001110

btn_state_cache .equ $3000
btn_state .equ $3001
lcd_address_counter .equ $3010

lcd_control_rs .equ $02
lcd_control_rw .equ $04
lcd_control_e .equ $08
lcd_busy_flag .equ $80
lcd_ddram .equ $80
lcd_cgram .equ $40
lcd_address_line1_middle .equ $14
lcd_address_line2_start .equ $40
lcd_address_line2_middle .equ $54
lcd_char_height .equ $08
lcd_chars_number .equ $08

btn_mask .equ $1e

btn_0 .equ %00101000
btn_1 .equ %00010001
btn_2 .equ %00100001
btn_3 .equ %01000001
btn_4 .equ %00010010
btn_5 .equ %00100010
btn_6 .equ %01000010
btn_7 .equ %00010100
btn_8 .equ %00100100
btn_9 .equ %01000100
btn_a .equ %10000001
btn_b .equ %10000010
btn_c .equ %10000100
btn_d .equ %10001000
btn_star .equ %00011000
btn_hash .equ %01001000

  .org $8000

reset:
  lda #%00001111 ; BTN: horizontals are high, reading verticals
  sta via_dir_a
  sta via_data_a

  jsr serialsetup
  jsr lcdsetup

  lda #0
  ldx #lcd_chars_number
printcharsloop:
  jsr lcdprint
  inc
  dex
  bne printcharsloop

  lda #">"
  jsr lcdprint

  lda via_data_a
  and #btn_mask
  sta btn_state_cache

loop:
  lda via_dir_a
  and #%11110000
  beq loopcont
  lda #%00001111
  sta via_dir_a
  sta via_data_a
loopcont:
  lda via_data_a
  and #%11110000
  beq loop
  sta btn_state
  lda #%11110000 
  sta via_dir_a
  sta via_data_a
  lda via_data_a
  and #%00001111
  beq loop
  ora btn_state
  cmp btn_state_cache
  beq loop
  sta btn_state_cache
  lda #$09
  jsr waitms
  lda via_data_a
  and #%00001111
  beq loop
  sta btn_state
  lda #%00001111 
  sta via_dir_a
  sta via_data_a
  lda via_data_a
  and #%11110000
  beq loop
  ora btn_state
  cmp btn_state_cache
  bne loop
  cmp #btn_0
  beq pressbtn0
  cmp #btn_1
  beq pressbtn1
  cmp #btn_2
  beq pressbtn2
  cmp #btn_3
  beq pressbtn3
  cmp #btn_4
  beq pressbtn4
  cmp #btn_5
  beq pressbtn5
  cmp #btn_6
  beq pressbtn6
  cmp #btn_7
  beq pressbtn7
  cmp #btn_8
  beq pressbtn8
  cmp #btn_9
  beq pressbtn9
  cmp #btn_a
  beq pressbtna
  cmp #btn_b
  beq pressbtnb
  cmp #btn_c
  beq pressbtnc
  cmp #btn_d
  beq pressbtnd
  cmp #btn_star
  beq pressbtnstar
  cmp #btn_hash
  beq pressbtnhash
  jmp loop
pressbtn0:
  lda #"0"
  jmp loopcont1
pressbtn1:
  lda #"1"
  jmp loopcont1
pressbtn2:
  lda #"2"
  jmp loopcont1
pressbtn3:
  lda #"3"
  jmp loopcont1
pressbtn4:
  lda #"4"
  jmp loopcont1
pressbtn5:
  lda #"5"
  jmp loopcont1
pressbtn6:
  lda #"6"
  jmp loopcont1
pressbtn7:
  lda #"7"
  jmp loopcont1
pressbtn8:
  lda #"8"
  jmp loopcont1
pressbtn9:
  lda #"9"
  jmp loopcont1
pressbtna:
  lda #"a"
  jmp loopcont1
pressbtnb:
  lda #"b"
  jmp loopcont1
pressbtnc:
  lda #"c"
  jmp loopcont1
pressbtnd:
  lda #"d"
  jmp loopcont1
pressbtnstar:
  lda #"*"
  jmp loopcont1
pressbtnhash:
  lda #"#"
loopcont1:
  jsr lcdprint
  jsr serialoutput
  ;;jsr ledhigh
  ;;jsr lcdprintbinary
  jmp loop

ledhigh:
  pha
  lda via_data_a
  ora #1
  sta via_data_a
  pla
  rts

ledlow:
  pha
  lda via_data_a
  and #%11111110
  sta via_data_a
  pla
  rts

serialsetup:
  pha
  lda via_sr ; VIA reset shift register
  lda via_ier
  ora #%00000100 ; VIA enable shift register interrupt
  sta via_ier
  lda via_acr
  ora #%00011000
  and #%11111011 ; VIA shift register mode 110
  sta via_acr
  lda #%1100 ; VIA control CA2 low
  sta via_pcr
  lda #%1110 ; VIA control CA2 high
  sta via_pcr
  lda #%1100 ; VIA control CA2 low
  sta via_pcr
  pla
  rts

serialoutput:
  sta via_sr
  wai
  pha
  lda #%1110
  sta via_pcr
  lda #%1100
  sta via_pcr
  pla
  rts

lcdprintbinary:
  pha
  ldx #$08
shiftloop:
  asl
  bcc printzero
  pha
  lda #"1"
  jsr lcdprint
  pla
  jmp shiftloop0
printzero:
  pha
  lda #"0"
  jsr lcdprint
  pla
shiftloop0:
  dex
  bne shiftloop
  pla
  rts

lcdsetup:
  pha
  lda #via_lcd_write ; LCD data (4 most significant bits) E, RW, RS
  sta via_dir_b

  lda #$0f ;; wait ~15 ms after powerup
  jsr waitms
  lda #%00111000 ; LCD: 8 bit; 2 lines; 5x8 dots
  jsr lcdcommand8
  lda #$05
  jsr waitms
  lda #%00111000 ; LCD: repeat 3 times
  jsr lcdcommand8
  lda #$01
  jsr waitms
  lda #%00111000 ; LCD: repeat 3 times
  jsr lcdcommand8
  lda #$01
  jsr waitms
  lda #%00101000 ; LCD: 4 bit; 2 lines; 5x8 dots
  jsr lcdcommandbusy8 ; use 8 bit subroutine since it's in 8 bit mode still
  lda #%00101000 ; LCD: 4 bit; 2 lines; 5x8 dots
  jsr lcdcommandbusy

  lda #%00000001 ; LCD: clear display
  jsr lcdcommand
  lda #$01
  jsr waitms
  jsr lcdbusy
  lda #%00001111 ; LCD: display on; cursor on; blink on
  jsr lcdcommandbusy
  lda #%00000110 ; LCD: increment address; no shift display
  jsr lcdcommandbusy

  lda #lcd_cgram ; LCD: set address counter to CGRAM 00
  jsr lcdcommandbusy
  lda #lcd_chars_number
  ldx #0
setupcharsloop:
  ldy #lcd_char_height
  pha
setupcharloop:
  lda lcdchars, X
  jsr lcdwritebusy
  inx
  dey
  bne setupcharloop
  pla
  dec
  bne setupcharsloop

  lda #lcd_ddram ; LCD: set address counter to DDRAM 00
  jsr lcdcommandbusy

  lda #%00000010 ; LCD: home
  jsr lcdcommandbusy

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

lcdcommand8:
  pha
  and #%11110000
  sta via_data_b
  ora #lcd_control_e
  sta via_data_b
  lda #0
  sta via_data_b
  pla
  rts

lcdcommand:
  pha
  pha
  and #%11110000
  pha
  sta via_data_b
  ora #lcd_control_e
  sta via_data_b
  pla
  sta via_data_b
  pla
  asl
  asl
  asl
  asl
  pha
  sta via_data_b
  ora #lcd_control_e
  sta via_data_b
  pla
  sta via_data_b
  pla
  rts

lcdcommandbusy8:
  jsr lcdcommand8
  jsr lcdbusy8
  rts

lcdcommandbusy:
  jsr lcdcommand
  jsr lcdbusy
  rts

lcdwritebusy:
  pha
  pha
  and #%11110000
  ora #lcd_control_rs
  pha
  sta via_data_b
  ora #lcd_control_e
  sta via_data_b
  pla
  sta via_data_b
  pla
  asl
  asl
  asl
  asl
  ora #lcd_control_rs
  pha
  sta via_data_b
  ora #lcd_control_e
  sta via_data_b
  pla
  sta via_data_b
  jsr lcdbusy
  pla
  rts

lcdprint:
  jsr lcdwritebusy
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
  jsr lcdcommandbusy
  jmp lcdreturn
lcdchangeline23:
  lda #lcd_address_line1_middle
  sta lcd_address_counter
  ora #lcd_ddram
  jsr lcdcommandbusy
  jmp lcdreturn
lcdchangeline2:
  lda #lcd_address_line2_middle
  sta lcd_address_counter
  ora #lcd_ddram
  jsr lcdcommandbusy
lcdreturn:
  pla
  rts

lcdbusy8:
  pha
  lda #via_lcd_read ; LCD allow read from data pins
  sta via_dir_b
lcdbusyloop80:
  lda #lcd_control_rw
  sta via_data_b
  ora #lcd_control_e
  sta via_data_b
  lda via_data_b
  and #lcd_busy_flag
  bne lcdbusyloop80
  lda #lcd_control_rw
  sta via_data_b
  lda #via_lcd_write ; LCD make all write only
  sta via_dir_b
  pla
  rts

lcdbusy:
  pha
  lda #via_lcd_read ; LCD allow read from data pins
  sta via_dir_b
lcdbusyloop0:
  lda #lcd_control_rw
  sta via_data_b
  ora #lcd_control_e
  sta via_data_b
  lda via_data_b
  and #%11110000
  sta lcd_address_counter
  lda #lcd_control_rw
  sta via_data_b
  ora #lcd_control_e
  sta via_data_b
  lda via_data_b
  and #%11110000
  ror
  ror
  ror
  ror
  ora lcd_address_counter
  sta lcd_address_counter
  and #lcd_busy_flag
  bne lcdbusyloop0
  lda #lcd_control_rw
  sta via_data_b
  lda #via_lcd_write ; LCD make all write only
  sta via_dir_b
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
  jsr lcdprint
  jsr ledhigh
  pla
  rti

  .org $fffc
  .word reset
  .word isr
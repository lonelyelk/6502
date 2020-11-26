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

btn_state_cache .equ $0200
btn_state .equ $0201
irq_counter .equ $0202
lcd_address_counter .equ $0203
lcd_state_dirty .equ $0204
lcd_address_pointer .equ $0205
lcd_memory .equ $0300

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

btn_num .equ $10
btn_irq_ticks .equ 3

  .org $8000

reset:
  sei
  lda via_ier
  ora #%10000010 ; VIA enable CA1 interrupt
  sta via_ier

  jsr serialsetup
  jsr lcdsetup

  lda #0
  sta irq_counter
  sta btn_state
  sta btn_state_cache
  sta lcd_address_pointer
  ldx #0
  lda #" "
lcd_clear:
  sta lcd_memory, x
  inx
  cpx #80
  bne lcd_clear

  lda #">"
  jsr lcdprint
  cli

loop:
  nop
  jmp loop

nmi:
irq:
  pha
  phx
  phy
serial_check:
  lda via_ifr
  and #%00000100 ; IRQ: check if serial port is the source of IRQ (finished data tramsmit, time to pulse latch)
  beq btn_check
  lda #%1110 ; VIA control CA2 high
  sta via_pcr
  lda #%1100 ; VIA control CA2 low
  sta via_pcr
  lda via_sr ; VIA reset shift register
btn_check:
  lda via_ifr
  and #%00000010 ; IRQ: check if CA1 is the source of IRQ (another timer)
  beq lcd_check
  lda #%00001111 ; BTN: horizontals are high and outputing, verticals read
  sta via_dir_a
  sta via_data_a
  lda via_data_a
  and #%11110000 ; BTN: read verticals
  sta btn_state
  lda #%11110000 ; BTN: verticals are high and outputing, horizontals read
  sta via_dir_a
  sta via_data_a
  lda via_data_a
  and #%00001111 ; BTN: read horizontals
  ora btn_state
  cmp btn_state_cache
  beq reset_irq
  sta btn_state
  lda irq_counter
  inc
  sta irq_counter
  cmp #btn_irq_ticks
  bcc lcd_check
  lda btn_state
  sta btn_state_cache
  beq lcd_check
  ldx #0
  stx irq_counter
btn_loop:
  cmp btninput, X
  beq print_btn_char
  inx
  cpx #btn_num
  beq lcd_check
  jmp btn_loop
print_btn_char:
  lda btnoutput, X
  jsr lcdprint
  jsr serialoutput
lcd_check:
  lda lcd_state_dirty
  beq exit_irq
  jsr lcdrefresh
exit_irq:
  ply
  plx
  pla
  rti
reset_irq:
  lda #0
  sta irq_counter
  jmp lcd_check

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
  ora #%10000100 ; VIA enable shift register interrupt
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
  pha
  phx
  ldx lcd_address_pointer
  sta lcd_memory, x
  inx
  cpx #80
  bne lcdprint_exit
  ldx #0
lcdprint_exit:
  stx lcd_address_pointer
  lda #1
  sta lcd_state_dirty

;;  jsr lcdwritebusy
;;  pha
;;  lda lcd_address_counter
;;  cmp #lcd_address_line1_middle
;;  beq lcdchangeline12
;;  cmp #lcd_address_line2_middle
;;  beq lcdchangeline23
;;  cmp #lcd_address_line2_start
;;  beq lcdchangeline2
;;  jmp lcdreturn
;;lcdchangeline12:
;;  lda #lcd_address_line2_start
;;  sta lcd_address_counter
;;  ora #lcd_ddram
;;  jsr lcdcommandbusy
;;  jmp lcdreturn
;;lcdchangeline23:
;;  lda #lcd_address_line1_middle
;;  sta lcd_address_counter
;;  ora #lcd_ddram
;;  jsr lcdcommandbusy
;;  jmp lcdreturn
;;lcdchangeline2:
;;  lda #lcd_address_line2_middle
;;  sta lcd_address_counter
;;  ora #lcd_ddram
;;  jsr lcdcommandbusy
;;lcdreturn:
  plx
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

lcdrefresh:
  pha
  phx
  phy
  lda #%00000010 ; LCD: home
  jsr lcdcommandbusy
  ldx #0
line1:
  lda lcd_memory, x
  jsr lcdwritebusy
  inx
  cpx #20
  bne line1
  ldx #40
line2:
  lda lcd_memory, x
  jsr lcdwritebusy
  inx
  cpx #60
  bne line2
  ldx #20
line3:
  lda lcd_memory, x
  jsr lcdwritebusy
  inx
  cpx #40
  bne line3
  ldx #60
line4:
  lda lcd_memory, x
  jsr lcdwritebusy
  inx
  cpx #80
  bne line4
  lda lcd_address_pointer
  cmp #20 ;; 0-19 -> 0-19
  bmi set_cursor
  cmp #40 ;; 20-39 -> 64-83
  bmi cursor_line2
  cmp #60 ;; 40-59 -> 20-39 line shifts AC?
  bmi cursor_line3
  adc #23 ;; 60-79 -> 84-93
set_cursor:
  ora #lcd_ddram
  jsr lcdcommandbusy
  lda #0
  sta lcd_state_dirty
  ply
  plx
  pla
  rts
cursor_line2:
  adc #44
  jmp set_cursor
cursor_line3:
  sbc #19
  jmp set_cursor


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
  .byte %00100 ;; male
  .byte %01010
  .byte %01110
  .byte %01010
  .byte %01010
  .byte %10101
  .byte %10101
  .byte %01110
  .byte %01110 ;; female
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

btninput:
  .byte %00101000 ;; 0
  .byte %00010001 ;; 1
  .byte %00100001 ;; 2
  .byte %01000001 ;; 3
  .byte %00010010 ;; 4
  .byte %00100010 ;; 5
  .byte %01000010 ;; 6
  .byte %00010100 ;; 7
  .byte %00100100 ;; 8
  .byte %01000100 ;; 9
  .byte %10000001 ;; a
  .byte %10000010 ;; b
  .byte %10000100 ;; c
  .byte %10001000 ;; d
  .byte %00011000 ;; *
  .byte %01001000 ;; #

btnoutput:
  .byte "0"
  .byte "1"
  .byte "2"
  .byte "3"
  .byte "4"
  .byte "5"
  .byte "6"
  .byte "7"
  .byte "8"
  .byte "9"
  .byte "a"
  .byte "b"
  .byte "c"
  .byte "d"
  .byte "*"
  .byte "#"

  .org $fffa
  .word nmi
  .word reset
  .word irq
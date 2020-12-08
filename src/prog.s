;; VIA1 7ff0-7fff
via1_data_a .equ $7fff
via1_data_b .equ $7ff0
via1_dir_a .equ $7ff3
via1_dir_b .equ $7ff2
via1_sr .equ $7ffa
via1_acr .equ $7ffb
via1_pcr .equ $7ffc
via1_ifr .equ $7ffd
via1_ier .equ $7ffe

;; VIA2 7fe0-7fef
via2_data_a .equ $7fef
via2_data_b .equ $7fe0
via2_dir_a .equ $7fe3
via2_dir_b .equ $7fe2
via2_sr .equ $7fea
via2_acr .equ $7feb
via2_pcr .equ $7fec
via2_ifr .equ $7fed
via2_ier .equ $7fee

via_lcd_write .equ %11111110 ; LCD data (4 most significant bits) E, RW, RS
via_lcd_read .equ %00001110

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

;; variables
btn_state_cache .equ $0200
btn_state .equ $0201
irq_counter .equ $0202
lcd_address_counter .equ $0203
lcd_state_dirty .equ $0204
lcd_address_pointer .equ $0205
lcd_memory .equ $0300
kbd_input .equ $0400
  .org $8000

reset:
  sei
  lda via1_ier
  ora #%10010000 ; VIA1 enable CB1 interrupt
  sta via1_ier

  jsr serialsetup
  jsr lcdsetup
  jsr kbd_setup

  lda #%00001111 ; KBD: columns output, rows input
  sta via2_dir_a

  lda #0
  sta irq_counter
  sta btn_state
  sta btn_state_cache
  sta lcd_address_pointer
  sta via2_data_a
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
  lda lcd_state_dirty
  beq loop
  jsr lcdrefresh
  jmp loop

nmi:
irq:
  pha
  phx
  phy
serial_check:
  lda via2_ifr
  and #%00000100 ; IRQ: check if serial port is the source of IRQ (finished data tramsmit, time to pulse latch)
  beq kbd_check
  lda #%1110 ; VIA2 control CA2 high
  sta via2_pcr
  lda #%1100 ; VIA2 control CA2 low
  sta via2_pcr
  lda via2_sr ; VIA2 reset shift register
kbd_check: ;; KBD: bit flags are: [release ack] [press ack] [press state]
  lda via1_ifr
  and #%00010000 ; IRQ: check if CB1 is the source of IRQ (another timer)
  beq exit_irq
  lda #%00001000 ; KBD: power columns from left to right: DA0(c1) ror-> DA1(c2) ror-> DA2(c3) ror-> DA3(c4)
  sta via2_data_a
  ldx #0
kbd_loop:
  pha
  ldy #4 ;; KBD: start with bottom row
  lda via2_data_a
kbd_col_loop: ; KBD read pits for columns from bottom to top: DA4(r1) <-rol DA5(r2) <-rol DA6(r3) <-rol DA7(r4)
  rol
  bcc kbd_col_open
  clc
  pha
  lda kbd_input, x
  and #%011
  ora #%001
  sta kbd_input, x
  pla
  jmp kbd_col_cont
kbd_col_open:
  pha
  lda kbd_input, x
  and #%100
  sta kbd_input, x
  pla
kbd_col_cont:
  inx
  dey
  bne kbd_col_loop
  pla
  ror
  bcs kbd_loop_exit
  sta via2_data_a ;; KBD: next column to the left
  jmp kbd_loop
kbd_loop_exit:
  dex
  clc
lcd_kbd_state_loop:
  txa
  adc #60
  tay
  lda kbd_input, x
  bit #%001
  beq lcd_kbd_release
  and #%010
  bne lcd_kbd_state_cont
;;lcd_kbd_press:
  lda #%011
  sta kbd_input, x
  lda kbd_values, x
  jsr lcdprint
  lda #"*"
  sta lcd_memory, y
  jmp lcd_kbd_state_cont
lcd_kbd_release:
  and #%100
  bne lcd_kbd_state_cont
  lda #%100
  sta kbd_input, x
  lda #" "
  sta lcd_memory, y
  lda #1
  sta lcd_state_dirty
lcd_kbd_state_cont:
  dex
  bpl lcd_kbd_state_loop

;;;;print_btn_char:
;;;;  lda btnoutput, X
;;;;  jsr lcdprint
;;;;  lda leddigitsoutput, X
;;;;  jsr serialoutput

exit_irq:
  lda via1_data_b
  ply
  plx
  pla
  rti

kbd_setup:
  pha
  phx
  ldx #15
  lda #0
kbd_setup_loop
  sta kbd_input, x
  dex
  bpl kbd_setup_loop
  plx
  pla
  rts

serialsetup:
  pha
  lda via2_sr ; VIA2 reset shift register
  lda via2_ier
  ora #%10000100 ; VIA2 enable shift register interrupt
  sta via2_ier
  lda via2_acr
  ora #%00011000
  and #%11111011 ; VIA2 shift register mode 110
  sta via2_acr
  lda #%1100 ; VIA2 control CA2 low
  sta via2_pcr
  lda #%1110 ; VIA2 control CA2 high
  sta via2_pcr
  lda #%1100 ; VIA2 control CA2 low
  sta via2_pcr
  pla
  rts

serialoutput:
  sta via2_sr
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
  sta via1_dir_b

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
  sta via1_data_b
  ora #lcd_control_e
  sta via1_data_b
  lda #0
  sta via1_data_b
  pla
  rts

lcdcommand:
  pha
  pha
  and #%11110000
  pha
  sta via1_data_b
  ora #lcd_control_e
  sta via1_data_b
  pla
  sta via1_data_b
  pla
  asl
  asl
  asl
  asl
  pha
  sta via1_data_b
  ora #lcd_control_e
  sta via1_data_b
  pla
  sta via1_data_b
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
  sta via1_data_b
  ora #lcd_control_e
  sta via1_data_b
  pla
  sta via1_data_b
  pla
  asl
  asl
  asl
  asl
  ora #lcd_control_rs
  pha
  sta via1_data_b
  ora #lcd_control_e
  sta via1_data_b
  pla
  sta via1_data_b
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
  plx
  pla
  rts

lcdbusy8:
  pha
  lda #via_lcd_read ; LCD allow read from data pins
  sta via1_dir_b
lcdbusyloop80:
  lda #lcd_control_rw
  sta via1_data_b
  ora #lcd_control_e
  sta via1_data_b
  lda via1_data_b
  and #lcd_busy_flag
  bne lcdbusyloop80
  lda #lcd_control_rw
  sta via1_data_b
  lda #via_lcd_write ; LCD make all write only
  sta via1_dir_b
  pla
  rts

lcdbusy:
  pha
  lda #via_lcd_read ; LCD allow read from data pins
  sta via1_dir_b
lcdbusyloop0:
  lda #lcd_control_rw
  sta via1_data_b
  ora #lcd_control_e
  sta via1_data_b
  lda via1_data_b
  and #%11110000
  sta lcd_address_counter
  lda #lcd_control_rw
  sta via1_data_b
  ora #lcd_control_e
  sta via1_data_b
  lda via1_data_b
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
  sta via1_data_b
  lda #via_lcd_write ; LCD make all write only
  sta via1_dir_b
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

kbd_values:
  .byte "D" ;; D
  .byte "C" ;; C
  .byte "B" ;; B
  .byte "A" ;; A
  .byte "#" ;; #
  .byte 9 ;; 9
  .byte 6 ;; 6
  .byte 3 ;; 3
  .byte 0 ;; 0
  .byte 8 ;; 8
  .byte 5 ;; 5
  .byte 2 ;; 2
  .byte "*" ;; *
  .byte 7 ;; 7
  .byte 4 ;; 4
  .byte 1 ;; 1

leddigitsoutput:
  .byte %00010001 ;; 0
  .byte %11010111 ;; 1
  .byte %00110010 ;; 2
  .byte %10010010 ;; 3
  .byte %11010100 ;; 4
  .byte %10011000 ;; 5
  .byte %00011000 ;; 6
  .byte %11010011 ;; 7
  .byte %00010000 ;; 8
  .byte %10010000 ;; 9
  .byte %01010000 ;; a
  .byte %00011100 ;; b
  .byte %00111110 ;; c
  .byte %00010110 ;; d
  .byte %11101111 ;; *
  .byte %00011110 ;; #

  .org $fffa
  .word nmi
  .word reset
  .word irq
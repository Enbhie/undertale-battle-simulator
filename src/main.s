.segment "HEADER"
  .byte "NES", $1A
  .byte 2, 1          ; 32K PRG, 8K CHR
  .byte $01, $00      ; vertical mirroring, mapper 0
  .res 8, 0

.segment "ZEROPAGE"
px:      .res 1
py:      .res 1
buttons: .res 1

.segment "CODE"

reset:
  sei
  cld
  ldx #$40
  stx $4017
  ldx #$FF
  txs
  inx
  stx $2000
  stx $2001
  stx $4010
: bit $2002
  bpl :-

  ; clear RAM, hide sprites
  lda #0
@clr:
  sta $0000,x
  sta $0100,x
  sta $0300,x
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  lda #$FE
  sta $0200,x
  lda #0
  inx
  bne @clr

: bit $2002
  bpl :-

  ; load palettes
  lda $2002
  lda #$3F
  sta $2006
  lda #$00
  sta $2006
  ldx #0
: lda palette,x
  sta $2007
  inx
  cpx #32
  bne :-

  lda #120
  sta px
  lda #112
  sta py

  lda #%10000000      ; NMI on
  sta $2000
  lda #%00011110      ; show sprites + background
  sta $2001

forever:
  jmp forever

nmi:
  pha
  txa
  pha

  lda #0
  sta $2003
  lda #>$0200
  sta $4014           ; OAM DMA

  ; read controller 1
  lda #1
  sta $4016
  lda #0
  sta $4016
  ldx #8
: lda $4016
  lsr a
  rol buttons
  dex
  bne :-

  ; bits: A B Sel Start Up Down Left Right
  lda buttons
  and #%00001000
  beq :+
  dec py
: lda buttons
  and #%00000100
  beq :+
  inc py
: lda buttons
  and #%00000010
  beq :+
  dec px
: lda buttons
  and #%00000001
  beq :+
  inc px
:
  lda py
  sta $0200
  lda #1
  sta $0201
  lda #0
  sta $0202
  lda px
  sta $0203

  lda #0
  sta $2005
  sta $2005

  pla
  tax
  pla
  rti

irq:
  rti

.segment "RODATA"
palette:
  .byte $0F,$00,$10,$30, $0F,$00,$10,$30, $0F,$00,$10,$30, $0F,$00,$10,$30
  .byte $0F,$16,$06,$26, $0F,$16,$06,$26, $0F,$16,$06,$26, $0F,$16,$06,$26

.segment "VECTORS"
  .word nmi, reset, irq

.segment "CHARS"
  .res 16, 0          ; tile 0: blank
  ; tile 1: soul
  .byte %01100110
  .byte %11111111
  .byte %11111111
  .byte %11111111
  .byte %01111110
  .byte %00111100
  .byte %00011000
  .byte %00000000
  .res 8, 0

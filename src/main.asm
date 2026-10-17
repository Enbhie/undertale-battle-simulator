; Soul Dodge for the NES
; D-pad moves the soul one cell per game tick. Survive 300 ticks:
; at 80 ms per tick, that is about 24 seconds. Start restarts after an ending.

.segment "HEADER"
  .byte "NES", $1A
  .byte 2, 1
  .byte $01, $00
  .res 8, 0

.segment "ZEROPAGE"
player_x:       .res 1
player_y:       .res 1
buttons:        .res 1
frame_count:    .res 1
frame_divider:  .res 1
frame_target:   .res 1
cadence_phase:  .res 1
hp:             .res 1
invulnerable:   .res 1
rng:            .res 1
spawn_clock:    .res 1
wave_clock:     .res 1
wave_row:       .res 1
wave_gap:       .res 1
wave_phase:     .res 1
wave_active:    .res 1
time_clock:     .res 1
time_segments:  .res 1
game_state:     .res 1
bullet_index:   .res 1
oam_index:      .res 1
cell_col:       .res 1
cell_row:       .res 1
cell_tile:      .res 1
row_number:     .res 1
gap_test:       .res 1
bullet_x:       .res 24
bullet_y:       .res 24
patch_count:    .res 1
patch_hi:       .res 48
patch_lo:       .res 48
patch_tile:     .res 48

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

@wait_vblank:
  bit $2002
  bpl @wait_vblank

  ; Clear work RAM and hide every OAM entry.
  lda #0
  ldx #0
@clear_ram:
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
  bne @clear_ram

@wait_second_vblank:
  bit $2002
  bpl @wait_second_vblank

  ; Load the universal background and sprite palettes.
  lda $2002
  lda #$3F
  sta $2006
  lda #$00
  sta $2006
  ldx #0
@palette_loop:
  lda palette,x
  sta $2007
  inx
  cpx #32
  bne @palette_loop

  ; Clear the nametable and its attribute table.
  lda $2002
  lda #$20
  sta $2006
  lda #$00
  sta $2006
  lda #0
  ldx #4
  ldy #0
@clear_nametable:
  sta $2007
  iny
  bne @clear_nametable
  dex
  bne @clear_nametable

  ; Draw the top and bottom arena walls.
  lda $2002
  lda #$20
  sta $2006
  lda #$62
  sta $2006
  ldx #28
  lda #3
@top_wall:
  sta $2007
  dex
  bne @top_wall

  lda $2002
  lda #$23
  sta $2006
  lda #$82
  sta $2006
  ldx #28
@bottom_wall:
  sta $2007
  dex
  bne @bottom_wall

  ; Draw both side walls using the PPU's 32-byte increment.
  lda #4
  sta $2000
  lda $2002
  lda #$20
  sta $2006
  lda #$82
  sta $2006
  ldx #24
  lda #3
@left_wall:
  sta $2007
  dex
  bne @left_wall

  lda $2002
  lda #$20
  sta $2006
  lda #$9D
  sta $2006
  ldx #24
@right_wall:
  sta $2007
  dex
  bne @right_wall
  lda #0
  sta $2000

  ; Twenty hearts and five time markers form the HUD.
  lda $2002
  lda #$20
  sta $2006
  lda #$23
  sta $2006
  ldx #20
  lda #4
@draw_hearts:
  sta $2007
  dex
  bne @draw_hearts

  lda $2002
  lda #$20
  sta $2006
  lda #$38
  sta $2006
  ldx #5
  lda #5
@draw_time:
  sta $2007
  dex
  bne @draw_time

  jsr initialize_game
  jsr render_oam
  lda #%10000000
  sta $2000
  lda #%00011110
  sta $2001

main_loop:
  lda frame_count
@wait_frame:
  cmp frame_count
  beq @wait_frame
  inc frame_divider
  lda frame_divider
  cmp frame_target
  bcc main_loop
  lda #0
  sta frame_divider
  jsr game_tick
  inc cadence_phase
  lda cadence_phase
  cmp #4
  beq @short_tick
  cmp #5
  bne @next_frame
  lda #0
  sta cadence_phase
  lda #5
  sta frame_target
  jmp @next_frame
@short_tick:
  lda #4
  sta frame_target
@next_frame:
  jmp main_loop

; Game ticks average 4.8 NTSC frames, approximately 80 ms.
game_tick:
  jsr read_controller
  lda game_state
  beq @playing
  lda buttons
  and #$08
  bne @restart
  jmp @show_finished
@restart:
  jsr restart_game
  jmp @finished

@playing:
@move_player:
  lda buttons
  and #$40
  beq @move_right
  lda player_x
  beq @move_right
  dec player_x
@move_right:
  lda buttons
  and #$80
  beq @move_up
  lda player_x
  cmp #25
  bcs @move_up
  inc player_x
@move_up:
  lda buttons
  and #$10
  beq @move_down
  lda player_y
  beq @move_down
  dec player_y
@move_down:
  lda buttons
  and #$20
  beq @countdown
  lda player_y
  cmp #23
  bcs @countdown
  inc player_y

@countdown:
  lda invulnerable
  beq @spawn_bullets
  dec invulnerable

@spawn_bullets:
  inc spawn_clock
  lda spawn_clock
  cmp #3
  bne @move_bullets
  lda #0
  sta spawn_clock
  jsr spawn_bullet

@move_bullets:
  ldx #0
@move_bullet_loop:
  cpx #24
  beq @wave_timer
  stx bullet_index
  lda bullet_y,x
  cmp #$FF
  beq @next_bullet
  inc bullet_y,x
  lda bullet_y,x
  cmp #24
  bcc @next_bullet
  lda #$FF
  sta bullet_y,x
@next_bullet:
  ldx bullet_index
  inx
  jmp @move_bullet_loop

@wave_timer:
  inc wave_clock
  lda wave_clock
  cmp #60
  bne @advance_wave
  lda #0
  sta wave_clock
  jsr start_wave

@advance_wave:
  lda wave_active
  beq @collisions
  inc wave_phase
  lda wave_phase
  cmp #2
  bcc @collisions
  lda #0
  sta wave_phase
  lda #0
  sta cell_tile
  jsr patch_wave_row
  inc wave_row
  lda wave_row
  cmp #24
  bcs @wave_finished
  lda #2
  sta cell_tile
  jsr patch_wave_row
  jmp @collisions
@wave_finished:
  lda #0
  sta wave_active

@collisions:
  jsr check_bullet_collisions
  lda game_state
  bne @render
  jsr check_wave_collision
  lda game_state
  bne @render

  inc time_clock
  lda time_clock
  cmp #60
  bne @render
  lda #0
  sta time_clock
  dec time_segments
  lda time_segments
  clc
  adc #24
  tax
  lda #0
  ldy #1
  jsr queue_tile
  lda time_segments
  bne @render
  lda #1
  sta game_state

@render:
  jsr render_oam
  jmp @finished
@show_finished:
  jsr render_oam
@finished:
  rts

initialize_game:
  lda #13
  sta player_x
  lda #20
  sta player_y
  lda #20
  sta hp
  lda #0
  sta invulnerable
  sta spawn_clock
  sta wave_clock
  sta wave_row
  sta wave_gap
  sta wave_phase
  sta wave_active
  sta time_clock
  sta game_state
  sta cadence_phase
  lda #5
  sta frame_target
  lda #5
  sta time_segments
  lda #$A7
  sta rng
  ldx #0
@clear_bullet_slots:
  lda #$FF
  sta bullet_y,x
  inx
  cpx #24
  bne @clear_bullet_slots
  rts

restart_game:
  lda #0
  sta patch_count
  lda wave_active
  beq @restart_state
  lda #0
  sta cell_tile
  jsr patch_wave_row
@restart_state:
  jsr initialize_game
  ; Restore the HUD after a previous run depleted hearts or time.
  lda #0
  sta bullet_index
@restore_hearts:
  lda bullet_index
  clc
  adc #3
  tax
  lda #4
  ldy #1
  jsr queue_tile
  inc bullet_index
  lda bullet_index
  cmp #20
  bne @restore_hearts
  lda #24
  sta bullet_index
@restore_time:
  lda bullet_index
  tax
  ldy #1
  lda #5
  jsr queue_tile
  inc bullet_index
  lda bullet_index
  cmp #29
  bne @restore_time
  jsr render_oam
  rts

read_controller:
  lda #1
  sta $4016
  lda #0
  sta $4016
  sta buttons
  ldx #0
@read_button:
  lda $4016
  and #1
  beq @next_button
  lda button_masks,x
  ora buttons
  sta buttons
@next_button:
  inx
  cpx #8
  bne @read_button
  rts

spawn_bullet:
  jsr random_byte
  ; Reduce the random byte to one of the 26 playable columns.
@reduce_column:
  cmp #26
  bcc @column_ready
  sec
  sbc #26
  jmp @reduce_column
@column_ready:
  sta gap_test
  ldx #0
@find_bullet_slot:
  cpx #24
  beq @spawn_done
  lda bullet_y,x
  cmp #$FF
  beq @found_bullet_slot
  inx
  jmp @find_bullet_slot
@found_bullet_slot:
  lda gap_test
  sta bullet_x,x
  lda #0
  sta bullet_y,x
@spawn_done:
  rts

start_wave:
  jsr random_byte
@reduce_gap:
  cmp #23
  bcc @gap_ready
  sec
  sbc #23
  jmp @reduce_gap
@gap_ready:
  sta wave_gap
  lda #0
  sta wave_row
  sta wave_phase
  lda #1
  sta wave_active
  lda #2
  sta cell_tile
  jsr patch_wave_row
  rts

patch_wave_row:
  lda wave_row
  clc
  adc #4
  sta row_number
  ldx #0
@patch_wave_column:
  cpx #26
  beq @patch_wave_done
  stx gap_test
  txa
  cmp wave_gap
  bcc @patch_wave_cell
  sec
  sbc wave_gap
  cmp #4
  bcc @skip_wave_cell
@patch_wave_cell:
  lda cell_tile
  ldx gap_test
  txa
  clc
  adc #3
  tax
  ldy row_number
  lda cell_tile
  jsr queue_tile
@skip_wave_cell:
  ldx gap_test
  inx
  jmp @patch_wave_column
@patch_wave_done:
  rts

check_bullet_collisions:
  ldx #0
@check_bullet:
  cpx #24
  beq @check_bullet_done
  stx bullet_index
  lda bullet_y,x
  cmp #$FF
  beq @next_collision_bullet
  cmp player_y
  bne @next_collision_bullet
  lda bullet_x,x
  cmp player_x
  bne @next_collision_bullet
  lda #$FF
  sta bullet_y,x
  jsr damage_player
@next_collision_bullet:
  ldx bullet_index
  inx
  jmp @check_bullet
@check_bullet_done:
  rts

check_wave_collision:
  lda wave_active
  beq @wave_collision_done
  lda player_y
  cmp wave_row
  bne @wave_collision_done
  lda player_x
  cmp wave_gap
  bcc @take_wave_hit
  sec
  sbc wave_gap
  cmp #4
  bcc @wave_collision_done
@take_wave_hit:
  jsr damage_player
@wave_collision_done:
  rts

damage_player:
  lda invulnerable
  bne @damage_done
  dec hp
  lda hp
  clc
  adc #3
  tax
  lda #0
  ldy #1
  jsr queue_tile
  lda #8
  sta invulnerable
  lda hp
  bne @damage_done
  lda #2
  sta game_state
@damage_done:
  rts

; Queue one nametable change for the next vblank. Inputs: A=tile, X=column,
; Y=row. The wave queue is bounded at 47 writes, including restart HUD restoration.
queue_tile:
  sta cell_tile
  stx cell_col
  sty cell_row
  ldy patch_count
  lda cell_col
  sta patch_lo,y
  lda cell_row
  and #7
  asl
  asl
  asl
  asl
  asl
  clc
  adc patch_lo,y
  sta patch_lo,y
  lda cell_row
  lsr
  lsr
  lsr
  tax
  lda row_high,x
  ldx patch_count
  sta patch_hi,x
  lda cell_tile
  sta patch_tile,x
  inc patch_count
  rts

render_oam:
  ldy #0
  lda #$FE
@hide_sprites:
  sta $0200,y
  tya
  clc
  adc #4
  tay
  bne @hide_sprites

  lda player_y
  asl
  asl
  asl
  clc
  adc #31
  sta $0200
  lda #1
  sta $0201
  lda #0
  ldx game_state
  beq @player_palette
  cpx #1
  bne @lost_palette
  lda #1
  bne @player_palette
@lost_palette:
  lda #2
@player_palette:
  sta $0202
  lda player_x
  asl
  asl
  asl
  clc
  adc #24
  sta $0203

  lda game_state
  bne @render_done
  lda #4
  sta oam_index
  ldx #0
@render_bullets:
  cpx #24
  beq @render_done
  stx bullet_index
  lda bullet_y,x
  cmp #$FF
  beq @next_render_bullet
  ldy oam_index
  asl
  asl
  asl
  clc
  adc #31
  sta $0200,y
  lda #2
  sta $0201,y
  lda #0
  sta $0202,y
  ldx bullet_index
  lda bullet_x,x
  asl
  asl
  asl
  clc
  adc #24
  ldy oam_index
  sta $0203,y
  inc oam_index
  inc oam_index
  inc oam_index
  inc oam_index
@next_render_bullet:
  ldx bullet_index
  inx
  jmp @render_bullets
@render_done:
  rts

random_byte:
  lda rng
  asl
  bcc @no_feedback
  eor #$1D
@no_feedback:
  sta rng
  rts

nmi:
  pha
  txa
  pha
  tya
  pha
  inc frame_count

  lda patch_count
  beq @patches_done
  lda $2002
  ldx #0
@apply_patch:
  cpx patch_count
  beq @patches_done
  lda patch_hi,x
  sta $2006
  lda patch_lo,x
  sta $2006
  lda patch_tile,x
  sta $2007
  inx
  jmp @apply_patch
@patches_done:
  lda #0
  sta patch_count
  lda #0
  sta $2005
  sta $2005
  lda #0
  sta $2003
  lda #2
  sta $4014
  pla
  tay
  pla
  tax
  pla
  rti

irq:
  rti

.segment "RODATA"
button_masks:
  .byte $01,$02,$04,$08,$10,$20,$40,$80

row_high:
  .byte $20,$20,$20,$20,$20,$20,$20,$20
  .byte $21,$21,$21,$21,$21,$21,$21,$21
  .byte $22,$22,$22,$22,$22,$22,$22,$22
  .byte $23,$23,$23,$23,$23,$23

palette:
  .byte $0F,$16,$27,$30, $0F,$16,$27,$30
  .byte $0F,$16,$27,$30, $0F,$16,$27,$30
  .byte $0F,$16,$27,$30, $0F,$2A,$30,$30
  .byte $0F,$06,$16,$30, $0F,$16,$27,$30

.segment "VECTORS"
  .word nmi, reset, irq

.segment "CHARS"
  ; Tile 0: blank.
  .res 16, 0
  ; Tile 1: soul.
  .byte %01100110,%11111111,%11111111,%11111111
  .byte %01111110,%00111100,%00011000,%00000000
  .res 8, 0
  ; Tile 2: falling bullet.
  .byte %00011000,%00111100,%01111110,%01111110
  .byte %01111110,%00111100,%00011000,%00000000
  .res 8, 0
  ; Tile 3: solid wall, using palette color 2.
  .res 8, 0
  .byte $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
  ; Tile 4: HUD heart.
  .byte %01100110,%11111111,%11111111,%11111111
  .byte %01111110,%00111100,%00011000,%00000000
  .res 8, 0
  ; Tile 5: gold time marker, using palette color 2.
  .res 8, 0
  .byte %00111100,%01111110,%11111111,%11111111
  .byte %11111111,%01111110,%00111100,%00011000

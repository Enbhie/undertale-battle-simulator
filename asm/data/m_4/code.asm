m_4_start:
    ; song 100 = MEGALOVANIA
    LDX #100
    JSR play_music
    set_menu_dialog TXT_SANS_START
    mov player_soul ,  #SOUL::MENU
    JSR switch_player_soul

    display_anim ANIM_DATA_MONSTERS_SANS_SANS_BKG

    sta_ptr tmp+2 ,  sans_act_txt
    JSR init_monster_act

    LDX cur_monster_fight_pos
    LDA #$00
    STA monster_flags ,  X
    STA sans_turns
    STA sans_glide
    STA sans_off
    STA sans_final_phase
    STA sans_final_repeat

    JSR get_var_idx
    LDA #$00
    STA monster_vars+0 ,  X
    STA monster_vars+1 ,  X
    STA monster_vars+2 ,  X
    STA monster_vars+3 ,  X
    STA monster_vars+4 ,  X
    STA monster_vars+5 ,  X
    JMP clear_event

m_4_turn:
    SANS_FLAG_SWEAT = $10
    SANS_FLAG_FINAL_STARTED = $20
    @state = monster_vars+0
    @time = monster_vars+1
    @sp = monster_vars+3
    @att = monster_vars+4
    @cnt = monster_vars+5

    LDA cur_monster_fight_pos
    BEQ :+
    JMP @end_event
:
    LDA #$00
    STA sans_strk
    JSR get_var_idx
    LDA @state ,  X
    BEQ @setup
    CMP #$01
    BNE :+
    JMP @wait
:
    CMP #$03
    BEQ @restore_wait
    JMP @attack

    @restore_wait:
    LDA packet_buffer_end
    CMP #<packet_buffer
    BNE @restore_rts
    LDA packet_buffer_end+1
    CMP #>packet_buffer
    BNE @restore_rts
    LDA background_index
    BNE @restore_rts
    JMP @finish
    @restore_rts:
    RTS

    @setup:
    INC @state ,  X
    LDA #$00
    STA @time ,  X
    STA @cnt ,  X
    STA @sp ,  X
    STA sans_final_phase
    STA sans_final_repeat
    LDA #$FF
    STA sans_hbone_prev
    STA sans_hbone_prev+1
    LDA sans_turns
    CMP #22
    BCC :+
    LDY cur_monster_fight_pos
    LDA monster_flags ,  Y
    AND #SANS_FLAG_FINAL_STARTED
    BNE :+
    LDA monster_flags ,  Y
    ORA #SANS_FLAG_FINAL_STARTED
    STA monster_flags ,  Y
    INC sans_final_phase
:
    ; halfway through the strikes Sans starts to sweat
    LDA sans_turns
    CMP #10
    BCC :+
    LDY cur_monster_fight_pos
    LDA monster_flags ,  Y
    AND #SANS_FLAG_SWEAT
    BNE :+
    LDA monster_flags ,  Y
    ORA #SANS_FLAG_SWEAT
    STA monster_flags ,  Y
    display_anim ANIM_DATA_MONSTERS_SANS_SANS_SWEAT_BKG
    JSR get_var_idx
:
    JSR clear_main_box
    JSR text_post_process
    mov player_soul ,  #SOUL::RED
    JSR switch_player_soul
    mov futur_box_pos_x1 ,  #$40
    mov futur_box_pos_x2 ,  #$C6
    RTS

    @wait:
    LDA dialogbox_anim_flag
    BNE @rts
    LDA sans_final_phase
    CMP #$01
    BEQ @hbone_setup
    CMP #$00
    BNE @wait_done
    LDA @att ,  X
    AND #$03
    CMP #$03
    BNE @wait_done
    @hbone_setup:
    LDA @sp ,  X
    BNE @hbone_wait
    INC @sp ,  X
    sta_ptr tmp+8 ,  sans_hbone_empty
    LDA #SANS_HBONE_CHR
    STA tmp+10
    JSR sans_box_draw
    RTS
    @hbone_wait:
    LDA packet_buffer_end
    CMP #<packet_buffer
    BNE @rts
    LDA packet_buffer_end+1
    CMP #>packet_buffer
    BNE @rts
    LDA background_index
    BNE @rts
    LDA #$00
    STA @sp ,  X
    @wait_done:
    INC @state ,  X
    @rts:
    RTS

    @attack:
    LDA sans_final_phase
    BEQ @normal_attack
    CMP #$01
    BNE :+
    JMP @hbones
:
    CMP #$02
    BNE :+
    JMP @wave
:
    CMP #$03
    BNE :+
    JMP @bones
:
    CMP #$04
    BEQ :+
    LDA @time ,  X
    CMP #12
    BCS :++
    JMP @tick
:
    JMP @final_beam
:
    JMP @finish
    @normal_attack:
    LDA @att ,  X
    AND #$03
    BNE :+
    JMP @wave
:
    CMP #$01
    BNE :+
    JMP @blasters
:
    CMP #$02
    BNE :+
    JMP @bones
:
    JMP @hbones

    ; Attack 1: thin bones slide left, the gap between the top and bottom bones rises and falls
    @wave:
    LDA sans_final_phase
    BEQ :+
    LDA @time ,  X
    CMP #175
    BCS @wave_end
    JMP @wave_spawn
:
    LDA @time ,  X
    CMP #$8C
    BCS @wave_end
    @wave_spawn:
    LDA @sp ,  X
    BNE @wave_dec
    LDA #$09
    STA @sp ,  X
    LDY @cnt ,  X
    LDA sans_wave_top ,  Y
    STA sans_kind
    LDA #HITBOX::BONE_LEFT
    LDX #$B6
    LDY #$82
    JSR sans_spawn
    JSR get_var_idx
    LDY @cnt ,  X
    LDA sans_wave_bot ,  Y
    STA sans_kind
    TAY
    LDA #$BC
    SEC
    SBC sans_bone_h ,  Y
    TAY
    LDA #HITBOX::BONE_LEFT
    LDX #$B6
    JSR sans_spawn
    JSR get_var_idx
    INC @cnt ,  X
    LDA @cnt ,  X
    CMP #$06
    BCC @wave_end
    LDA #$00
    STA @cnt ,  X
    JMP @wave_end
    @wave_dec:
    DEC @sp ,  X
    @wave_end:
    LDA sans_final_phase
    CMP #$02
    BEQ @long_bones_end
    CMP #$03
    BEQ @long_bones_end
    LDA @time ,  X
    CMP #$D2
    BCC :+
    JMP @finish
:
    JMP @tick

    @long_bones_end:
    LDA @time ,  X
    CMP #174
    BCC @long_bones_tick
    LDA sans_final_repeat
    BNE @long_bones_last
    INC sans_final_repeat
    LDA #$FF
    STA @time ,  X
    JMP @tick
    @long_bones_last:
    LDA @time ,  X
    CMP #244
    BCC @long_bones_tick
    JMP @finish
    @long_bones_tick:
    JMP @tick

    ; Attack 2: a beam ring around the middle, then an X shaped beam
    @blasters:
    LDA @time ,  X
    BNE :+
    JMP @b_warn1
:
    CMP #$18
    BNE :+
    JMP @b_fire1
:
    CMP #$2C
    BEQ @b_clear
    CMP #$32
    BNE :+
    JMP @b_warn2
:
    CMP #$4A
    BNE :+
    JMP @b_fire2
:
    CMP #$5E
    BEQ @b_clear
    ; Allow the queued erase to finish before the box starts expanding.
    CMP #$6E
    BCC :+
    JMP @finish
:
    JMP @tick
    @b_clear:
    JSR clear_hitbox
    JSR sans_erase
    JMP @tick
    @b_warn1:
    sta_ptr tmp+8 ,  sans_beam_ring_warning
    JSR sans_beam_draw
    JMP @tick
    @b_warn2:
    sta_ptr tmp+8 ,  sans_beam_cross_warning
    JSR sans_beam_draw
    JMP @tick
    @b_fire1:
    sta_ptr tmp+8 ,  sans_beam_ring
    JSR sans_beam_draw
    sta_ptr tmp+8 ,  sans_beam_ring_hitboxes
    JSR sans_beam_hitboxes
    JMP @tick
    @b_fire2:
    sta_ptr tmp+8 ,  sans_beam_cross
    JSR sans_beam_draw
    sta_ptr tmp+8 ,  sans_beam_cross_hitboxes
    JSR sans_beam_hitboxes
    JMP @tick

    ; Attack 3: thin bones slide left one at a time, alternating top and bottom
    @bones:
    LDA sans_final_phase
    BEQ :+
    LDA @time ,  X
    CMP #175
    BCS @bones_end
    JMP @bones_spawn
:
    LDA @time ,  X
    CMP #$8C
    BCS @bones_end
    @bones_spawn:
    LDA @sp ,  X
    BNE @bones_dec
    LDA #$11
    STA @sp ,  X
    LDA #$03
    STA sans_kind
    LDA @cnt ,  X
    LSR
    BCS :+
    LDA #HITBOX::BONE_LEFT
    LDX #$B6
    LDY #$82
    JSR sans_spawn
    JSR get_var_idx
    JMP :++
    :
    LDA #HITBOX::BONE_LEFT
    LDX #$B6
    LDY #$BC
    TYA
    SEC
    SBC sans_bone_h+3
    TAY
    LDA #HITBOX::BONE_LEFT
    JSR sans_spawn
    JSR get_var_idx
    :
    INC @cnt ,  X
    JMP @wave_end
    @bones_dec:
    DEC @sp ,  X
    @bones_end:
    LDA sans_final_phase
    CMP #$03
    BNE :+
    JMP @long_bones_end
:
    LDA @time ,  X
    CMP #$D2
    BCC :+
    JMP @finish
:
    JMP @tick

    ; Step counterclockwise every 9 frames, about 2.9 pixels/frame at the box edge.
    @final_beam:
    LDA @sp ,  X
    BEQ @final_beam_draw
    CMP #$05
    BEQ @final_beam_collision
    JMP @final_beam_end
    @final_beam_draw:
    LDY @cnt ,  X
    TYA
    CLC
    ADC #SANS_ROTATE_BANK + $80
    STA tmp+10
    sta_ptr tmp+8 ,  sans_rotate_map
    JSR sans_box_draw
    JMP @final_beam_end
    @final_beam_collision:
    JSR clear_hitbox
    JSR get_var_idx
    LDY @cnt ,  X
    LDA sans_rotate_hitbox_lo ,  Y
    STA tmp+8
    LDA sans_rotate_hitbox_hi ,  Y
    STA tmp+9
    JSR sans_beam_hitboxes
    JSR get_var_idx
    DEC @cnt ,  X
    LDA @cnt ,  X
    AND #$07
    STA @cnt ,  X
    @final_beam_end:
    JSR get_var_idx
    INC @sp ,  X
    LDA @sp ,  X
    CMP #9
    BCC :+
    LDA #$00
    STA @sp ,  X
:
    LDA @time ,  X
    CMP #239
    BNE @final_beam_tick
    LDA sans_final_repeat
    BNE @final_beam_done
    INC sans_final_repeat
    LDA #$FF
    STA @time ,  X
    @final_beam_tick:
    JMP @tick
    @final_beam_done:
    JSR clear_hitbox
    JSR sans_erase
    JSR get_var_idx
    INC sans_final_phase
    LDA #$00
    STA @time ,  X
    JMP @tick

    ; Attack 4: horizontal bones alternate between falling left and rising right
    @hbones:
    LDA @time ,  X
    CMP #$A0
    BCS @hbones_end
    LDA @sp ,  X
    BNE @hbones_dec
    LDA #$13
    STA @sp ,  X
    LDA #$04
    STA sans_kind
    LDA @cnt ,  X
    AND #$01
    TAY
    LDA sans_hbone_x ,  Y
    TAX
    LDA sans_hbone_y ,  Y
    TAY
    LDA #HITBOX::BONE_FALL
    JSR sans_spawn
    JSR get_var_idx
    INC @cnt ,  X
    JMP @hbones_end
    @hbones_dec:
    DEC @sp ,  X
    @hbones_end:
    JSR sans_hbone_draw
    JSR get_var_idx
    LDA @time ,  X
    CMP #$D2
    BCC :+
    JSR sans_erase
    JSR get_var_idx
    LDA #$03
    STA @state ,  X
    RTS
:
    JMP @tick

    @tick:
    JSR get_var_idx
    INC @time ,  X
    RTS

    @finish:
    JSR get_var_idx
    LDA sans_final_phase
    BEQ @finish_normal
    CMP #$04
    BCS @finish_normal
    INC sans_final_phase
    LDA #$00
    STA sans_final_repeat
    STA @time ,  X
    STA @sp ,  X
    STA @cnt ,  X
    JSR clear_hitbox
    LDA #$02
    STA @state ,  X
    RTS
    @finish_normal:
    LDA sans_final_phase
    CMP #$05
    BNE :+
    LDY cur_monster_fight_pos
    LDA monster_flags ,  Y
    ORA #MONSTER_FLAG_SPARE
    STA monster_flags ,  Y
    LDX #86
    JSR play_music
    JSR get_var_idx
:
    LDA #$00
    STA @state ,  X
    INC @att ,  X
    ; after the 22 dodged strikes, Sans offers the last chance to spare
    LDA sans_turns
    CMP #22
    BCC :+
    set_menu_dialog TXT_SANS_DROP
    JSR get_var_idx
:
    mov futur_box_pos_x1 ,  #$08
    mov futur_box_pos_x2 ,  #$F6
    mov player_soul ,  #SOUL::MENU
    JSR switch_player_soul
    JSR clear_hitbox
    @end_event:
    JMP clear_event

sans_wave_top: .byte 0 ,  1 ,  2 ,  3 ,  2 ,  1
sans_wave_bot: .byte 3 ,  2 ,  1 ,  0 ,  1 ,  2
sans_bone_h: .byte 8 ,  16 ,  24 ,  32
sans_fall_x: .byte $49 ,  $90 ,  $6B ,  $B4
sans_hbone_x: .byte $42 ,  $86
sans_hbone_y: .byte $82 ,  $B6
sans_w: .byte 6 ,  6 ,  6 ,  6 ,  64
sans_h: .byte 8 ,  16 ,  24 ,  32 ,  6
sans_alo:
    .byte <ANIM_DATA_MONSTERS_SANS_SANS_BONE8 ,  <ANIM_DATA_MONSTERS_SANS_SANS_BONE16 ,  <ANIM_DATA_MONSTERS_SANS_SANS_BONE24
    .byte <ANIM_DATA_MONSTERS_SANS_SANS_BONE32 ,  <ANIM_DATA_MONSTERS_SANS_SANS_BONEH
sans_ahi:
    .byte >ANIM_DATA_MONSTERS_SANS_SANS_BONE8 ,  >ANIM_DATA_MONSTERS_SANS_SANS_BONE16 ,  >ANIM_DATA_MONSTERS_SANS_SANS_BONE24
    .byte >ANIM_DATA_MONSTERS_SANS_SANS_BONE32 ,  >ANIM_DATA_MONSTERS_SANS_SANS_BONEH

.include "beam_data.inc"
.include "rotate_data.inc"
.include "hbone_data.inc"

; Consecutive bones on the same side are 40 frames apart, longer than
; the roughly 36 frames needed to cross the box.
sans_hbone_draw:
    LDA #$FF
    STA sans_hbone_now
    STA sans_hbone_now+1
    LDX #MAX_HITBOX-1
    @find:
    LDA hitbox_t ,  X
    CMP #HITBOX::BONE_FALL
    BNE @next
    LDA hitbox_x ,  X
    CMP #$42
    BEQ @left
    CMP #$86
    BNE @next
    LDA hitbox_y ,  X
    STA sans_hbone_now+1
    JMP @next
    @left:
    LDA hitbox_y ,  X
    STA sans_hbone_now
    @next:
    DEX
    BPL @find

    LDX #$01
    @dirty:
    LDA #$00
    STA sans_hbone_dirty ,  X
    LDA sans_hbone_prev ,  X
    JSR sans_hbone_mark
    LDA sans_hbone_now ,  X
    JSR sans_hbone_mark
    STA sans_hbone_prev ,  X
    DEX
    BPL @dirty

    LDA #$00
    STA tmp+6
    @row:
    LDA #$00
    STA tmp+7
    @side:
    LDX tmp+6
    LDA sans_hbone_bits ,  X
    LDX tmp+7
    AND sans_hbone_dirty ,  X
    BEQ @skip
    JSR sans_hbone_row
    @skip:
    INC tmp+7
    LDA tmp+7
    CMP #$02
    BNE @side
    INC tmp+6
    LDA tmp+6
    CMP #$08
    BNE @row
    RTS

; Mark the tile rows covered by y and y+5. Preserve A and X.
sans_hbone_mark:
    CMP #$FF
    BEQ @done
    PHA
    SEC
    SBC #$80
    LSR
    LSR
    LSR
    TAY
    LDA sans_hbone_dirty ,  X
    ORA sans_hbone_bits ,  Y
    STA sans_hbone_dirty ,  X
    PLA
    PHA
    CLC
    ADC #5
    SEC
    SBC #$80
    LSR
    LSR
    LSR
    TAY
    LDA sans_hbone_dirty ,  X
    ORA sans_hbone_bits ,  Y
    STA sans_hbone_dirty ,  X
    PLA
    @done:
    RTS

sans_hbone_bits: .byte 1 ,  2 ,  4 ,  8 ,  16 ,  32 ,  64 ,  128

; Send one nine-tile half-row. The center tile combines both bones.
sans_hbone_row:
    LDA tmp+6
    ASL
    ASL
    ASL
    CLC
    ADC #$80
    STA tmp+11
    LDX #$01
    @state:
    LDA sans_hbone_now ,  X
    CMP #$FF
    BEQ @empty
    SEC
    SBC tmp+11
    CLC
    ADC #4
    CMP #11
    BCS @empty
    LSR
    CLC
    ADC #1
    BNE @store
    @empty:
    LDA #$00
    @store:
    STA tmp+8 ,  X
    DEX
    BPL @state

    LDA #$01
    LDX tmp+6
    BNE :+
    LDA #$00
    BEQ :++
:
    CPX #$07
    BNE :+
    LDA #$02
:
    STA tmp+10
    TAX
    LDA sans_hbone_center_lo ,  X
    STA tmp+4
    LDA sans_hbone_center_hi ,  X
    STA tmp+5
    LDA tmp+8
    ASL
    ASL
    ASL
    SEC
    SBC tmp+8
    CLC
    ADC tmp+9
    TAY
    LDA (tmp+4) ,  Y
    STA tmp+12

    LDA tmp+10
    ASL
    CLC
    ADC tmp+7
    TAX
    LDA sans_hbone_table_lo ,  X
    STA tmp+2
    LDA sans_hbone_table_hi ,  X
    STA tmp+3
    LDX tmp+7
    LDA tmp+8 ,  X
    ASL
    ASL
    ASL
    TAY
    mov_ptr tmp+0 ,  packet_buffer_end
    LDA #$49
    STY tmp+13
    LDY #$00
    STA (tmp+0) ,  Y
    INY
    LDA #$22
    STA (tmp+0) ,  Y
    INY
    LDA tmp+6
    ASL
    ASL
    ASL
    ASL
    ASL
    CLC
    ADC #$08
    LDX tmp+7
    BEQ :+
    ADC #$08
:
    STA (tmp+0) ,  Y
    INY
    LDX tmp+7
    BEQ :+
    LDA tmp+12
    STA (tmp+0) ,  Y
    INY
:
    STY tmp+14
    LDY tmp+13
    LDX #$08
    @tile:
    LDA (tmp+2) ,  Y
    STY tmp+13
    LDY tmp+14
    STA (tmp+0) ,  Y
    INC tmp+14
    LDY tmp+13
    INY
    DEX
    BNE @tile
    LDY tmp+14
    LDA tmp+7
    BNE :+
    LDA tmp+12
    STA (tmp+0) ,  Y
    INY
:
    LDA #SANS_HBONE_CHR
    LDX #$09
    @attr:
    STA (tmp+0) ,  Y
    INY
    DEX
    BNE @attr
    TYA
    add_A2ptr packet_buffer_end
    RTS

; tmp+8 points to a 17 x 8 tile image, including the box border.
sans_beam_draw:
    LDA #SANS_BEAM_CHR
    STA tmp+10
sans_box_draw:
    mov_ptr tmp+4 ,  packet_buffer_end
    sta_ptr tmp+0 ,  $2208
    LDX #$08
    @row:
    LDY #$00
    LDA #$51
    STA (tmp+4) ,  Y
    INY
    LDA tmp+1
    STA (tmp+4) ,  Y
    INY
    LDA tmp+0
    STA (tmp+4) ,  Y
    LDA #$03
    add_A2ptr tmp+4
    LDY #$00
    @tiles:
        LDA (tmp+8) ,  Y
        STA (tmp+4) ,  Y
        INY
        CPY #17
        BNE @tiles
    TYA
    add_A2ptr tmp+8
    LDA #17
    add_A2ptr tmp+4
    LDY #$00
    LDA tmp+10
    @attributes:
        STA (tmp+4) ,  Y
        INY
        CPY #17
        BNE @attributes
    TYA
    add_A2ptr tmp+4
    LDA #$20
    add_A2ptr tmp+0
    DEX
    BNE @row
    mov_ptr packet_buffer_end ,  tmp+4
    RTS

; Rectangles are generated from the same PNG as the visible beam.
sans_beam_hitboxes:
    @next:
    LDY #$00
    LDA (tmp+8) ,  Y
    CMP #$FF
    BEQ @done
    CLC
    ADC #60
    STA sans_x
    INY
    LDA (tmp+8) ,  Y
    CLC
    ADC #126
    STA sans_y
    INY
    LDA (tmp+8) ,  Y
    CLC
    ADC sans_x
    ADC #1
    STA tmp+11
    INY
    LDA (tmp+8) ,  Y
    CLC
    ADC sans_y
    STA tmp+12
    LDA #$04
    add_A2ptr tmp+8
    LDX sans_x
    LDY sans_y
    LDA #HITBOX::BLOCK
    JSR new_hitbox
    CPY #$FF
    BEQ @done
    LDA tmp+11
    STA hitbox_w ,  Y
    LDA tmp+12
    STA hitbox_h ,  Y
    JMP @next
    @done:
    RTS

sans_erase:
    sta_ptr tmp+8 ,  sans_box_tiles
    LDA #UI_CHR_BNK + $80
    STA tmp+10
    JMP sans_box_draw

sans_box_tiles:
    .byte DIALOG_BOX_TILE_TL
    .repeat 15
    .byte DIALOG_BOX_TILE_TOP
    .endrepeat
    .byte DIALOG_BOX_TILE_TR
    .repeat 6
    .byte DIALOG_BOX_TILE_LEFT
    .repeat 15
    .byte DIALOG_BOX_TILE_MIDDLE
    .endrepeat
    .byte DIALOG_BOX_TILE_RIGHT
    .endrepeat
    .byte DIALOG_BOX_TILE_BL
    .repeat 15
    .byte DIALOG_BOX_TILE_BOT
    .endrepeat
    .byte DIALOG_BOX_TILE_BR

; A = hitbox type, X = x, Y = y, sans_kind = anim kind; returns Y = hitbox idx
sans_spawn:
    STX sans_x
    STY sans_y
    LDX sans_x
    LDY sans_y
    JSR new_hitbox
    CPY #$FF
    BEQ @done
    LDX sans_kind
    LDA sans_w ,  X
    CLC
    ADC hitbox_x ,  Y
    STA hitbox_w ,  Y
    LDA sans_h ,  X
    CLC
    ADC hitbox_y ,  Y
    STA hitbox_h ,  Y
    CPX #$04
    BEQ @done
    LDA sans_alo ,  X
    STA tmp+0
    LDA sans_ahi ,  X
    STA tmp+1
    JSR add_anim
    CPX #$FF
    BNE :+
    LDA #$00
    STA hitbox_t ,  Y
    RTS
:
    INX
    TXA
    STA hitbox_a ,  Y
    TYA
    TAX
    LDA hitbox_a ,  X
    TAY
    DEY
    JSR shift_entity_spr
    @done:
    RTS

m_4_custom:
m_4_hit:
    JMP clear_event

m_4_act:
    @act_wait = monster_vars+2
    JSR get_var_idx
    LDA @act_wait ,  X
    BNE @wait
    INC @act_wait ,  X
    call_read_dialog TXT_SANS_CHECK
    RTS
    @wait:
    LDA n_dialog
    BNE @end
    JSR get_var_idx
    LDA #$00
    STA @act_wait ,  X
    JMP clear_event
    @end:
    RTS

m_4_item:
    JMP clear_event

m_4_spare:
    @spare_wait = monster_vars+2
    JSR get_var_idx
    LDA @spare_wait ,  X
    BNE @spare_wait_dialog
    LDY cur_monster_fight_pos
    LDA monster_flags ,  Y
    AND #MONSTER_FLAG_SPARE
    BNE @spare_win
    INC @spare_wait ,  X
    call_read_dialog TXT_SANS_SPARE_NOT_READY
    RTS
    @spare_wait_dialog:
    LDA n_dialog
    BNE @spare_end
    JSR get_var_idx
    LDA #$00
    STA @spare_wait ,  X
    JMP clear_event
    @spare_end:
    RTS
    @spare_win:
    LDA #$02
    JSR run_scene
    JMP begin_battle_victory

m_4_flee:
    JMP clear_event

sans_act_txt:
.byte $01
.byte FONT_CHR_BNK ,  "* Check" ,  $00 ,  "       "

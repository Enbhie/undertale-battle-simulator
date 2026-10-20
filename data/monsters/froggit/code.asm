start:
    set_menu_dialog TXT_FROGGIT_START
    mov player_soul, #SOUL::MENU
    JSR switch_player_soul

    display_anim ANIM_DATA_MONSTERS_FROGGIT_FROGGIT_BKG

    sta_ptr tmp+2, froggit_act_txt
    JSR init_monster_act

    JSR get_var_idx
    LDA #$00
    STA monster_vars+0, X
    STA monster_vars+1, X
    STA monster_vars+2, X

    JMP clear_event

turn:
    @turn_state = monster_vars+0
    @turn_time = monster_vars+1

    LDA cur_monster_fight_pos
    BEQ :+
    JMP @end_event
:

    JSR get_var_idx
    LDA @turn_state, X
    BNE @attack_wait

    LDA #$E0
    STA @turn_time+0, X
    LDA #$01
    STA @turn_time+1, X
    INC @turn_state, X
    JSR clear_main_box
    JSR text_post_process
    mov player_soul, #SOUL::RED
    JSR switch_player_soul
    mov futur_box_pos_x1, #$40
    mov futur_box_pos_x2, #$C6
    RTS

    @attack_wait:
    CMP #$01
    BNE @attack
    LDA dialogbox_anim_flag
    BNE @end
    INC @turn_state, X
    RTS

    @attack:
    CMP #$02
    BNE @end_event
    LDA @turn_time+0, X
    AND #$3F
    BNE @tick
    phx
    JSR rng
    AND #$7F
    add #$40
    TAX
    LDY #$80
    LDA #HITBOX::FOLLOW_DIAMOND
    JSR new_hitbox
    CPY #$FF
    BEQ @spawn_done
    TXA
    add #$03
    STA hitbox_w, Y
    LDA #$83
    STA hitbox_h, Y
    LDA #<ANIM_DATA_MONSTERS_TESTOBUG_ANIMS_SPR_0
    STA tmp+0
    LDA #>ANIM_DATA_MONSTERS_TESTOBUG_ANIMS_SPR_0
    STA tmp+1
    JSR add_anim
    CMP #$FF
    BNE :+
    LDA #$00
    STA hitbox_t, Y
    BNE @spawn_done
:
    INX
    TXA
    STA hitbox_a, Y
    @spawn_done:
    plx

    @tick:
    dcx_16 @turn_time
    LDA @turn_time+1, X
    BNE @end
    LDA @turn_time+0, X
    BNE @end
    LDA #$00
    STA @turn_state, X
    mov futur_box_pos_x1, #$08
    mov futur_box_pos_x2, #$F6
    mov player_soul, #SOUL::MENU
    JSR switch_player_soul
    JSR clear_hitbox

    @end_event:
    JMP clear_event
    @end:
    RTS

custom:
hit:
    JMP clear_event

act:
    @act_wait = monster_vars+2
    JSR get_var_idx
    LDA @act_wait, X
    BNE @wait
    INC @act_wait, X
    LDA act_choice
    BNE @compliment
    call_read_dialog TXT_FROGGIT_CHECK
    RTS

    @compliment:
    call_read_dialog TXT_FROGGIT_ACT_COMPLIMENT
    LDX cur_monster_fight_pos
    LDA monster_flags, X
    ORA #MONSTER_FLAG_SPARE
    STA monster_flags, X
    RTS

    @wait:
    LDA n_dialog
    BNE @end
    JSR get_var_idx
    LDA #$00
    STA @act_wait, X
    JMP clear_event
    @end:
    RTS

item:
spare:
flee:
    JMP clear_event

froggit_act_txt:
.byte $02
.byte FONT_CHR_BNK, "* Check", $00, "       "
.byte FONT_CHR_BNK, "* Compliment", $00, "   "

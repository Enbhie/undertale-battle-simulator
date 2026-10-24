;--------------------------------
; Battle exit transition
;--------------------------------
;
; The NES cannot alpha blend an individual monster.  Fade the battle palette
; through a dim pass to black, then rebuild the encounter-selection screen.
;
begin_battle_exit:
    LDA battle_exit_state
    BNE @end

    LDA #$01
    STA battle_exit_state
    LDA #$00
    STA battle_exit_timer
    STA n_dialog
    STA item_adr
    STA item_adr+1
    STA player_flag
    STA monster_0_event
    STA monster_1_event
    STA monster_2_event

    JSR clear_hitbox

    for_x @clear_anims, #MAX_ANIM-1
        LDA #$00
        STA anims_flag, X
    to_x_dec @clear_anims, #0

    mov player_soul, #SOUL::WAIT
@end:
    RTS


begin_boss_chain_transition:
    LDA #$01
    STA boss_chain_anim_state
    LDA #$00
    STA n_dialog
    STA player_flag
    STA fight_state
    STA fight_timer
    STA fight_damage
    STA fight_markpos
    STA item_adr+0
    STA item_adr+1
    STA item_var
    STA monster_0_event
    STA monster_1_event
    STA monster_2_event
    mov player_soul, #SOUL::WAIT

    JSR clear_hitbox

    for_x @clear_anims, #MAX_ANIM-1
        LDA #$00
        STA anims_flag, X
    to_x_dec @clear_anims, #0

    LDA boss_chain_stage
    CMP #$01
    BNE @snake_transition
        display_anim ANIM_DATA_MONSTERS_CHAIN_EAT_GRASSHOPPER_0
        RTS

    @snake_transition:
        display_anim ANIM_DATA_MONSTERS_CHAIN_EAT_FROGGIT_0
        RTS


; Return A = 0 while normal battle processing may continue, nonzero otherwise.
update_battle_exit:
    LDA boss_chain_anim_state
    BEQ @normal_exit

    LDX #MAX_ANIM-1
    @wait_for_chain_anim:
        LDA anims_flag, X
        BMI @chain_active
        DEX
        BPL @wait_for_chain_anim

    LDA boss_chain_stage
    CMP #$01
    BNE @load_snake
        LDA #$02
        STA boss_chain_stage
        LDA #$02
        STA fight_id
        JMP @load_chain_boss
    @load_snake:
        LDA #$03
        STA boss_chain_stage
        LDA #$05
        STA fight_id

    @load_chain_boss:
        LDA #$00
        STA boss_chain_round
        JSR clear_chain_battle_state
        JSR clear_main_box
        JSR load_fight
        LDA #SOUL::WAIT
        STA player_soul
        LDA #(PLAYER_FLAG_DRAW_HP + PLAYER_FLAG_DRAW_PLAYER)
        STA player_flag
        LDA #$00
        STA boss_chain_anim_state
        LDA #$01
        RTS

    @chain_active:
        LDA #$00
        RTS

    @normal_exit:
    LDA battle_exit_state
    BEQ @done

    INC battle_exit_timer
    LDA battle_exit_timer
    CMP #$08
    BCC @active

    LDA #$00
    STA battle_exit_timer
    INC battle_exit_state
    LDA battle_exit_state
    CMP #$02
    BEQ @dim
    CMP #$03
    BEQ @black
    CMP #$04
    BEQ @restart

@active:
    LDA #$01
    RTS

@dim:
    for_x @copy_dim, #$00
        LDA battle_exit_dim_palette, X
        STA palettes, X
    to_x_inc @copy_dim, #25
    JMP @send_palette

@black:
    for_x @copy_black, #$00
        LDA #$0F
        STA palettes, X
    to_x_inc @copy_black, #25

@send_palette:
    ora_adr nmi_flags, #NMI_PLT
    JMP @active

@restart:
    LDA #$00
    STA PPU_MASK
    JSR INIT
    LDA #$00
    STA battle_exit_state
    RTS

@done:
    LDA #$00
    RTS


clear_chain_battle_state:
    LDA #$00
    STA fight_state
    STA fight_timer
    STA fight_damage
    STA fight_markpos
    STA item_adr+0
    STA item_adr+1
    STA item_var

    for_x @clear_monsters, #$02
        LDA #$00
        STA monster_events, X
        STA monster_last_events, X
        STA monster_flags, X
        STA monster_act_str_size, X
    to_x_dec @clear_monsters, #0

    for_x @clear_vars, #MONSTER_VAR_SIZE*3-1
        LDA #$00
        STA monster_vars, X
    to_x_dec @clear_vars, #-1

    JSR clear_hitbox
    RTS


battle_exit_dim_palette:
    .byte $0F
    .byte $10, $0F, $10
    .byte $0F, $10, $10
    .byte $06, $18, $10
    .byte $07, $0F, $0F
    .byte $10, $0F, $06
    .byte $06, $0F, $0F
    .byte $0F, $0F, $0F
    .byte $0F, $0F, $0F

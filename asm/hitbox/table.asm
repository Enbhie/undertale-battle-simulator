.segment "MONSTER_DATA"

hitbox_call_table_move_lo:
    .byte <(call_hitbox_none-1)
    .byte <(call_hitbox_move_diamond-1)
    .byte <(call_hitbox_move_falling_diamond-1)
.repeat 254
    .byte <(call_hitbox_none-1)
.endrepeat

hitbox_call_table_move_hi:
    .byte >(call_hitbox_none-1)
    .byte >(call_hitbox_move_diamond-1)
    .byte >(call_hitbox_move_falling_diamond-1)
.repeat 254
    .byte >(call_hitbox_none-1)
.endrepeat


hitbox_call_table_hit_lo:
    .byte <(call_hitbox_none-1)
    .byte <(call_hitbox_hit_diamond-1)
.repeat 254
    .byte <(call_hitbox_none-1)
.endrepeat

hitbox_call_table_hit_hi:
    .byte >(call_hitbox_none-1)
    .byte >(call_hitbox_hit_diamond-1)
.repeat 254
    .byte >(call_hitbox_none-1)
.endrepeat


call_hitbox_none:
    RTS


call_hitbox_move_diamond:
    LDA frame_counter
    LSR
    BCS @end

    LDA hitbox_x, X
    CMP player_x
    blt :+
        DEC hitbox_x, X
        DEC hitbox_w, X
        JMP :++
    :
        INC hitbox_x, X
        INC hitbox_w, X
    :

    LDA hitbox_y, X
    CMP player_y
    blt :+
        DEC hitbox_y, X
        DEC hitbox_h, X
        JMP :++
    :
        INC hitbox_y, X
        INC hitbox_h, X
    :

    @end:
    RTS


; Move downward at a fixed speed. It deliberately never reads player_x/player_y.
call_hitbox_move_falling_diamond:
    LDA frame_counter
    LSR
    BCS @end

    INC hitbox_y, X
    INC hitbox_h, X
    LDA hitbox_y, X
    CMP player_bound_y2
    blt @end
    JMP remove_hitbox

@end:
    RTS


call_hitbox_hit_diamond:
    LDA player_stats + PlayerStat::hp
    BEQ @remove
    DEC player_stats + PlayerStat::hp
    ora_adr player_flag, #PLAYER_FLAG_DRAW_HP
@remove:
    JMP remove_hitbox


.segment "LAST_BNK"

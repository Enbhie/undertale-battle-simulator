; Soul Dodge - 16-bit DOS version for MASM or TASM.
; Survive timed obstacle rounds between five progressively harder bosses.
; Move with WASD or the arrow keys, attack with Space, and quit with Q.

.8086
.MODEL SMALL
.STACK 100h

BATTLE_W     EQU 30
BATTLE_H     EQU 12
BULLET_COUNT EQU 32
BASE_ROUND_TICKS EQU 375
UFO_SPAWN_TICKS EQU 125
UFO_LIFE_TICKS EQU 63
UFO_MOVE_TICKS EQU 4
UFO_FIRE_TICKS EQU 15
SCREEN_LEFT  EQU 24
SCREEN_TOP   EQU 5
PANEL_LEFT   EQU 14
PANEL_WIDTH  EQU 52

.DATA
player_x       db 15
player_y       db 9
hp             db 20
ticks          dw 0
round_ticks    dw BASE_ROUND_TICKS
timer_value    dw 0
game_state     db 0
spawn_clock    db 0
wave_clock     db 0
gap_start      db 0
wave_column    db 0
spawn_column   db 0
key_scan       db 0
rng            dw 0
fallback_low   dw 0
fallback_target dw 1
fallback_phase db 0
row_index      db 0
boss_index     db 0
next_boss      db 1
boss_hp        db 0
boss_max_hp    db 0
boss_cooldown  db 0
bullet_move_clock db 0
boss_x         db 10
boss_direction db 1
boss_move_clock db 0
boss_hit_flash db 0
player_shot_x  db 0
player_shot_y  db 0FFh
boss_move_rates db 4, 3, 2, 2, 1
recovery_x     db 0
recovery_y     db 0FFh
recovery_clock db 0
recovery_rates db 80, 75, 70, 65, 60
ufo_x          db 0
ufo_y          db 0
ufo_direction_x db 0
ufo_direction_y db 0
ufo_move_clock db 0
ufo_shot_clock db 0
ufo_spawn_clock dw 0
ufo_life        db 0
ufo_shot_x      db 0
ufo_shot_y      db 0FFh
gap_width      db 4
timer_text     db "300"
hp_text        db "20/20"
boss_hp_text   db "08/08"
single_char    db "*"
shot_char      db "^"
recovery_char  db 3
ufo_art        db "<=>"
ufo_shot_char  db "!"
side_row       db "|",30 dup(" "),"|"
arena_border   db "+",30 dup("-"),"+"

title_text     db "SOUL DODGE - SURVIVE THE NIGHT"
title_len      EQU $-title_text
boss_title_1   db "I  EASY - WISP OF CINDERS"
boss_title_1_len EQU $-boss_title_1
boss_title_2   db "II  FAIR - BRAMBLE JACK"
boss_title_2_len EQU $-boss_title_2
boss_title_3   db "III  NORMAL - MIRROR MOTH"
boss_title_3_len EQU $-boss_title_3
boss_title_4   db "IV  HARD - CLOCKWORK CROW"
boss_title_4_len EQU $-boss_title_4
boss_title_5   db "V  FINAL - OBSIDIAN CROWN"
boss_title_5_len EQU $-boss_title_5
boss_title_ptrs dw OFFSET boss_title_1, OFFSET boss_title_2
               dw OFFSET boss_title_3, OFFSET boss_title_4
               dw OFFSET boss_title_5
boss_title_lengths db boss_title_1_len, boss_title_2_len
               db boss_title_3_len, boss_title_4_len
               db boss_title_5_len
boss_art_1     db "   .^.   "
boss_art_2     db "  [###]  "
boss_art_3     db "  (o.o)  "
boss_art_4     db "  <###>  "
boss_art_5     db "  /X X\  "
boss_hit_art   db "!! HIT !!"
boss_art_ptrs  dw OFFSET boss_art_1, OFFSET boss_art_2
               dw OFFSET boss_art_3, OFFSET boss_art_4
               dw OFFSET boss_art_5
boss_art_len   EQU 9
boss_taunt_1   db "* A warm spark drifts down."
boss_taunt_1_len EQU $-boss_taunt_1
boss_taunt_2   db "* Brambles sweep across the box!"
boss_taunt_2_len EQU $-boss_taunt_2
boss_taunt_3   db "* The mirrors split the stars."
boss_taunt_3_len EQU $-boss_taunt_3
boss_taunt_4   db "* The gears are speeding up!"
boss_taunt_4_len EQU $-boss_taunt_4
boss_taunt_5   db "* The Crown leaves no safe place."
boss_taunt_5_len EQU $-boss_taunt_5
boss_taunt_ptrs dw OFFSET boss_taunt_1, OFFSET boss_taunt_2
               dw OFFSET boss_taunt_3, OFFSET boss_taunt_4
               dw OFFSET boss_taunt_5
boss_taunt_lengths db boss_taunt_1_len, boss_taunt_2_len
               db boss_taunt_3_len, boss_taunt_4_len
               db boss_taunt_5_len
boss_attack_rates db 6, 5, 4, 3, 2
boss_wave_rates   db 48, 40, 32, 26, 20
obstacle_spawn_rates db 8, 6, 5, 4, 3
obstacle_wave_rates db 100, 90, 80, 70, 60
obstacle_fall_rates db 3, 2, 2, 1, 1
boss_health_values db 8, 10, 12, 14, 16
boss_gap_widths    db 8, 7, 6, 5, 4
boss_hp_label  db "BOSS HP:"
boss_hp_label_len EQU $-boss_hp_label
boss_player_hp_label db "HP:"
boss_player_hp_label_len EQU $-boss_player_hp_label
boss_player_hp_text db "20"
attack_hint    db "Press SPACE to strike while dodging."
attack_hint_len EQU $-attack_hint
lv_label       db "LV 1"
lv_label_len   EQU $-lv_label
hp_label       db "HP"
hp_label_len   EQU $-hp_label
time_label     db "TIME: "
time_label_len EQU $-time_label
time_suffix    db " / 030"
time_suffix_len EQU $-time_suffix
health_bar     db 20 dup (219)
dialog_border  db "+",50 dup("-"),"+"
dialog_side    db "|",50 dup(" "),"|"
dialog_text    db "* The bones are falling!"
dialog_text_len EQU $-dialog_text
dialog_hint    db "Find the four-cell gap to survive."
dialog_hint_len EQU $-dialog_hint
controls_text  db "MOVE: ARROWS / WASD   SPACE: ATTACK"
controls_len   EQU $-controls_text
win_text       db "* All five challengers are defeated!"
win_text_len   EQU $-win_text
lose_text      db "* Your soul has fallen..."
lose_text_len  EQU $-lose_text
end_hint       db "PRESS R TO TRY AGAIN       Q: QUIT"
end_hint_len   EQU $-end_hint
bullet_x       db BULLET_COUNT dup (0)
bullet_y       db BULLET_COUNT dup (0FFh)

.CODE

start PROC
  mov ax, @data
  mov ds, ax

  ; Seed the random generator and prepare the BIOS-timer fallback.
  mov ah, 00h
  int 1Ah
  mov fallback_low, dx
  mov ax, dx
  xor ax, cx
  or ax, 1
  mov rng, ax

  mov ax, 0003h
  int 10h
  mov ah, 01h
  mov ch, 20h
  mov cl, 00h
  int 10h

  call reset_game
  call render_game

Game_Loop:
  call read_input
  call update_game
  cmp hp, 0
  jne Game_Check_Win
  mov game_state, 2
  call render_game
  jmp Game_Finished

Game_Check_Win:
  cmp game_state, 1
  je Game_Show_End
  cmp boss_index, 0
  jne Game_Continue
  mov ax, ticks
  cmp ax, round_ticks
  jb Game_Continue
  call begin_boss
  jmp Game_Continue

Game_Show_End:
  mov game_state, 1
  call render_game
  jmp Game_Finished

Game_Continue:
  call render_game
  call wait_tick
  jmp Game_Loop

Game_Finished:
  mov ah, 00h
  int 16h
  cmp al, "q"
  je Game_Exit
  cmp al, "Q"
  je Game_Exit
  cmp al, "r"
  je Game_Restart
  cmp al, "R"
  jne Game_Finished

Game_Restart:
  call reset_game
  call render_game
  jmp Game_Loop

Game_Exit:
  mov ax, 0003h
  int 10h
  mov ax, 4C00h
  int 21h
start ENDP

reset_game PROC NEAR
  mov player_x, 15
  mov player_y, 9
  mov hp, 20
  mov word ptr ticks, 0
  mov round_ticks, BASE_ROUND_TICKS
  mov game_state, 0
  mov boss_index, 0
  mov next_boss, 1
  mov boss_hp, 0
  mov boss_max_hp, 0
  mov boss_cooldown, 0
  mov bullet_move_clock, 0
  mov boss_x, 10
  mov boss_direction, 1
  mov boss_move_clock, 0
  mov boss_hit_flash, 0
  mov player_shot_y, 0FFh
  mov recovery_x, 0
  mov recovery_y, 0FFh
  mov recovery_clock, 0
  mov ufo_x, 0
  mov ufo_y, 0
  mov ufo_direction_x, 0
  mov ufo_direction_y, 0
  mov ufo_move_clock, 0
  mov ufo_shot_clock, 0
  mov ufo_spawn_clock, 0
  mov ufo_life, 0
  mov ufo_shot_y, 0FFh
  mov gap_width, 4
  mov spawn_clock, 0
  mov wave_clock, 0
  mov gap_start, 0
  mov wave_column, 0
  mov spawn_column, 0
  mov row_index, 0
  mov byte ptr timer_text, "3"
  mov byte ptr timer_text+1, "0"
  mov byte ptr timer_text+2, "0"
  mov byte ptr hp_text, "2"
  mov byte ptr hp_text+1, "0"
  mov si, 0
Reset_Bullets:
  mov byte ptr bullet_y[si], 0FFh
  inc si
  cmp si, BULLET_COUNT
  jb Reset_Bullets
  ret
reset_game ENDP

begin_boss PROC NEAR
  mov al, next_boss
  mov boss_index, al
  call setup_boss
  ret
begin_boss ENDP

defeat_boss PROC NEAR
  cmp boss_index, 5
  jae Boss_Rush_Won
  inc next_boss
  mov hp, 20
  call start_survival_round
  ret
Boss_Rush_Won:
  mov hp, 20
  mov boss_index, 6
  mov game_state, 1
  ret
defeat_boss ENDP

start_survival_round PROC NEAR
  mov boss_index, 0
  mov word ptr ticks, 0
  mov al, next_boss
  xor ah, ah
  mov bx, BASE_ROUND_TICKS
  mul bx
  mov round_ticks, ax
  mov spawn_clock, 0
  mov wave_clock, 0
  mov bullet_move_clock, 0
  mov recovery_clock, 0
  mov recovery_y, 0FFh
  mov player_shot_y, 0FFh
  mov ufo_spawn_clock, 0
  mov ufo_life, 0
  mov ufo_move_clock, 0
  mov ufo_shot_clock, 0
  mov ufo_shot_y, 0FFh
  mov si, 0
Survival_Clear_Bullets:
  mov byte ptr bullet_y[si], 0FFh
  inc si
  cmp si, BULLET_COUNT
  jb Survival_Clear_Bullets
  ret
start_survival_round ENDP

setup_boss PROC NEAR
  mov al, boss_index
  dec al
  xor ah, ah
  mov bx, ax
  mov al, boss_health_values[bx]
  mov boss_hp, al
  mov boss_max_hp, al
  mov al, boss_gap_widths[bx]
  mov gap_width, al
  mov boss_x, 10
  mov boss_direction, 1
  mov boss_move_clock, 0
  mov boss_hit_flash, 0
  mov boss_cooldown, 0
  mov bullet_move_clock, 0
  mov player_shot_y, 0FFh
  mov recovery_x, 0
  mov recovery_y, 0FFh
  mov recovery_clock, 0
  mov ufo_life, 0
  mov ufo_shot_y, 0FFh
  mov spawn_clock, 0
  mov wave_clock, 0
  mov si, 0
Setup_Boss_Clear_Bullets:
  mov byte ptr bullet_y[si], 0FFh
  inc si
  cmp si, BULLET_COUNT
  jb Setup_Boss_Clear_Bullets
  ret
setup_boss ENDP

read_input PROC NEAR
Input_Next:
  mov ah, 01h
  int 16h
  jnz Input_Have_Key
  jmp Input_Done
Input_Have_Key:
  mov ah, 00h
  int 16h
  mov key_scan, ah
  or al, 20h
  cmp al, "q"
  jne Input_Not_Quit
  jmp Input_Quit
Input_Not_Quit:
  cmp al, " "
  je Input_Attack
  cmp al, "a"
  je Input_Left
  cmp key_scan, 4Bh
  je Input_Left
  cmp al, "d"
  je Input_Right
  cmp key_scan, 4Dh
  je Input_Right
  cmp al, "w"
  je Input_Up
  cmp key_scan, 48h
  je Input_Up
  cmp al, "s"
  je Input_Down
  cmp key_scan, 50h
  jne Input_Next
  jmp Input_Down

Input_Left:
  cmp player_x, 0
  je Input_Next
  dec player_x
  jmp Input_Next
Input_Right:
  cmp player_x, BATTLE_W-1
  jae Input_Next
  inc player_x
  jmp Input_Next
Input_Up:
  cmp player_y, 0
  je Input_Next
  dec player_y
  jmp Input_Next
Input_Down:
  cmp player_y, BATTLE_H-1
  jae Input_Next
  inc player_y
  jmp Input_Next
Input_Attack:
  cmp boss_index, 0
  jne Input_Attack_Check_Stage
  jmp Input_Next
Input_Attack_Check_Stage:
  cmp boss_index, 6
  jb Input_Attack_Check_Cooldown
  jmp Input_Next
Input_Attack_Check_Cooldown:
  cmp boss_cooldown, 0
  je Input_Attack_Ready
  jmp Input_Next
Input_Attack_Ready:
  cmp player_shot_y, 0FFh
  je Input_Attack_Fire
  jmp Input_Next
Input_Attack_Fire:
  mov al, player_x
  mov player_shot_x, al
  mov al, player_y
  mov player_shot_y, al
  mov boss_cooldown, 4
  jmp Input_Next
Input_Quit:
  jmp Game_Exit
Input_Done:
  ret
read_input ENDP

update_game PROC NEAR
  cmp boss_index, 6
  jb Update_Stage_Active
  ret
Update_Stage_Active:
  cmp boss_index, 0
  jne Update_Boss_Clock
  inc word ptr ticks
  jmp Update_Clock_Done
Update_Boss_Clock:
  cmp boss_cooldown, 0
  je Update_Clock_Done
  dec boss_cooldown
Update_Clock_Done:

  call update_recovery

  cmp boss_index, 0
  jne Update_UFO_Done
  cmp next_boss, 4
  jb Update_UFO_Done
  call update_ufo
Update_UFO_Done:

  cmp boss_index, 0
  je Update_Player_Shot
  cmp boss_hit_flash, 0
  je Update_Boss_Movement
  dec boss_hit_flash
Update_Boss_Movement:
  inc boss_move_clock
  mov al, boss_index
  dec al
  xor ah, ah
  mov bx, ax
  mov al, boss_move_rates[bx]
  cmp boss_move_clock, al
  jb Update_Player_Shot
  mov boss_move_clock, 0
  cmp boss_direction, 0
  je Update_Boss_Move_Left
  cmp boss_x, BATTLE_W-boss_art_len
  jae Update_Boss_Turn_Left
  inc boss_x
  jmp Update_Player_Shot
Update_Boss_Turn_Left:
  mov boss_direction, 0
  jmp Update_Player_Shot
Update_Boss_Move_Left:
  cmp boss_x, 0
  je Update_Boss_Turn_Right
  dec boss_x
  jmp Update_Player_Shot
Update_Boss_Turn_Right:
  mov boss_direction, 1

Update_Player_Shot:
  cmp player_shot_y, 0FFh
  je Update_Bullets_Start
  cmp player_shot_y, 0
  je Update_Check_Boss_Hit
  dec player_shot_y
  cmp player_shot_y, 0
  jne Update_Bullets_Start
Update_Check_Boss_Hit:
  mov al, boss_x
  cmp player_shot_x, al
  jb Update_Player_Shot_Missed
  add al, boss_art_len
  cmp player_shot_x, al
  jae Update_Player_Shot_Missed
  dec boss_hp
  mov boss_hit_flash, 5
  mov player_shot_y, 0FFh
  cmp boss_hp, 0
  jne Update_Bullets_Start
  call defeat_boss
  ret
Update_Player_Shot_Missed:
  mov player_shot_y, 0FFh

  ; Move existing bullets down and release slots that leave the arena.
Update_Bullets_Start:
  inc bullet_move_clock
  mov al, next_boss
  dec al
  xor ah, ah
  mov bx, ax
  mov al, obstacle_fall_rates[bx]
  cmp bullet_move_clock, al
  jae Update_Move_Obstacles
  jmp Update_Waves
Update_Move_Obstacles:
  mov bullet_move_clock, 0
  mov si, 0
Update_Bullets:
  mov al, bullet_y[si]
  cmp al, 0FFh
  je Update_Next_Bullet
  inc bullet_y[si]
  cmp byte ptr bullet_y[si], BATTLE_H
  jb Update_Next_Bullet
  mov byte ptr bullet_y[si], 0FFh
Update_Next_Bullet:
  inc si
  cmp si, BULLET_COUNT
  jb Update_Bullets

  ; The returning obstacle rounds spawn attacks more frequently.
  inc spawn_clock
  cmp boss_index, 0
  jne Update_Boss_Attack_Rate
  mov al, next_boss
  dec al
  xor ah, ah
  mov bx, ax
  mov al, obstacle_spawn_rates[bx]
  jmp Update_Check_Spawn
Update_Boss_Attack_Rate:
  mov al, boss_index
  dec al
  xor ah, ah
  mov bx, ax
  mov al, boss_attack_rates[bx]
Update_Check_Spawn:
  cmp spawn_clock, al
  jb Update_Waves
  mov spawn_clock, 0
  call random_word
  xor dx, dx
  mov bx, BATTLE_W
  div bx
  mov al, dl
  call spawn_bullet

Update_Waves:
  inc wave_clock
  cmp boss_index, 0
  jne Update_Boss_Wave_Rate
  mov al, next_boss
  dec al
  xor ah, ah
  mov bx, ax
  mov al, obstacle_wave_rates[bx]
  jmp Update_Check_Wave
Update_Boss_Wave_Rate:
  mov al, boss_index
  dec al
  xor ah, ah
  mov bx, ax
  mov al, boss_wave_rates[bx]
Update_Check_Wave:
  cmp wave_clock, al
  jb Update_Collisions
  mov wave_clock, 0
  call spawn_wave

Update_Collisions:
  mov si, 0
Collision_Loop:
  mov al, bullet_y[si]
  cmp al, 0FFh
  je Collision_Next
  cmp al, player_y
  jne Collision_Next
  mov al, bullet_x[si]
  cmp al, player_x
  jne Collision_Next
  mov byte ptr bullet_y[si], 0FFh
  dec hp
  jz Collision_Done
Collision_Next:
  inc si
  cmp si, BULLET_COUNT
  jb Collision_Loop
Collision_Done:
  ret
update_game ENDP

update_recovery PROC NEAR
  cmp recovery_y, 0FFh
  je Recovery_Try_Spawn

  mov al, recovery_y
  cmp al, player_y
  jne Recovery_Move_Down
  mov al, recovery_x
  cmp al, player_x
  jne Recovery_Move_Down
  cmp hp, 20
  jae Recovery_Move_Down

  mov byte ptr recovery_y, 0FFh
  mov recovery_clock, 0
  cmp hp, 17
  jae Recovery_Heal_To_Max
  add hp, 3
  ret
Recovery_Heal_To_Max:
  mov hp, 20
  ret

Recovery_Move_Down:
  inc recovery_y
  cmp recovery_y, BATTLE_H
  jb Recovery_Done
  mov byte ptr recovery_y, 0FFh
  mov recovery_clock, 0
  ret

Recovery_Try_Spawn:
  inc recovery_clock
  mov al, 100
  cmp boss_index, 0
  je Recovery_Check_Rate
  mov al, boss_index
  dec al
  xor ah, ah
  mov bx, ax
  mov al, recovery_rates[bx]
Recovery_Check_Rate:
  cmp recovery_clock, al
  jb Recovery_Done
  mov recovery_clock, 0
  call random_word
  xor dx, dx
  mov bx, BATTLE_W
  div bx
  mov recovery_x, dl
  mov recovery_y, 0
Recovery_Done:
  ret
update_recovery ENDP

update_ufo PROC NEAR
  inc word ptr ufo_spawn_clock
  cmp ufo_spawn_clock, UFO_SPAWN_TICKS
  jb UFO_Check_Active
  mov ufo_spawn_clock, 0
  cmp ufo_life, 0
  jne UFO_Check_Active
  call spawn_ufo
  ret
UFO_Check_Active:
  cmp ufo_life, 0
  je UFO_Done
UFO_Active:
  dec ufo_life
  jz UFO_Leave
  call move_ufo
  call update_ufo_shot
  ret
UFO_Leave:
  mov ufo_shot_y, 0FFh
UFO_Done:
  ret
update_ufo ENDP

spawn_ufo PROC NEAR
  call random_word
  xor dx, dx
  mov bx, BATTLE_W-2
  div bx
  mov ufo_x, dl
  call random_word
  xor dx, dx
  mov bx, BATTLE_H-1
  div bx
  mov ufo_y, dl
  mov ufo_life, UFO_LIFE_TICKS
  mov ufo_move_clock, 0
  mov ufo_shot_clock, 0
  mov ufo_shot_y, 0FFh
  call random_word
  and al, 1
  mov ufo_direction_x, al
  mov al, ah
  and al, 1
  mov ufo_direction_y, al
  ret
spawn_ufo ENDP

move_ufo PROC NEAR
  inc ufo_move_clock
  cmp ufo_move_clock, UFO_MOVE_TICKS
  jae UFO_Move_Ready
  ret
UFO_Move_Ready:
  mov ufo_move_clock, 0
  call random_word
  test al, 1
  jz UFO_Set_Left
  mov ufo_direction_x, 1
  jmp UFO_Set_Vertical_Direction
UFO_Set_Left:
  mov ufo_direction_x, 0
UFO_Set_Vertical_Direction:
  test al, 2
  jz UFO_Set_Up
  mov ufo_direction_y, 1
  jmp UFO_Move_Horizontal
UFO_Set_Up:
  mov ufo_direction_y, 0

UFO_Move_Horizontal:
  cmp ufo_direction_x, 0
  je UFO_Move_Left
  cmp ufo_x, BATTLE_W-3
  jae UFO_Bounce_Left
  inc ufo_x
  jmp UFO_Move_Vertical
UFO_Bounce_Left:
  mov ufo_direction_x, 0
  dec ufo_x
  jmp UFO_Move_Vertical
UFO_Move_Left:
  cmp ufo_x, 0
  je UFO_Bounce_Right
  dec ufo_x
  jmp UFO_Move_Vertical
UFO_Bounce_Right:
  mov ufo_direction_x, 1
  inc ufo_x

UFO_Move_Vertical:
  cmp ufo_direction_y, 0
  je UFO_Move_Up
  cmp ufo_y, BATTLE_H-2
  jae UFO_Bounce_Up
  inc ufo_y
  jmp UFO_Move_Done
UFO_Bounce_Up:
  mov ufo_direction_y, 0
  dec ufo_y
  jmp UFO_Move_Done
UFO_Move_Up:
  cmp ufo_y, 0
  je UFO_Bounce_Down
  dec ufo_y
  jmp UFO_Move_Done
UFO_Bounce_Down:
  mov ufo_direction_y, 1
  inc ufo_y
UFO_Move_Done:
  ret
move_ufo ENDP

update_ufo_shot PROC NEAR
  cmp ufo_shot_y, 0FFh
  je UFO_Try_Fire
  mov al, ufo_shot_x
  cmp al, player_x
  je UFO_Shot_Vertical
  jb UFO_Shot_Move_Right
  dec ufo_shot_x
  jmp UFO_Shot_Vertical
UFO_Shot_Move_Right:
  inc ufo_shot_x
UFO_Shot_Vertical:
  mov al, ufo_shot_y
  cmp al, player_y
  je UFO_Check_Shot_Hit
  jb UFO_Shot_Move_Down
  dec ufo_shot_y
  jmp UFO_Check_Shot_Hit
UFO_Shot_Move_Down:
  inc ufo_shot_y
UFO_Check_Shot_Hit:
  mov al, ufo_shot_y
  cmp al, player_y
  jne UFO_Shot_Done
  mov al, ufo_shot_x
  cmp al, player_x
  jne UFO_Shot_Done
  dec hp
  mov ufo_shot_y, 0FFh
  mov ufo_shot_clock, 0
  ret
UFO_Try_Fire:
  inc ufo_shot_clock
  cmp ufo_shot_clock, UFO_FIRE_TICKS
  jb UFO_Shot_Done
  mov ufo_shot_clock, 0
  mov al, ufo_x
  inc al
  mov ufo_shot_x, al
  mov al, ufo_y
  inc al
  mov ufo_shot_y, al
UFO_Shot_Done:
  ret
update_ufo_shot ENDP

spawn_bullet PROC NEAR
  mov spawn_column, al
  mov si, 0
Spawn_Find_Slot:
  cmp byte ptr bullet_y[si], 0FFh
  je Spawn_Store
  inc si
  cmp si, BULLET_COUNT
  jb Spawn_Find_Slot
  ret
Spawn_Store:
  mov al, spawn_column
  mov bullet_x[si], al
  mov byte ptr bullet_y[si], 0
  ret
spawn_bullet ENDP

spawn_wave PROC NEAR
  call random_word
  mov cx, ax
  xor bx, bx
  mov bl, gap_width
  mov ax, BATTLE_W
  sub ax, bx
  inc ax
  mov bx, ax
  mov ax, cx
  xor dx, dx
  div bx
  mov gap_start, dl
  mov wave_column, 0
Wave_Column_Loop:
  mov al, wave_column
  cmp al, gap_start
  jb Wave_Spawn_Bullet
  sub al, gap_start
  cmp al, gap_width
  jb Wave_Next_Column
Wave_Spawn_Bullet:
  mov al, wave_column
  call spawn_bullet
Wave_Next_Column:
  inc wave_column
  cmp wave_column, BATTLE_W
  jb Wave_Column_Loop
  ret
spawn_wave ENDP

random_word PROC NEAR
  mov ax, rng
  mov dx, ax
  mov cl, 7
  shl dx, cl
  xor ax, dx
  mov dx, ax
  mov cl, 9
  shr dx, cl
  xor ax, dx
  mov dx, ax
  mov cl, 8
  shl dx, cl
  xor ax, dx
  mov rng, ax
  ret
random_word ENDP

wait_tick PROC NEAR
  ; BIOS wait uses CX:DX microseconds (80,000 = 0001:3880h).
  mov cx, 0001h
  mov dx, 3880h
  mov ah, 86h
  int 15h
  jnc Wait_Done

  ; Older BIOSes may not implement INT 15h/AH=86h. Alternate one- and
  ; two-tick waits to keep the average game speed close to 80 ms.
Wait_Fallback:
  mov ah, 00h
  int 1Ah
  mov ax, dx
  sub ax, fallback_low
  cmp ax, fallback_target
  jb Wait_Fallback
  mov fallback_low, dx
  cmp fallback_phase, 0
  jne Wait_Fallback_Short
  mov fallback_target, 2
  mov fallback_phase, 1
  ret
Wait_Fallback_Short:
  mov fallback_target, 1
  mov fallback_phase, 0
Wait_Done:
  ret
wait_tick ENDP

render_game PROC NEAR
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push es

  call clear_screen

  cmp boss_index, 0
  jne Render_Boss_Title
  mov si, OFFSET title_text
  mov cx, title_len
  mov dh, 1
  mov dl, 24
  mov bl, 0Eh
  call print_at
  jmp Render_Top_Status

Render_Boss_Title:
  mov al, boss_index
  cmp al, 5
  jbe Render_Boss_Title_Index_Ready
  mov al, 5
Render_Boss_Title_Index_Ready:
  dec al
  xor ah, ah
  mov bx, ax
  shl bx, 1
  mov si, boss_title_ptrs[bx]
  mov al, boss_index
  cmp al, 5
  jbe Render_Boss_Length_Index_Ready
  mov al, 5
Render_Boss_Length_Index_Ready:
  dec al
  xor ah, ah
  mov bx, ax
  xor cx, cx
  mov cl, boss_title_lengths[bx]
  mov ax, cx
  shr ax, 1
  mov dl, 40
  sub dl, al
  mov dh, 1
  mov bl, 0Eh
  call print_at

  cmp boss_hit_flash, 0
  je Render_Normal_Boss_Art
  mov si, OFFSET boss_hit_art
  mov bl, 0Fh
  jmp Render_Boss_Art_Position
Render_Normal_Boss_Art:
  mov al, boss_index
  cmp al, 5
  jbe Render_Boss_Art_Index_Ready
  mov al, 5
Render_Boss_Art_Index_Ready:
  dec al
  xor ah, ah
  mov bx, ax
  shl bx, 1
  mov si, boss_art_ptrs[bx]
  mov bl, 0Ch
Render_Boss_Art_Position:
  mov cx, boss_art_len
  mov dh, 3
  mov dl, boss_x
  add dl, SCREEN_LEFT+1
  call print_at

Render_Top_Status:
  cmp boss_index, 0
  je Render_Survival_Status
  jmp Render_Boss_Status
Render_Survival_Status:
  ; Each 80 ms game tick is 8/100 of a second.
  mov ax, round_ticks
  sub ax, ticks
  mov bx, 8
  mul bx
  add ax, 99
  adc dx, 0
  mov bx, 100
  div bx
  mov timer_value, ax

  mov ax, timer_value
  xor dx, dx
  mov bx, 100
  div bx
  add al, "0"
  mov timer_text, al
  mov ax, dx
  xor dx, dx
  mov bx, 10
  div bx
  add al, "0"
  mov timer_text+1, al
  add dl, "0"
  mov timer_text+2, dl

  mov ax, round_ticks
  mov bx, 8
  mul bx
  mov bx, 100
  div bx
  xor dx, dx
  mov bx, 100
  div bx
  add al, "0"
  mov time_suffix+3, al
  mov ax, dx
  xor dx, dx
  mov bx, 10
  div bx
  add al, "0"
  mov time_suffix+4, al
  add dl, "0"
  mov time_suffix+5, dl

  mov al, hp
  xor ah, ah
  mov bl, 10
  div bl
  add al, "0"
  add ah, "0"
  mov hp_text, al
  mov hp_text+1, ah
  mov hp_text+3, al
  mov hp_text+4, ah

  mov si, OFFSET lv_label
  mov cx, lv_label_len
  mov dh, 18
  mov dl, 17
  mov bl, 0Fh
  call print_at
  mov si, OFFSET hp_label
  mov cx, hp_label_len
  mov dh, 18
  mov dl, 25
  mov bl, 0Fh
  call print_at
  mov si, OFFSET hp_text
  mov cx, 5
  mov dh, 18
  mov dl, 28
  mov bl, 0Fh
  call print_at
  mov si, OFFSET health_bar
  mov cx, 20
  mov dh, 18
  mov dl, 35
  mov bl, 04h
  call print_at
  mov si, OFFSET health_bar
  xor cx, cx
  mov cl, hp
  mov dh, 18
  mov dl, 35
  mov bl, 0Eh
  call print_at
  jmp Render_Player_Status

Render_Boss_Status:
  mov al, hp
  xor ah, ah
  mov bl, 10
  div bl
  add al, "0"
  add ah, "0"
  mov boss_player_hp_text, al
  mov boss_player_hp_text+1, ah
  mov si, OFFSET boss_player_hp_label
  mov cx, boss_player_hp_label_len
  mov dh, 2
  mov dl, 17
  mov bl, 0Fh
  call print_at
  mov si, OFFSET boss_player_hp_text
  mov cx, 2
  mov dh, 2
  mov dl, 20
  mov bl, 0Fh
  call print_at
  mov al, boss_hp
  xor ah, ah
  mov bl, 10
  div bl
  add al, "0"
  add ah, "0"
  mov boss_hp_text, al
  mov boss_hp_text+1, ah
  mov al, boss_max_hp
  xor ah, ah
  mov bl, 10
  div bl
  add al, "0"
  add ah, "0"
  mov boss_hp_text+3, al
  mov boss_hp_text+4, ah
  mov si, OFFSET boss_hp_label
  mov cx, boss_hp_label_len
  mov dh, 2
  mov dl, 32
  mov bl, 0Ch
  call print_at
  mov si, OFFSET boss_hp_text
  mov cx, 5
  mov dh, 2
  mov dl, 41
  mov bl, 0Ch
  call print_at
  jmp Render_Arena

Render_Player_Status:
  mov si, OFFSET time_label
  mov cx, time_label_len
  mov dh, 2
  mov dl, 35
  mov bl, 0Eh
  call print_at
  mov si, OFFSET timer_text
  mov cx, 3
  mov dh, 2
  mov dl, 41
  mov bl, 0Eh
  call print_at
  mov si, OFFSET time_suffix
  mov cx, time_suffix_len
  mov dh, 2
  mov dl, 44
  mov bl, 0Eh
  call print_at

Render_Arena:
  mov si, OFFSET arena_border
  mov cx, BATTLE_W+2
  mov dh, 4
  mov dl, SCREEN_LEFT
  mov bl, 0Fh
  call print_at

  mov row_index, 0
Render_Empty_Row:
  mov si, OFFSET side_row
  mov cx, BATTLE_W+2
  mov al, row_index
  add al, SCREEN_TOP
  mov dh, al
  mov dl, SCREEN_LEFT
  mov bl, 0Fh
  call print_at
  inc row_index
  cmp row_index, BATTLE_H
  jb Render_Empty_Row

  mov si, OFFSET arena_border
  mov cx, BATTLE_W+2
  mov dh, SCREEN_TOP+BATTLE_H
  mov dl, SCREEN_LEFT
  mov bl, 0Fh
  call print_at

  ; Draw active bullets over the empty arena cells.
  mov di, 0
Render_Bullets:
  mov al, bullet_y[di]
  cmp al, 0FFh
  je Render_Next_Bullet
  add al, SCREEN_TOP
  mov dh, al
  mov dl, bullet_x[di]
  add dl, SCREEN_LEFT+1
  mov si, OFFSET single_char
  mov cx, 1
  mov bl, 0Eh
  call print_at
Render_Next_Bullet:
  inc di
  cmp di, BULLET_COUNT
  jb Render_Bullets

  cmp recovery_y, 0FFh
  je Render_UFO_Check
  mov al, recovery_y
  add al, SCREEN_TOP
  mov dh, al
  mov dl, recovery_x
  add dl, SCREEN_LEFT+1
  mov si, OFFSET recovery_char
  mov cx, 1
  mov bl, 0Ch
  call print_at

Render_UFO_Check:
  cmp ufo_life, 0
  je Render_UFO_Shot
  mov al, ufo_y
  add al, SCREEN_TOP
  mov dh, al
  mov dl, ufo_x
  add dl, SCREEN_LEFT+1
  mov si, OFFSET ufo_art
  mov cx, 3
  mov bl, 0Bh
  call print_at

Render_UFO_Shot:
  cmp ufo_shot_y, 0FFh
  je Render_Player_Shot
  mov al, ufo_shot_y
  add al, SCREEN_TOP
  mov dh, al
  mov dl, ufo_shot_x
  add dl, SCREEN_LEFT+1
  mov si, OFFSET ufo_shot_char
  mov cx, 1
  mov bl, 0Ch
  call print_at

Render_Player_Shot:
  cmp player_shot_y, 0FFh
  je Render_Player_Soul
  mov al, player_shot_y
  add al, SCREEN_TOP
  mov dh, al
  mov dl, player_shot_x
  add dl, SCREEN_LEFT+1
  mov si, OFFSET shot_char
  mov cx, 1
  mov bl, 0Ah
  call print_at

  ; Plot the soul last so it stays visible over a bullet.
Render_Player_Soul:
  mov byte ptr single_char, 3
  mov al, player_y
  add al, SCREEN_TOP
  mov dh, al
  mov dl, player_x
  add dl, SCREEN_LEFT+1
  mov si, OFFSET single_char
  mov cx, 1
  mov bl, 0Ch
  call print_at
  mov byte ptr single_char, "*"

  ; Frame the dialogue area like a classic RPG battle box.
  mov si, OFFSET dialog_border
  mov cx, PANEL_WIDTH
  mov dh, 19
  mov dl, PANEL_LEFT
  mov bl, 0Fh
  call print_at
  mov row_index, 0
Render_Dialogue_Side:
  mov si, OFFSET dialog_side
  mov cx, PANEL_WIDTH
  mov al, row_index
  add al, 20
  mov dh, al
  mov dl, PANEL_LEFT
  mov bl, 0Fh
  call print_at
  inc row_index
  cmp row_index, 4
  jb Render_Dialogue_Side
  mov si, OFFSET dialog_border
  mov cx, PANEL_WIDTH
  mov dh, 24
  mov dl, PANEL_LEFT
  mov bl, 0Fh
  call print_at

  cmp game_state, 1
  jne Render_Check_Loss
  mov si, OFFSET win_text
  mov cx, win_text_len
  mov dh, 21
  mov dl, 18
  mov bl, 0Ah
  call print_at
  jmp Render_End_Hint
Render_Check_Loss:
  cmp game_state, 2
  jne Render_Playing_Dialogue
  mov si, OFFSET lose_text
  mov cx, lose_text_len
  mov dh, 21
  mov dl, 18
  mov bl, 0Ch
  call print_at
Render_End_Hint:
  mov si, OFFSET end_hint
  mov cx, end_hint_len
  mov dh, 22
  mov dl, 22
  mov bl, 0Eh
  call print_at
  jmp Render_Done
Render_Playing_Dialogue:
  cmp boss_index, 0
  je Render_Survival_Dialogue
  mov al, boss_index
  cmp al, 5
  jbe Render_Taunt_Index_Ready
  mov al, 5
Render_Taunt_Index_Ready:
  dec al
  xor ah, ah
  mov bx, ax
  shl bx, 1
  mov si, boss_taunt_ptrs[bx]
  mov al, boss_index
  cmp al, 5
  jbe Render_Taunt_Length_Index_Ready
  mov al, 5
Render_Taunt_Length_Index_Ready:
  dec al
  xor ah, ah
  mov bx, ax
  xor cx, cx
  mov cl, boss_taunt_lengths[bx]
  mov dh, 20
  mov dl, 17
  mov bl, 0Fh
  call print_at
  mov si, OFFSET attack_hint
  mov cx, attack_hint_len
  mov dh, 21
  mov dl, 17
  mov bl, 07h
  call print_at
  mov si, OFFSET controls_text
  mov cx, controls_len
  mov dh, 22
  mov dl, 22
  mov bl, 0Eh
  call print_at
  jmp Render_Done
Render_Survival_Dialogue:
  mov si, OFFSET dialog_text
  mov cx, dialog_text_len
  mov dh, 20
  mov dl, 17
  mov bl, 0Fh
  call print_at
  mov si, OFFSET dialog_hint
  mov cx, dialog_hint_len
  mov dh, 21
  mov dl, 17
  mov bl, 07h
  call print_at
  mov si, OFFSET controls_text
  mov cx, controls_len
  mov dh, 22
  mov dl, 22
  mov bl, 0Eh
  call print_at

Render_Done:
  pop es
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
render_game ENDP

clear_screen PROC NEAR
  push ax
  push cx
  push di
  push es
  mov ax, 0B800h
  mov es, ax
  xor di, di
  mov ax, 0720h
  mov cx, 2000
  cld
  rep stosw
  pop es
  pop di
  pop cx
  pop ax
  ret
clear_screen ENDP

; Print DS:SI, CX characters at screen row DH, column DL, color BL.
print_at PROC NEAR
  push ax
  push bx
  push cx
  push dx
  push si
  push di
  push es

  xor ax, ax
  mov al, dh
  mov di, ax
  shl di, 1
  shl di, 1
  shl di, 1
  shl di, 1
  shl di, 1
  mov ax, di
  shl di, 1
  shl di, 1
  add di, ax
  xor ax, ax
  mov al, dl
  shl ax, 1
  add di, ax
  mov ax, 0B800h
  mov es, ax

Print_Character:
  cmp cx, 0
  je Print_Done
  mov al, [si]
  mov ah, bl
  mov es:[di], ax
  inc si
  add di, 2
  dec cx
  jmp Print_Character

Print_Done:
  pop es
  pop di
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
print_at ENDP

END start

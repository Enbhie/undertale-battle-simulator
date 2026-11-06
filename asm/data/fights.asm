
.segment "MONSTER_DATA"

;--------------------------------
; Array: fights
;--------------------------------
;
; List of 256 <Fight> structures.
; The index in the array is the ID of the fight.
;--------------------------------
fights:
    .byte $03, $00, $00, $00 ; fight 0
    .byte $01, $02, $00, $00 ; fight 1
    .byte $01, $01, $00, $00 ; fight 2
    .byte $01, $03, $00, $00 ; fight 3
<<<<<<< HEAD
    .byte $01, $04, $00, $00 ; fight 4 - boss chain starts at Grasshopper
    .byte $01, $05, $00, $00 ; fight 5 - Snake
=======
    .byte $01, $04, $00, $00 ; fight 4
>>>>>>> ed263d6d4bbd1e9ada92b281ccc8ef517e2d94a7

    ; unused data
    .repeat 251
        .tag Fight
    .endrepeat

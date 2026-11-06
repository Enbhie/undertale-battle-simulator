SANS_ROTATE_BANK = 40
sans_rotate_map:
    .byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    .byte 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33
    .byte 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50
    .byte 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67
    .byte 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84
    .byte 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101
    .byte 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118
    .byte 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135
sans_rotate_hitbox_lo:
    .byte <sans_rotate_hitbox_0, <sans_rotate_hitbox_1, <sans_rotate_hitbox_2, <sans_rotate_hitbox_3, <sans_rotate_hitbox_4, <sans_rotate_hitbox_5, <sans_rotate_hitbox_6, <sans_rotate_hitbox_7
sans_rotate_hitbox_hi:
    .byte >sans_rotate_hitbox_0, >sans_rotate_hitbox_1, >sans_rotate_hitbox_2, >sans_rotate_hitbox_3, >sans_rotate_hitbox_4, >sans_rotate_hitbox_5, >sans_rotate_hitbox_6, >sans_rotate_hitbox_7
sans_rotate_hitbox_0:
    .byte 2, 18, 29, 4
    .byte 105, 18, 29, 4
    .byte 2, 22, 62, 4
    .byte 72, 22, 62, 4
    .byte 2, 26, 132, 12
    .byte 2, 38, 62, 4
    .byte 72, 38, 62, 4
    .byte 2, 42, 29, 4
    .byte 105, 42, 29, 4
    .byte $FF
sans_rotate_hitbox_1:
    .byte 2, 2, 31, 4
    .byte 2, 6, 38, 4
    .byte 2, 10, 45, 4
    .byte 2, 14, 52, 4
    .byte 2, 18, 59, 4
    .byte 12, 22, 57, 4
    .byte 26, 26, 55, 4
    .byte 41, 30, 54, 4
    .byte 55, 34, 55, 4
    .byte 67, 38, 57, 4
    .byte 75, 42, 59, 4
    .byte 82, 46, 52, 4
    .byte 89, 50, 45, 4
    .byte 96, 54, 38, 4
    .byte 103, 58, 31, 4
    .byte $FF
sans_rotate_hitbox_2:
    .byte 21, 2, 34, 4
    .byte 26, 6, 32, 4
    .byte 31, 10, 30, 4
    .byte 36, 14, 28, 4
    .byte 41, 18, 26, 4
    .byte 46, 22, 24, 4
    .byte 51, 26, 23, 4
    .byte 56, 30, 24, 4
    .byte 62, 34, 23, 4
    .byte 66, 38, 24, 4
    .byte 69, 42, 26, 4
    .byte 72, 46, 28, 4
    .byte 75, 50, 30, 4
    .byte 78, 54, 32, 4
    .byte 81, 58, 34, 4
    .byte $FF
sans_rotate_hitbox_3:
    .byte 45, 2, 22, 4
    .byte 47, 6, 21, 4
    .byte 49, 10, 20, 4
    .byte 51, 14, 19, 4
    .byte 54, 18, 17, 4
    .byte 56, 22, 16, 4
    .byte 58, 26, 15, 4
    .byte 60, 30, 16, 4
    .byte 63, 34, 15, 4
    .byte 64, 38, 16, 4
    .byte 65, 42, 17, 4
    .byte 66, 46, 19, 4
    .byte 67, 50, 20, 4
    .byte 68, 54, 21, 4
    .byte 69, 58, 22, 4
    .byte $FF
sans_rotate_hitbox_4:
    .byte 58, 2, 20, 4
    .byte 59, 6, 18, 8
    .byte 60, 14, 16, 8
    .byte 61, 22, 14, 8
    .byte 62, 30, 12, 4
    .byte 61, 34, 14, 8
    .byte 60, 42, 16, 8
    .byte 59, 50, 18, 8
    .byte 58, 58, 20, 4
    .byte $FF
sans_rotate_hitbox_5:
    .byte 69, 2, 22, 4
    .byte 68, 6, 21, 4
    .byte 67, 10, 20, 4
    .byte 66, 14, 19, 4
    .byte 65, 18, 17, 4
    .byte 64, 22, 16, 4
    .byte 63, 26, 15, 4
    .byte 60, 30, 16, 4
    .byte 58, 34, 15, 4
    .byte 56, 38, 16, 4
    .byte 54, 42, 17, 4
    .byte 51, 46, 19, 4
    .byte 49, 50, 20, 4
    .byte 47, 54, 21, 4
    .byte 45, 58, 22, 4
    .byte $FF
sans_rotate_hitbox_6:
    .byte 81, 2, 34, 4
    .byte 78, 6, 32, 4
    .byte 75, 10, 30, 4
    .byte 72, 14, 28, 4
    .byte 69, 18, 26, 4
    .byte 66, 22, 24, 4
    .byte 62, 26, 23, 4
    .byte 56, 30, 24, 4
    .byte 51, 34, 23, 4
    .byte 46, 38, 24, 4
    .byte 41, 42, 26, 4
    .byte 36, 46, 28, 4
    .byte 31, 50, 30, 4
    .byte 26, 54, 32, 4
    .byte 21, 58, 34, 4
    .byte $FF
sans_rotate_hitbox_7:
    .byte 103, 2, 31, 4
    .byte 96, 6, 38, 4
    .byte 89, 10, 45, 4
    .byte 82, 14, 52, 4
    .byte 75, 18, 59, 4
    .byte 67, 22, 57, 4
    .byte 55, 26, 55, 4
    .byte 41, 30, 54, 4
    .byte 26, 34, 55, 4
    .byte 12, 38, 57, 4
    .byte 2, 42, 59, 4
    .byte 2, 46, 52, 4
    .byte 2, 50, 45, 4
    .byte 2, 54, 38, 4
    .byte 2, 58, 31, 4
    .byte $FF

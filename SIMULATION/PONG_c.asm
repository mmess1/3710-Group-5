# Optimized Pong program (same gameplay behavior, fewer instructions)

init:
    MOVI $r4, 0
    MOVI $r5, 0
    MOVI $r2, 0

    MOVI $r6, 63
    MULI $r6, 5
    MOVI $r7, 47
    MULI $r7, 5

    MOVI $r8, 1
    MOVI $r9, 1

main_loop:
    CMPI $r2, 1
    BCOND 12, delay_tier2
    MOVI $r12, 60
    BCOND 14, frame_delay_setup

delay_tier2:
    CMPI $r2, 3
    BCOND 12, delay_tier3
    MOVI $r12, 80
    BCOND 14, frame_delay_setup

delay_tier3:
    CMPI $r2, 5
    BCOND 12, delay_tier4
    MOVI $r12, 90
    BCOND 14, frame_delay_setup

delay_tier4:
    CMPI $r2, 7
    BCOND 12, delay_tier5
    MOVI $r12, 96
    BCOND 14, frame_delay_setup

delay_tier5:
    CMPI $r2, 9
    BCOND 12, delay_tier6
    MOVI $r12, 100
    BCOND 14, frame_delay_setup

delay_tier6:
    CMPI $r2, 11
    BCOND 12, delay_tier7
    MOVI $r12, 103
    BCOND 14, frame_delay_setup

delay_tier7:
    CMPI $r2, 13
    BCOND 12, delay_default
    MOVI $r12, 90
    BCOND 14, frame_delay_setup

delay_default:
    MOVI $r12, 80

frame_delay_setup:
    MOVI $r14, 6

frame_delay_reset_inner:
    MOVI $r15, 112

frame_delay_inner:
    SUBI $r15, 1
    CMPI $r15, 0
    BCOND 1, frame_delay_inner

frame_delay_middle:
    SUBI $r14, 1
    CMPI $r14, 0
    BCOND 1, frame_delay_reset_inner

frame_delay_outer:
    SUBI $r12, 1
    CMPI $r12, 0
    BCOND 1, frame_delay_setup

    ADD $r6, $r8
    ADD $r7, $r9

    CMPI $r7, 5
    BCOND 13, top_collision

    MOVI $r14, 93
    MULI $r14, 5
    ADDI $r14, 1

    CMP $r7, $r14
    BCOND 7, bottom_collision

direction_dispatch:
    CMPI $r8, 0
    BCOND 6, left_side
    BCOND 7, right_side

top_collision:
    MOVI $r7, 5
    MULI $r9, -1
    BCOND 14, direction_dispatch

bottom_collision:
    MOV $r7, $r14
    MULI $r9, -1
    BCOND 14, direction_dispatch

left_side:
    MOVI $r11, 40
    CMP $r6, $r11
    BCOND 12, right_side

    MOV $r10, $r6
    SUB $r10, $r8
    CMP $r10, $r11
    BCOND 13, left_miss

    MOV $r10, $r7
    ADDI $r10, 8
    CMP $r10, $r1
    BCOND 6, left_miss

    MOV $r10, $r1
    ADDI $r10, 44
    CMP $r7, $r10
    BCOND 12, left_miss

left_hit:
    MOV $r14, $r1
    MOVI $r13, 0
    BCOND 14, apply_hit_speed

left_miss:
    MOV $r10, $r6
    ADDI $r10, 8
    CMPI $r10, 30
    BCOND 6, left_post_check

    CMPI $r6, 39
    BCOND 12, left_post_check

    CMPI $r9, 0
    BCOND 13, left_deep_reflect

    MOV $r10, $r7
    ADDI $r10, 8
    SUB $r10, $r9
    CMP $r10, $r1
    BCOND 7, left_deep_reflect

    MOV $r10, $r7
    ADDI $r10, 8
    CMP $r10, $r1
    BCOND 6, left_deep_reflect

left_flip_dy:
    MULI $r9, -1
    BCOND 14, main_loop_far

left_deep_reflect:
    CMPI $r9, 0
    BCOND 7, left_post_check

    MOV $r11, $r1
    ADDI $r11, 44
    MOV $r10, $r7
    SUB $r10, $r9
    CMP $r10, $r11
    BCOND 13, left_post_check

    CMP $r7, $r11
    BCOND 12, left_post_check

    MULI $r9, -1
    BCOND 14, main_loop_far

left_post_check:
    CMPI $r6, 5
    BCOND 13, score_p2
    BCOND 14, main_loop_far

main_loop_far:
    BCOND 14, main_loop

apply_hit_speed:
    ADDI $r2, 1

    MOV $r8, $r2
    ADDI $r8, 2
    ARSHI $r8, 1
    CMPI $r8, 6
    BCOND 13, bounce_handler
    MOVI $r8, 6

bounce_handler:
    MOV $r10, $r7
    ADDI $r10, 4
    SUB $r10, $r14
    SUBI $r10, 22

    MOV $r15, $r10
    MUL $r10, $r8
    MULI $r10, 3
    ARSHI $r10, 6
    MOV $r9, $r10

    CMPI $r9, 0
    BCOND 1, bounce_dir

    CMPI $r15, 0
    BCOND 0, bounce_dir
    BCOND 6, bounce_set_neg

    MOVI $r9, 1
    BCOND 14, bounce_dir

bounce_set_neg:
    NOT $r9, $r0

bounce_dir:
    CMPI $r13, 0
    BCOND 0, main_loop_far

    MULI $r8, -1
    BCOND 14, main_loop_far

right_side:
    MOVI $r11, 61
    MULI $r11, 10

    MOV $r10, $r6
    ADDI $r10, 8
    CMP $r10, $r11
    BCOND 6, right_post_check

    SUB $r10, $r8
    CMP $r10, $r11
    BCOND 7, right_miss

    MOV $r10, $r7
    ADDI $r10, 8
    CMP $r10, $r3
    BCOND 6, right_miss

    MOV $r10, $r3
    ADDI $r10, 44
    CMP $r7, $r10
    BCOND 12, right_miss

right_hit:
    MOV $r14, $r3
    MOVI $r13, 1
    BCOND 14, apply_hit_speed

right_miss:
    MOV $r15, $r11
    ADDI $r15, 9

    MOV $r10, $r6
    ADDI $r10, 8
    CMP $r10, $r11
    BCOND 6, right_post_check

    CMP $r6, $r15
    BCOND 12, right_post_check

    CMPI $r9, 0
    BCOND 13, right_deep_reflect

    MOV $r10, $r7
    ADDI $r10, 8
    SUB $r10, $r9
    CMP $r10, $r3
    BCOND 7, right_deep_reflect

    MOV $r10, $r7
    ADDI $r10, 8
    CMP $r10, $r3
    BCOND 6, right_deep_reflect

right_flip_dy:
    MULI $r9, -1
    BCOND 14, main_loop_far

right_deep_reflect:
    CMPI $r9, 0
    BCOND 7, right_post_check

    MOV $r15, $r3
    ADDI $r15, 44
    MOV $r10, $r7
    SUB $r10, $r9
    CMP $r10, $r15
    BCOND 13, right_post_check

    CMP $r7, $r15
    BCOND 12, right_post_check

    MULI $r9, -1
    BCOND 14, main_loop_far

right_post_check:
    MOV $r10, $r11
    ADDI $r10, 16
    CMP $r6, $r10
    BCOND 7, score_p1
    BCOND 14, main_loop_far

score_p1:
    ADDI $r4, 1
    MOVI $r8, 1
    BCOND 14, reset_after_score

score_p2:
    ADDI $r5, 1
    MOVI $r8, -1

reset_after_score:
    MOVI $r2, 0

    MOVI $r6, 63
    MULI $r6, 5
    MOVI $r7, 47
    MULI $r7, 5

    MOVI $r9, 1
    BCOND 14, main_loop_far

# Optimized Pong program (same gameplay behavior, fewer instructions)

init:
    MOVI $r4, 0
    MOVI $r5, 0
    MOVI $r8, 1
    BCOND 14, init_to_reset_mid

main_loop:
    MOVI $r12, 80
    CMPI $r2, 1
    BCOND 13, delay_set_60

    CMPI $r2, 5
    BCOND 12, delay_gt5
    CMPI $r2, 3
    BCOND 12, delay_set_90
    BCOND 14, frame_delay_setup

delay_gt5:
    CMPI $r2, 9
    BCOND 12, delay_gt9
    CMPI $r2, 7
    BCOND 12, delay_set_100
    MOVI $r12, 96
    BCOND 14, frame_delay_setup

delay_gt9:
    CMPI $r2, 13
    BCOND 12, frame_delay_setup
    CMPI $r2, 11
    BCOND 12, delay_set_90
    MOVI $r12, 103
    BCOND 14, frame_delay_setup

delay_set_60:
    MOVI $r12, 60
    BCOND 14, frame_delay_setup

delay_set_90:
    MOVI $r12, 90
    BCOND 14, frame_delay_setup

delay_set_100:
    MOVI $r12, 100

frame_delay_setup:
    MOVI $r14, 6

frame_delay_reset_inner:
    MOVI $r15, 2

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
    BCOND 14, wall_flip

bottom_collision:
    MOV $r7, $r14
wall_flip:
    MULI $r9, -1
    BCOND 14, direction_dispatch

left_side:
    MOVI $r11, 40
    MOV $r14, $r1
    CMP $r6, $r11
    BCOND 12, right_side

    MOV $r10, $r6
    SUB $r10, $r8
    CMP $r10, $r11
    BCOND 13, side_miss
    BCOND 14, side_hit_test

right_side:
    MOVI $r11, 61
    MULI $r11, 10
    MOV $r14, $r3

    MOV $r10, $r6
    ADDI $r10, 8
    CMP $r10, $r11
    BCOND 6, right_post_check

    SUB $r10, $r8
    CMP $r10, $r11
    BCOND 7, side_miss

side_hit_test:
    MOV $r10, $r7
    ADDI $r10, 8
    CMP $r10, $r14
    BCOND 6, side_miss

    MOV $r10, $r14
    ADDI $r10, 44
    CMP $r7, $r10
    BCOND 12, side_miss
    BCOND 14, apply_hit_speed

left_miss_pre:
    MOV $r10, $r6
    ADDI $r10, 8
    CMPI $r10, 30
    BCOND 6, left_post_check

    CMPI $r6, 39
    BCOND 12, left_post_check
    BCOND 14, shared_reflect

side_miss:
    CMPI $r8, 0
    BCOND 6, left_miss_pre

right_miss_pre:
    MOV $r15, $r11
    ADDI $r15, 9
    CMP $r6, $r15
    BCOND 12, right_post_check

shared_reflect:
    CMPI $r9, 0
    BCOND 13, shared_deep_reflect

    MOV $r10, $r7
    ADDI $r10, 8
    SUB $r10, $r9
    CMP $r10, $r14
    BCOND 7, shared_deep_reflect

    MOV $r10, $r7
    ADDI $r10, 8
    CMP $r10, $r14
    BCOND 6, shared_deep_reflect

    MULI $r9, -1
    BCOND 14, main_loop_far

shared_deep_reflect:
    CMPI $r9, 0
    BCOND 7, post_check_dispatch

    MOV $r15, $r14
    ADDI $r15, 44
    MOV $r10, $r7
    SUB $r10, $r9
    CMP $r10, $r15
    BCOND 13, post_check_dispatch

    CMP $r7, $r15
    BCOND 12, post_check_dispatch

    MULI $r9, -1
    BCOND 14, main_loop_far

init_to_reset_mid:
    BCOND 14, reset_after_score

post_check_dispatch:
    CMPI $r8, 0
    BCOND 6, left_post_check
right_post_check:
    ADDI $r11, 16
    CMP $r6, $r11
    BCOND 7, score_p1
main_loop_mid:
    BCOND 14, main_loop

left_post_check:
    CMPI $r6, 5
    BCOND 13, score_p2

main_loop_far:
    BCOND 14, main_loop_mid

apply_hit_speed:
    ADDI $r2, 1
    MOV $r13, $r8

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
    BCOND 6, main_loop_far

    MULI $r8, -1
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

    CMPI $r9, 0
    MOVI $r9, 1
    BCOND 7, serve_angle_done
    MOVI $r9, -1
serve_angle_done:
    BCOND 14, main_loop_far

# register use
    # $r1  = player 1 paddle y position
    # $r2  = rally hit counter
    # $r3  = player 2 paddle y position
    # $r4  = player 1 score
    # $r5  = player 2 score
    # $r6  = ball x
    # $r7  = ball y
    # $r8  = ball dx
    # $r9  = ball dy
    # $r10 = temp
    # $r11 = temp
    # $r12 = current frame delay value
    # $r13 = side flag
    # $r14 = temp
    # $r15 = temp

# branch codes
    # 0  =
    # 1  !=
    # 6  >
    # 7  <=
    # 12 <
    # 13 >=
    # 14 jump

# ram constants
    # none in this version
    # x start is built inline as 315
    # y start is built inline as 235

# setup =========================================================

init:
    MOVI $r4, 0       # p1 score = 0
    MOVI $r5, 0       # p2 score = 0
    MOVI $r8, 1       # start with dx = +1
    BCOND 14, reset_after_score

# main game loop ================================================

main_loop:

# ----- frame delay select -----
    MOVI $r12, 80     # default delay tier

    CMPI $r2, 1       # compare rally count to 1
    BCOND 13, delay_set_60

    CMPI $r2, 5       # compare rally count to 5
    BCOND 12, delay_gt5
    CMPI $r2, 3       # compare rally count to 3
    BCOND 12, delay_set_90
    BCOND 14, frame_delay_setup

delay_gt5:
    CMPI $r2, 9       # compare rally count to 9
    BCOND 12, delay_gt9
    CMPI $r2, 7       # compare rally count to 7
    BCOND 12, delay_set_100
    MOVI $r12, 96     # select this delay tier
    BCOND 14, frame_delay_setup

delay_gt9:
    CMPI $r2, 13      # compare rally count to 13
    BCOND 12, frame_delay_setup
    CMPI $r2, 11      # compare rally count to 11
    BCOND 12, delay_set_90
    MOVI $r12, 103    # select this delay tier
    BCOND 14, frame_delay_setup

delay_set_60:
    MOVI $r12, 60     # fastest delay tier used here
    BCOND 14, frame_delay_setup

delay_set_90:
    MOVI $r12, 90     # middle delay tier
    BCOND 14, frame_delay_setup

delay_set_100:
    MOVI $r12, 100    # slowest delay tier in this table

# ----- frame delay loop -----
frame_delay_setup:
    MOVI $r14, 6      # outer spin count

frame_delay_reset_inner:
    MOVI $r15, 2      # inner spin count

frame_delay_inner:
    SUBI $r15, 1      # inner--
    CMPI $r15, 0      # compare inner counter to zero
    BCOND 1, frame_delay_inner

frame_delay_middle:
    SUBI $r14, 1      # outer--
    CMPI $r14, 0      # compare outer counter to zero
    BCOND 1, frame_delay_reset_inner

frame_delay_outer:
    SUBI $r12, 1      # delay tier countdown--
    CMPI $r12, 0      # compare delay tier to zero
    BCOND 1, frame_delay_setup

# ----- ball update -----
    ADD $r6, $r8      # x += dx
    ADD $r7, $r9      # y += dy

# ----- vertical collision -----
    CMPI $r7, 5       # compare y to top wall
    BCOND 13, top_collision

    MOVI $r14, 93     # build 93
    MULI $r14, 5      # 93 * 5 = 465
    ADDI $r14, 1      # bottom bound = 466

    CMP $r7, $r14     # compare y to bottom wall
    BCOND 7, bottom_collision

# ----- choose horizontal path -----
direction_dispatch:
    CMPI $r8, 0       # test sign of dx
    BCOND 6, left_side
    BCOND 7, right_side

top_collision:
    MOVI $r7, 5       # clamp y back to top edge
    BCOND 14, wall_flip

bottom_collision:
    MOV $r7, $r14     # clamp y back to bottom edge

wall_flip:
    MULI $r9, -1      # flip dy
    BCOND 14, direction_dispatch

# side handling =================================================

right_side:
    MOVI $r11, 61     # build 61
    MULI $r11, 10     # right paddle hit x = 610
    MOV $r14, $r3     # load p2 paddle top into temp

    MOV $r10, $r6     # copy current x
    ADDI $r10, 8      # move to ball right edge
    CMP $r10, $r11    # compare right edge to right hit line
    BCOND 6, right_post_check

    SUB $r10, $r8     # back up one x-step from that edge
    CMP $r10, $r11    # compare previous edge to right hit line
    BCOND 7, side_miss

side_hit_test:
    MOV $r10, $r7     # copy ball y
    ADDI $r10, 8      # move to ball center
    CMP $r10, $r14    # compare center to paddle top
    BCOND 6, side_miss

    MOV $r10, $r14    # copy paddle top
    ADDI $r10, 44     # build paddle bottom
    CMP $r7, $r10     # compare ball y to paddle bottom
    BCOND 12, side_miss

# shared bounce =================================================
apply_hit_speed:
    ADDI $r2, 1       # rally count++
    MOV $r13, $r8     # save old dx sign

    MOV $r8, $r2      # copy rally count into dx temp
    ADDI $r8, 2       # bias it upward
    ARSHI $r8, 1      # divide by 2 to get new speed tier
    CMPI $r8, 6       # cap speed at 6
    BCOND 13, bounce_handler
    MOVI $r8, 6       # clamp dx magnitude to 6

bounce_handler:
    MOV $r10, $r7     # copy ball y
    SUB $r10, $r14    # subtract paddle top to get local offset
    SUBI $r10, 18     # shift toward paddle center

    MOV $r15, $r10    # save center offset for zero-dy fixup
    MUL $r10, $r8     # scale offset by dx magnitude
    MULI $r10, 3      # multiply numerator by 3
    ARSHI $r10, 6     # divide by 64 for final dy
    MOV $r9, $r10     # store new dy

# ----- zero-dy fixup -----
    CMPI $r9, 0       # check if computed dy is zero
    BCOND 1, bounce_dir

    CMPI $r15, 0      # check if paddle offset was exactly centered
    BCOND 0, bounce_dir
    MOVI $r9, -1      # force dy = -1 first
    BCOND 6, bounce_dir
    ADDI $r9, 2       # turn -1 into +1 for the other side

# ----- horizontal direction fix -----
bounce_dir:
    CMPI $r13, 0      # test saved dx sign
    BCOND 6, main_loop_far

    MULI $r8, -1      # if old dx was right-facing then flip
    BCOND 14, main_loop_far

left_side:
    MOVI $r11, 40     # left paddle hit x = 40
    MOV $r14, $r1     # load p1 paddle top into temp

    CMP $r6, $r11     # compare current x to left hit line
    BCOND 12, right_side

    MOV $r10, $r6     # copy current x
    SUB $r10, $r8     # back up one step to previous x
    CMP $r10, $r11    # compare previous x to left hit line
    BCOND 13, side_miss
    BCOND 14, side_hit_test

# score / post dispatch =========================================

post_check_dispatch:
    CMPI $r8, 0       # test sign of dx
    BCOND 6, left_post_check

right_post_check:
    ADDI $r11, 16     # extend right-side line to score line
    CMP $r6, $r11     # compare x to right score line
    BCOND 7, score_p1

main_loop_far:
    BCOND 14, main_loop

left_post_check:
    CMPI $r6, 5       # compare x to left score line
    BCOND 13, score_p2
    BCOND 14, main_loop_far

score_p1:
    ADDI $r4, 1       # p1++
    MOVI $r8, 1       # next serve goes right
    BCOND 14, reset_after_score

score_p2:
    ADDI $r5, 1       # p2++
    MOVI $r8, -1      # next serve goes left

# reset =========================================================

reset_after_score:
    MOVI $r2, 0       # reset rally counter to 0
    MOVI $r6, 63      # build x start base
    MULI $r6, 5       # x = 315
    MOVI $r7, 47      # build y start base
    MULI $r7, 5       # y = 235

    ARSHI $r9, 15     # collapse old dy sign
    MULI $r9, 2       # scale sign
    ADDI $r9, 1       # produce ±1 style restart dy
    BCOND 14, main_loop_far

# miss / reflect helpers ========================================

left_miss_pre:
    CMPI $r6, 21      # compare x to left miss threshold
    BCOND 6, left_post_check

    CMPI $r6, 39      # compare x to left near-wall value
    BCOND 12, left_post_check
    BCOND 14, shared_reflect

side_miss:
    CMPI $r8, 0       # test sign of dx
    BCOND 6, left_miss_pre

right_miss_pre:
    MOV $r15, $r11    # copy current right-side line
    ADDI $r15, 9      # push to right score threshold
    CMP $r6, $r15     # compare x to that threshold
    BCOND 12, right_post_check

shared_reflect:
    CMPI $r9, 0       # test dy sign
    BCOND 13, shared_deep_reflect

    MOV $r10, $r7     # copy y
    ADDI $r10, 8      # move to ball center
    SUB $r10, $r9     # reconstruct previous center y
    CMP $r10, $r14    # compare previous center to paddle top
    BCOND 7, post_check_dispatch

    ADD $r10, $r9     # restore current center
    CMP $r10, $r14    # compare center to paddle top
    BCOND 6, post_check_dispatch

    MULI $r9, -1      # flip dy on this edge case
    BCOND 14, main_loop_far

shared_deep_reflect:
    BCOND 0, post_check_dispatch

    MOV $r15, $r14    # copy paddle top
    ADDI $r15, 44     # build paddle bottom
    MOV $r10, $r7     # copy ball y
    SUB $r10, $r9     # reconstruct previous y
    CMP $r10, $r15    # compare previous y to paddle bottom
    BCOND 13, post_check_dispatch

    CMP $r7, $r15     # compare current y to paddle bottom
    BCOND 12, post_check_dispatch

    MULI $r9, -1      # flip dy on this edge case
    BCOND 14, main_loop_far
! This program executes pow as a test program using the LC 2200 calling convention
! Check your registers ($v0) and memory to see if it is consistent with this program

        ! vector table
vector0:
        .fill 0x00000000                        ! device ID 0
        .fill 0x00000000                        ! device ID 1
        .fill 0x00000000                        ! ...
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000
        .fill 0x00000000                        ! device ID 7
        ! end vector table

main:	lea $sp, initsp                         ! initialize the stack pointer
        lw $sp, 0($sp)                          ! finish initialization

                                                ! TODO FIX ME: Install timer interrupt handler into vector table
        lea $t0, timer_handler
        lea $t1, vector0
        sw $t0, 0($t1)

                                                ! TODO FIX ME: Install rice cooker interrupt handler into vector table
        lea $t0, rice_cooker
        lea $t1, vector0
        sw $t0, 1($t1)
        
        
        ei                                      ! Enable interrupts

        lea $a0, BASE                           ! load base for pow
        lw $a0, 0($a0)
        lea $a1, EXP                            ! load power for pow
        lw $a1, 0($a1)
        lea $at, POW                            ! load address of pow
        jalr $ra, $at                           ! run pow
        lea $a0, ANS                            ! load base for pow
        sw $v0, 0($a0)

        halt                                    ! stop the program here
        addi $v0, $zero, -1                     ! load a bad value on failure to halt

BASE:   .fill 2
EXP:    .fill 8
ANS:	.fill 0                                 ! should come out to 256 (BASE^EXP)

POW:    addi $sp, $sp, -1                       ! allocate space for old frame pointer
        sw $fp, 0($sp)

        addi $fp, $sp, 0                        ! set new frame pinter
        
        skpgt $a1, $zero                        ! check if $a1 is zero (if not, skip the br)
        br RET1                                 ! if the power is 0 return 1
        skpgt $a0, $zero
        br RET0                                 ! if the base is 0 return 0 (otherwise, the br was skipped)

        addi $a1, $a1, -1                       ! decrement the power

        lea $at, POW                            ! load the address of POW
        addi $sp, $sp, -2                       ! push 2 slots onto the stack
        sw $ra, -1($fp)                         ! save RA to stack
        sw $a0, -2($fp)                         ! save arg 0 to stack
        jalr $ra, $at                           ! recursively call POW
        add $a1, $v0, $zero                     ! store return value in arg 1
        lw $a0, -2($fp)                         ! load the base into arg 0
        lea $at, MULT                           ! load the address of MULT
        jalr $ra, $at                           ! multiply arg 0 (base) and arg 1 (running product)
        lw $ra, -1($fp)                         ! load RA from the stack
        addi $sp, $sp, 2

        br FIN                                  ! return

RET1:   addi $v0, $zero, 1                      ! return a value of 1
        skplt $zero, $v0                        ! convenient use of skplt to get to FIN (0 < 1)

RET0:   add $v0, $zero, $zero                   ! return a value of 0

FIN:    lw $fp, 0($fp)                          ! restore old frame pointer
        addi $sp, $sp, 1                        ! pop off the stack
        jalr $zero, $ra

MULT:   add $v0, $zero, $zero                   ! return value = 0
        addi $t0, $zero, 0                      ! sentinel = 0
AGAIN:  add $v0, $v0, $a0                       ! return value += argument0
        addi $t0, $t0, 1                        ! increment sentinel
        skple $a1, $t0                         ! if $t0 <= $a1, keep looping
        br AGAIN                                ! loop again

        jalr $zero, $ra                         ! return from mult

timer_handler:
        addi $sp, $sp, -1
        sw $k0, 0($sp)
        ei

        addi $sp, $sp, -2
        sw $t0, 1($sp)
        sw $t1, 0($sp)

        lea $t0, ticks !t0 = address of FFFF
        lw $t0, 0($t0) !t0 = FFFF
        lw $t1, 0($t0) !t1 = value at FFFF
        addi $t1, $t1, 1 !t1 = t1 + 1
        sw $t1, 0($t0) !save t1 at FFFF

        lw $t0, 1($sp)
        lw $t1, 0($sp)
        addi $sp, $sp, 2

        di
        lw $k0, 0($sp)
        addi $sp, $sp, 1
        reti					!TODO FIX ME

rice_cooker:
       addi $sp, $sp, -1
        sw $k0, 0($sp)
        ei

        addi $sp, $sp, -4
        sw $t0, 3($sp)
        sw $t1, 2($sp)
        sw $t2, 1($sp)
        sw $a0, 0($sp)

        lea $t0, power          !t0 = address of power
        lw $t0, 0($t0)          !t0 = FFE0
        lw $t1, 0($t0)          !t1 = value at FFE0
        IN $a0, 1               !a0 = rice cooker power value
        ADD $t2, $zero, $zero   !t2 = 0
        ADDI $t2, $zero, 50     !t2 = 50
        SKPGE $a0, $t2          ! if (a0 >= 50) skip
        add $t1, $t1, $a0       !t1 = t1 + a0
        sw $t1, 0($t0)          !save t1 at FFE0

        lw $t0, 3($sp)
        lw $t1, 2($sp)
        lw $t2, 1($sp)
        lw $a0, 0($sp)
        addi $sp, $sp, 4

        di
        lw $k0, 0($sp)
        addi $sp, $sp, 1
        reti					    !TODO FIX ME


initsp: .fill 0xA000

ticks:  .fill 0xFFFF
power:  .fill 0xFFE0

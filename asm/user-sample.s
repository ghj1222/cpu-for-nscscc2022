.set noreorder
.set noat
.globl __start
.section text

__start:
.text

lui $a0, 0x8040
lui $a1, 0x8050
lui $a2, 0x8060

LOOP:
lw    $t0, 0x0($a0)           # t0=input

addi  $t1, $zero, 0x0
addi  $t2, $t0, 0x0
srl   $t6, $t2, 16
beq   $t6, $zero, COND0
addi  $t2, $t2, 1
lui   $t2, 1

COND0:
add   $t3, $t2, $t1           # MID=(L+R)

COND1:                        # 二分循环体，但是要保证跳转前先算mid

srl   $t3, $t3, 1             # MID=MID/2
mul   $t4, $t3, $t3           # MID2=MID*MID
sltu  $t5, $t0, $t4           # COND=input<MID2

beq   $t5, $zero, COND2       # if (COND==0)去COND2
nop

b     COND3                   # 跳转到COND3
addi  $t2, $t3, 0x0            # MID*MID>input的情况，R=MID

COND2:
addi  $t1, $t3, 0x0           # MID*MID<=input的情况 L=MID

COND3:
addi  $t6, $t1, 1
bne   $t6, $t2, COND1         # t1!=t2直接跳转
add   $t3, $t2, $t1           # MID=(L+R) 利用好延迟槽

sw    $t1, 0x0($a1)
addi  $a1, $a1, 0x4


bne   $a1, $a2, LOOP
addi  $a0, $a0, 0x4


jr    $ra
nop

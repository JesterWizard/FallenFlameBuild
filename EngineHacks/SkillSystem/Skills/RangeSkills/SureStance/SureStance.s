.thumb

.macro _blh to, reg=r3
	ldr \reg, =\to
	mov lr, \reg
	.short 0xF800
.endm

@arguments:
	@r0: unit pointer
	@r1: item id
	@r2: min max range word
@retuns
	@r0: updated min max range word
	
gBattleActor  = 0x203A4EC
gBattleTarget = 0x203A56C
pActionStruct = 0x203A958
gActiveUnitId = 0x202BE44

.set MaxRangeBonus, 0xF
push 	{lr}
add 	sp, #-0x4
str 	r2, [sp]
mov 	r0, r1
mov 	r1, sp // save the stack pointer address into a scratch register as it will be incremented with the below pushes/pops
push 	{r4}
push 	{r5}
push 	{r6}
push 	{r7}
mov 	r7, r1 // save the stack pointer into another register as we'll be using r1 now

// Check if the target and active unit are the same
// We only want the skill to apply when being attacked
CheckActiveUnit:
ldr r0, =gActiveUnitId
ldrb r0, [r0]
ldr r1, =gBattleTarget
ldrb r1, [r1, #0xB]
cmp r0, r1
beq End

GetActorPositions:
ldr r4, =gBattleActor
mov r5, #0x10 // x coordinate
mov r6, #0x11 // y coordinate
ldrb r0, [r4, r5]
ldrb r1, [r4, r6]

GetTargetPositions:
ldr r4, =gBattleTarget
mov r5, #0x10 // x coordinate
mov r6, #0x11 // y coordinate
ldrb r2, [r4, r5]
ldrb r3, [r4, r6]

// Get the absolute values to calculate the difference
@ r0 = x1
@ r1 = y1 
@ r2 = x2 
@ r3 = y2 
ComparePositions:
sub   r0, r2 @ X difference 
sub   r1, r3 @ Y difference 

asr r3, r0, #31
add r0, r0, r3
eor r0, r3

asr r3, r1, #31
add r1, r1, r3
eor r1, r3

add r0, r1 @ distance in r0

cmp r0, #1
ble End // If not ranged, then skip to the end

AddRangeBonus:
ldrh 	r0, [r7]
mov 	r0, #MaxRangeBonus

@prevent the maximum range from going over 15
cmp 	r0, #0xF
bls NotOverMax
mov 	r0, #0xF
NotOverMax:
strh 	r0, [r7]

End:
pop 	{r7}
pop 	{r6}
pop 	{r5}
pop 	{r4}
ldr 	r0, [sp]
add 	sp, #0x4
pop 	{r3} // restore link register value
bx 	r3
.ltorg
.align

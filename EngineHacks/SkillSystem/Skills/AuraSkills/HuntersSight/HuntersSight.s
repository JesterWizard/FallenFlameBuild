.thumb
.equ HuntersSightID, AuraSkillCheck+4

push {r4-r7, lr}
mov r4, r0 @atkr
mov r5, r1 @dfdr

@r0 is unit
@r1 is skill to check
@r2 is allegiance 0 = same team, 1 = are allies, 2 = different team, 3 = are enemies 
@r3 is maxrange

@check for skill
CheckSkill:
ldr r0, AuraSkillCheck
mov lr, r0
mov r0, r4 @attacker
ldr r1, HuntersSightID
mov r2, #0 @can trade
mov r3, #1 @range
.short 0xf800
cmp r0, #0
beq End

// Get the x and y coordinates of the attacker and defender
ldrb r0, [r4, #0x10] @ X coordinate of attacker
ldrb r1, [r4, #0x11] @ Y coordinate of attacker
ldrb r2, [r5, #0x10] @ X coordinate of defender
ldrb r3, [r5, #0x11] @ Y coordinate of defender

// Get the absolute value of the difference
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

cmp r0, #2
bne End // If not ranged, then skip to the end

@add 15 to ally's hit rate
mov r1, #0x60 
ldrh r0, [r4, r1] @HIT value
mov r2, #0xF
add r0, r2
strh r0, [r4, r1]

End:
pop {r4-r7, r15}

Trampoline:
	bx  r3

.align
.ltorg
AuraSkillCheck:
@Poin AuraSkillCheck
@WORD HuntersSightID

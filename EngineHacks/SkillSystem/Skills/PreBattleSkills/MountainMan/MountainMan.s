.equ MountainManID, SkillTester+4
.equ gBattleData, 0x203a4d4
.thumb
push {r4-r7,lr}
@goes in the battle loop.
@r0 is the attacker
@r1 is the defender
mov r4, r0
mov r5, r1

@ @make sure we're in combat (or battle forecast)
@ ldrb r3, =gBattleData
@ ldrb r3, [r3]
@ cmp r3, #4
@ beq End

@check for skill
ldr r0, SkillTester
mov lr, r0
mov r0, r4
ldr r1, MountainManID
.short 0xf800
cmp r0, #0
beq End

@set bonuses
mov  r0,#0x57     @get the terrain avoid bonuses
ldsb r1,[r4,r0]   @load the value
mov  r0,#0x60     @get the unit's hit value
ldrh r2,[r4,r0]   @load the value
add  r1, r2       @add them together and store in r1
strh r1,[r4,r0]   @now store it the value in the hit value location
b    End

End:
pop {r4-r7}
pop {r0}
bx r0

.ltorg
.align

SkillTester:
@POIN SkillTester
@WORD MountainManID

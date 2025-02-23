.thumb
.equ VeteranAxeID, AuraSkillCheck+4
.equ HITBonus, VeteranAxeID+4
.equ ATKBonus, HITBonus+4

WTYPE_AXE         = 0x02
GetEquippedWeapon = 0x08016B28+1
GetWeaponType     = 0x08017548+1

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
ldr r1, VeteranAxeID
mov r2, #0 @can trade
mov r3, #1 @range
.short 0xf800
cmp r0, #0
beq End

@ Check attacker is using an axe
mov r0, r4
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_AXE
bne End

@ Check defender is using an axe
mov r0, r5
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_AXE
bne End

@add WTA bonuses to ally in range of skill holder
mov r1, #0x54 
ldrb r0, [r4, r1] @WTA damage boost
ldr r2, #ATKBonus
add r0, r2
strb r0, [r4, r1]
mov r1, #0x53
ldrb r0, [r4, r1] @WTA hit boost
ldr r3, #HITBonus
add r0, r3
strb r0, [r4,r1]

mov r1, #0x5A 
ldrb r0, [r4, r1] @ATK
add r0, r2
strb r0, [r4, r1]
mov r1, #0x60
ldrb r0, [r4, r1] @HIT
add r0, r3
strb r0, [r4,r1]

End:
pop {r4-r7, r15}

Trampoline:
	bx  r3

.align
.ltorg
AuraSkillCheck:
@Poin AuraSkillCheck
@WORD VeteranAxeID

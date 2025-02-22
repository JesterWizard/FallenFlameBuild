.thumb
.equ LanceEdgeID, AuraSkillCheck+4

WTYPE_LANCE       = 0x01
WTYPE_SWORD       = 0x00
GetEquippedWeapon = 0x08016B28+1
GetWeaponType     = 0x08017548+1

push {r4-r7, lr}
mov r4, r0 @atkr
mov r5, r1 @dfdr

@check for skill
CheckSkill:
ldr r0, AuraSkillCheck
mov lr, r0
mov r0, r4 @attacker
ldr r1, LanceEdgeID
mov r2, #3 @can't_trade
mov r3, #1 @range
.short 0xf800
cmp r0, #0
beq End

@ Check enemy is using a SWORD
mov r0, r4
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_SWORD
bne End

@subtract +2 battle struct ATK from Sword user
mov r1, #0x5A
ldrsh r0, [r4, r1] @atk
sub r0, #2
strh r0, [r4,r1]

End:
pop {r4-r7, r15}

Trampoline:
	bx  r3

.align
.ltorg
AuraSkillCheck:
@Poin AuraSkillCheck
@WORD LanceEdgeID

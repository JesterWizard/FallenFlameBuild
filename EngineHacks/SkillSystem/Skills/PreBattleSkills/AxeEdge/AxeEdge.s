.thumb
.equ AxeEdgeID, SkillTester+4

WTYPE_AXE         = 0x02
WTYPE_LANCE       = 0x01
GetEquippedWeapon = 0x08016B28+1
GetWeaponType     = 0x08017548+1

push {r4-r7, lr}
mov r4, r0 @atkr
mov r5, r1 @dfdr

@has AxeEdge
ldr r0, SkillTester
mov lr, r0
mov r0, r4 @attacker data
ldr r1, AxeEdgeID
.short 0xf800
cmp r0, #0
beq End

@ Check skill holder is using an axe
mov r0, r4
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_AXE
bne End

@ Check enemy unit is using a lance
mov r0, r5
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_LANCE
bne End

@add +1 battle struct ATK/DEF to skill holder
mov r1, #0x5a
ldrsh r0, [r4, r1] @atk
add r0, #1
strh r0, [r4,r1]
mov r1, #0x5c
ldrsh r0, [r4, r1] @def
add r0, #1
strh r0, [r4,r1]

End:
pop {r4-r7, r15}

Trampoline:
	bx  r3

.align
.ltorg
SkillTester:
@Poin SkillTester
@WORD AxeEdgeID

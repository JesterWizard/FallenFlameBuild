.thumb
.equ LanceEdgeID, SkillTester+4

WTYPE_LANCE       = 0x01
WTYPE_SWORD       = 0x00
GetEquippedWeapon = 0x08016B28+1
GetWeaponType     = 0x08017548+1

push {r4-r7, lr}
mov r4, r0 @atkr
mov r5, r1 @dfdr

@has LanceEdge
ldr r0, SkillTester
mov lr, r0
mov r0, r4 @attacker data
ldr r1, LanceEdgeID
.short 0xf800
cmp r0, #0
beq End

@ Check skill holder is using a lance
mov r0, r4
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_LANCE
bne End

@ Check enemy unit is using an sword
mov r0, r5
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_SWORD
bne End

@add +2 battle struct DEF to skill holder
@ mov r1, #0x5a
@ ldrsh r0, [r4, r1] @atk
@ add r0, #1
@ strh r0, [r4,r1]
mov r1, #0x5c
ldrsh r0, [r4, r1] @def
add r0, #2
strh r0, [r4,r1]

End:
pop {r4-r7, r15}

Trampoline:
	bx  r3

.align
.ltorg
SkillTester:
@Poin SkillTester
@WORD LanceEdgeID

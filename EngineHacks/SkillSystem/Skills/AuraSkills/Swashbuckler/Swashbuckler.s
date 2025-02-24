.thumb
.equ SwashbucklerID, AuraSkillCheck+4

WTYPE_AXE         = 0x02
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
ldr r1, SwashbucklerID
mov r2, #3 @can't_trade
mov r3, #1 @range
.short 0xf800
cmp r0, #0
beq End

@ Check enemy is using a AXE
mov r0, r4
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_AXE
bne End

mov r1, #0x57
ldrb r0, [r4, r1] @terrain avoid bonus
cmp  r0, #1
ble  End 		  @they either have no bonuses or they're already negative, so nothing to reverse
lsl r0, #1 		  @multiply the AVO bonus by 2, easier to add to the other unit's HIT than invert the AVO bonus
mov r1, #0x60
ldrh r3, [r5, r1] @load the defender's hit rate to add the bonus to.
add  r3, r0
strh r3, [r5, r1] @store the result

End:
pop {r4-r7, r15}

Trampoline:
	bx  r3

.align
.ltorg
AuraSkillCheck:
@Poin AuraSkillCheck
@WORD SwashbucklerID

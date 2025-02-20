.thumb

@@jumped to from 2C830
@@r4=attacker, battle struct r5=defender battle struct

@ Now attack struct is passed in via r0 with the defense struct in r1

.equ SuperiorShotID, SkillTester+4

WTYPE_BOW         = 0x03
GetEquippedWeapon = 0x08016B28+1
GetWeaponType     = 0x08017548+1

push       {r4-r6,lr}
mov        r4,r0 @ Attack struct
mov        r5,r1 @ Defense struct

@Skill check on attacker
CheckAttackerSkill:
ldr        r6,SkillTester
mov        r0,r4
ldr        r1,SuperiorShotID
mov        r14,r6
.short    0xF800
cmp        r0,#0
beq        CheckDefenderSkill

@ Check enemy unit is using a bow
CheckDefenderWeapon:
mov r0, r5
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_BOW
bne End

SetAttackerBonus:
mov        r0,#0x53     @WTA hit bonus byte
mov        r1,#0xF      @put regular WTA hit bonus in register
strb       r1,[r4,r0]   @save it in the attacker's battle struct
mov        r0,#0x54     @WTA damage bonus byte
mov        r1,#1        @put regular WTA damage bonus in register
strb       r1,[r4,r0]   @save it in the attacker's battle struct

SetDefenderNerf:
mov        r6,#0        @set to 0 as we'll be subtracting bonuses from this to make them negative
mov        r0,#0x53
mov        r1,#0xF
sub        r1,r6,r1
strb       r1,[r5,r0]
mov        r0,#0x54
mov        r1,#1
sub        r1,r6,r1
strb       r1,[r5,r0]

@Skill check on defender
CheckDefenderSkill:
ldr        r6,SkillTester
mov        r0,r5
ldr        r1,SuperiorShotID
mov        r14,r6
.short    0xF800
cmp        r0,#0
beq        End

@ Check enemy unit is using a bow
CheckAttackerWeapon:
mov r0, r4
ldr r3, =GetEquippedWeapon
bl Trampoline
ldr r3, =GetWeaponType
bl Trampoline
cmp r0, #WTYPE_BOW
bne End

SetDefenderBonus:
mov        r0,#0x53     @WTA hit bonus byte
mov        r1,#0xF      @put regular WTA hit bonus in register
strb       r1,[r5,r0]   @save it in the attacker's battle struct
mov        r0,#0x54     @WTA damage bonus byte
mov        r1,#1        @put regular WTA damage bonus in register
strb       r1,[r5,r0]   @save it in the attacker's battle struct

SetAttackerNerf:
mov        r6,#0        @set to 0 as we'll be subtracting bonuses from this to make them negative
mov        r0,#0x53
mov        r1,#0xF
sub        r1,r6,r1
strb       r1,[r4,r0]
mov        r0,#0x54
mov        r1,#1
sub        r1,r6,r1
strb       r1,[r4,r0]

End:
pop        {r4-r6}
pop        {r0}
bx         r0

Trampoline:
	bx  r3

.ltorg
.align

SkillTester:
@POIN SkillTester
@WORD SuperiorShotID

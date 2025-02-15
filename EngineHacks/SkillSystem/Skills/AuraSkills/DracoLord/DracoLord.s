.equ DracoLordID, AuraSkillCheck+4
.thumb
push {r4-r7,lr}
@goes in the battle loop.
@r0 is the attacker
@r1 is the defender
mov r4, r0
mov r5, r1

CheckSkill:
@now check for the skill
ldr r0, AuraSkillCheck
mov lr, r0
mov r0, r4 @attacker
ldr r1, DracoLordID
mov r2, #3 @are enemies
mov r3, #3 @range
.short 0xf800
cmp r0, #0
beq End

mov r0, r4          @move attacker into r0
ldr r0, [r4, #4]    @load their class struct
ldrb r0, [r0, #4]   @load the class id byte
cmp r0, #0x1F       @is wyvern rider (male)?
beq ApplySkill
cmp r0, #0x20       @is wyvern rider (female)?
beq ApplySkill      
cmp r0, #0x21       @is wyvern lord (male)?
beq ApplySkill
cmp r0, #0x22       @is wyvern lord (female)?
beq ApplySkill
cmp r0, #0x23       @is wyvern knight (male)?
beq ApplySkill
cmp r0, #0x24       @is wyvern knight (female)?
beq ApplySkill
cmp r0, #0x3B       @is manakete (Myrrh)?
beq ApplySkill
cmp r0, #0x3C       @is manakete (morva)?
beq ApplySkill
cmp r0, #0x65       @is draco zombie?
b   End             @unit is none of these clases, so branch to the end

ApplySkill:
mov r0, r4
add r0, #0x5c    @attacker defense
ldrh r3, [r0]
sub r3, #4
strh r3, [r0]
mov r0, r4
add r0,#0x5A     @Move to the attacker's damage.
ldrh r3,[r0]     @Load the attacker's damage into r3.
sub  r3,#4       @subtract 4 damage.
strh r3,[r0]     @Store dmg.

End:
pop {r4-r7}
pop {r0}
bx r0
.align
.ltorg
AuraSkillCheck:
@ POIN AuraSkillCheck
@ WORD DracoLordID

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
	
.set MaxRangeBonus, 0xF
push 	{lr}
add 	sp, #-0x4
str 	r2, [sp]
mov 	r0, r1

AddRangeBonus:
mov 	r2, sp
ldrh 	r0, [r2]
mov 	r0, #MaxRangeBonus

@prevent the maximum range from going over 15
cmp 	r0, #0xF
bls NotOverMax
mov 	r0, #0xF
NotOverMax:
strh 	r0, [r2]

End:
ldr 	r0, [sp]
add 	sp, #0x4
pop 	{r3}
bx 	r3
.ltorg
.align

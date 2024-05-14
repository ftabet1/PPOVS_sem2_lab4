	.def _c_int00
	.mmregs
	.text
_c_int00:
	ld	#d3n, dp
	stm 	#stack, SP 	;stack init 
	ssbx	frct
	ssbx	ovm
	ssbx	sxm
	orm	#1, PMST
	nop
	
	stm #gar, AR7
main_loop:
	;init calc_arg args
  	stm #C1,  AR2	;AR2 - const cos(a)
  	stm #S1,  AR3	;AR3 - const sin(a)
  	stm #arg, AR4	;AR4 - argument value
  	stm #m	, AR5	;AR5 - M value
  	call calc_arg
  	
  	;init calc_harm args
  	;addm #1, C1
  	nop
  	stm #C1, AR2	;AR2 - const cos(a)
  	stm #S1, AR3	;AR3 - const sin(a)
  	stm #Cn, AR4	;AR4 - current cos(a+nk) tick
  	stm #Sn, AR5	;AR5 - current sin(a+nk) tick
  	mvdm #gar, AR1	;AR1 - counter reg.; Harmonic count value
  	call calc_harm	;call
  	
  	;init calc_sig args
  	stm #xn, AR6	;AR6 - signal array pointer
  	stm #N-1, AR1	;AR1 - counter reg.; Number of tick's
  	call calc_sig	;call
	
	rsbx	ovm
	nop
	
	;start iir
	stm	#d3n, ar2
	rptz	A, #8
	stl	A, *ar2+
	
	stm	#N, ar1
	stm	#yn, ar3
	stm	#xn, ar4
	ld	*ar4+, A
	call	loop_iir
	
	addm #2, *AR7
	XOR B, B
	ld *AR7, 16, B
	add #-200, 16, B
	nop
	xc 2, BGT
	b loop
	
	b main_loop
	;while(true)
loop:
  	b loop	
;main end


loop_iir:	
	;d1(n)
	ld	*ar4+, 16, A
	ld	d1nm1, T
	mas	b11, A
	mas	b11, A
	ld	d1nm2, T
	masr	b21, A
	sth	A, d1n
	;y1(n)
	mpy	a21, A
	ltd	d1nm1
	mac	a11, A
	ltd	d1n
	mac	a01, A
	;d2(n)
	ld	d2nm1, T
	mas	b12, A
	mas	b12, A
	ld	d2nm2, T
	masr	b22, A
	sth	A, d2n
	;y2(n)
	mpy	a22, A
	ltd	d2nm1
	mac	a12, A
	ltd	d2n
	mac	a02, A
	;d3(n)
	ld	d3nm1, T
	mas	b13, A
	mas	b13, A
	ld	d3nm2, T
	masr	b23, A
	sth	A, d3n
	;y(n)
	mpy	a23, A
	ltd	d3nm1
	mac	a13, A
	ltd	d3n
	mac	a03, A
	
	sth	a, *ar3+
	banz	loop_iir, *ar1-
	ret


;calc_arg func. begin
calc_arg:
	ld *AR4, 16, A
	exp a		;check zeros
  	st  T, temp	;save T
  	ld  temp, A	;load T to A
  	sub #5, A	;A -= 5
  	stl A, temp	;save A
  	neg A
  	stl A, m	;save m value
  	ld temp, T	;load A to T
  	ld *AR4, 16, A	;load arg to a
  	norm A		;norm a to threshold
  	;now sin(arg)=arg (acc. A)
  	sth  A, *AR3 ;save sin(a)
  	
  	;cos(a) first calc begin
  		squr A, A
  		sfta A, -1
  		sth  a, temp
  		ld #0x7FFF, A
  		sub temp, A
  	;end	
  	nop
  	stl  A, *AR2 ;save cos(a)
  	
  	ld m, B
  	xc 2, BGT
  		call sin_recovery
	ret

;alg begin
sin_recovery:
	sub #1, B
	stlm B, AR1
	nop
sin_rec_loop:
		ld  *AR3, 16, B
		mpy *AR3, *AR2, A
		sfta A, 1
		sth  A, *AR3	;sin(2a)
		
		ld B, A
		squr A, B
		sfta B, 1
		sth  B, temp
		ld #0x7FFF, B
		sub temp, B
		stl B, *AR2	;cos(2a)
		
		banz sin_rec_loop, *AR1-
	ret
;alg_end

;calc_arg func. end


;calc_harm func. begin
calc_harm:
		mpy *AR3, *AR4, A	;A =  sin(a) * cos(an)
  		macr *AR2, *AR5, A	;A += cos(a) * sin(an)
  		mpy *AR2, *AR4, B	;B =  cos(a) * cos(an)
  		masr *AR3, *AR5, B	;B -= sin(a) * sin(an)
  		sth A, *AR5 	;save Sn
  		sth B, *AR4 	;save Cn
  	banz calc_harm, *AR1-	;loop

  	mvdd *AR5, *AR3		;save calculated sin value
  	mvdd *AR4, *AR2		;save calculated cos value
  	st #0, *AR5		;reset sin(0) value
  	st #0x7FFF, *AR4	;reset cos(0) value
  	RET 
;calc_harm func. end


;calc_sig func. begin
calc_sig:
  		mpy *AR3, *AR4, A	;A =  sin(a) * cos(an)
  		macr *AR2, *AR5, A	;A += cos(a) * sin(an)
		mpy *AR2, *AR4, B	;B =  cos(a) * cos(an)
		masr *AR3, *AR5, B	;B -= sin(a) * sin(an)
  		sth A, *AR5 ;Sn
  		sth B, *AR4 ;Cn
  		sfta A, #-4
  		sth A, *AR6+		;save current sine value
  	banz calc_sig, *AR1-	;loop
  	st #0, *AR5		;reset sin(0) value
  	st #0x7FFF, *AR4	;reset cos(0) value
  	RET
;calc_sig func. end  

	.align
	.data
;----------------------------------
;********intermediate value********
d3n	.word	0x0000
d3nm1	.word	0x0000
d3nm2	.word	0x0000

d2n	.word	0x0000
d2nm1	.word	0x0000
d2nm2	.word	0x0000

d1n	.word	0x0000
d1nm1	.word	0x0000
d1nm2	.word	0x0000	
;----------------------------------


;----------------------------------
;***************coefs**************
a01	.word	0x072A
a11	.word	0x851F
a21	.word	0x072B
b11	.word	0x4C0B ;x2
b21	.word	0x32B5

a02	.word	0x198A
a12	.word	0xF02A
a22	.word	0x198A
b12	.word	0x44F9 ;x2
b22	.word	0x4C65

a03	.word	0x3331
a13	.word	0xFCF1
a23	.word	0x3333
b13	.word	0x41A5 ;x2
b23	.word	0x6DF4
;----------------------------------

N 	 .set  	2048	;number of sine tick's

;----------------------------------
;*************signals**************
xn	.space (N*16)
yn	.space ((N+40)*16)
;----------------------------------

gar 	 .word 	0x0001	;harm. number	
temp	 .word	0x0000  ;temp for thmsng
arg	 .word 	0x0405  ;sine argument value
m	 .word	0x0000	;m-value to calculate sin(a) value
S1 	 .word  0x0000  ;sin(a) const. value
C1 	 .word  0x0000	;cos(a) const. value
Sn 	 .word  0x0000	;sin(an) value
Cn       .word  0x7FFF	;cos(an) value
Cnt	 .word	0x0001  ;
sig 	 .space  (N*8*2)	;signal tick's array
stack .bes  (512*8*2)		;stack region
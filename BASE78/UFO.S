*	    2035    030784
*
*
** UFO.S **
** ASTEROIDS FOR THE ATARI 3600 **
** THIS FILE CONTAINS THE UFO HANDLING ROUTINE **
**
** TRASHES: X, Y, AC AND FIRST 7 BYTES OF TEMP.

URTS:
	RTS
UFO:
	LDA	STATUS+25	;CHECK STATUS OF UFO
	BMI	TOOFAR
	JMP	NOTNEW		;DON'T INITIALIZE IF ALREADY EXISTS
TOOFAR:
	CMP	#$FF		;IF HE'S BLOWING UP, DO NOTHING TILL
	BNE	URTS		; HE'S DEAD.

	LDA	DIFF		;IF NOVICE THEN NO UFO
	BEQ	URTS
	LDA	MODE		;CHECK STATUS OF SHIPS
	CMP	#1
	BMI	NOTTEAM
	LDA	STATE
	AND	STATE+1
	BNE	URTS

	BEQ	BRINGOUT	;BEQ = JMP

NOTTEAM:
	LDX	PLAYER
	LDA	STATE,X
	BNE	URTS

BRINGOUT:
	LDA	FRMCNT		;EVERY FORTH FRAME
	AND	#2
	BNE	URTS

	LDX	PLAYER
	LDA	ROCKTOT,X	;DON'T BRING OUT UFO IF NO ROCKS.
	BEQ	URTS

	LDY	RTIMER		;DEC RTIMER, BUT PEG AT ZERO
	BEQ	Z2
	DEC	RTIMER
Z2:
	DEC	EDELAY
	BNE	URTS
	INC	EDELAY		;HOLD AT ONE

	CPY	#0		;DON'T CARE NUM ROCKS IF RTIMER=0
	BEQ	LOGG
	CMP	STARTNUM,X	;OR OVER NUMBER TO START
	BCS	URTS

	;NEW UFO TIME!
LOGG:
	LDA	SDELAY		;EVERY TIME UFO GOES REDUCE SDELAY
	SEC
	SBC	#6
	CMP	#20
	BCC	DIES
	STA	SDELAY
DIES:
	LDA	SDELAY
	STA	EDELAY

	LDA	#$15		;INITIALIZE SHOT REPEATER
	STA	USHOTCNT

	JSR	NEWRAND		;SET Y POSITION TO RANDOM #
	LSR			; BETWEEN $10 AND $10+$7F
	ADC	#$10		; (KEEP AWAY FROM TOP AND BOTTOM)
	STA	YPOSH+25

	LDX	PALTAB+25	;LOADER MUST USE CORRECT PAL/WIDTH
	LDA	MODE
	CMP	#1
	BNE	ONE
	LDY	#8
	BPL	TWO
ONE:
	LDA	PLAYER	; CHECK SCORE
	ASL
	ASL
	TAY
TWO:
	LDA	SCORE+1,Y
	CMP	#2
	BCS	MRBILL		; IF MORE THAN 30K THAN MR BILL
	LDA	SDELAY		;IF SDELAY IS BIG THEN SLUGGO
	BMI	SLUGGO
	JSR	NEWRAND
	STA	TEMP
	LDA	SDELAY
	LSR
	CMP	TEMP
	BCS	SLUGGO
MRBILL:
	INX			;ADD ONE FOR SMALLER WIDTH STAMP
	LDY	#SMALLUFO
	BNE	NEWUFO		;UNCONDITIONAL BRANCH
SLUGGO:
	LDY	#LARGEUFO

NEWUFO:
	STY	STATUS+25
	STX	PALS+25
	JSR	NEWRAND		;GOING RIGHT OR LEFT?
	LSR			; SHIFT A RANDOM BIT INTO CARRY
	BCC	GORIGHT		; IF BIT 0, GO RIGHT TO LEFT
	LDA	#XPOSMAX+4	; ELSE LEFT TO RIGHT.
	STA	XPOSH+25
	LDA	#(-1)&255	; XVEL -1 = LEFT TO RIGHT.
	BMI	STORXVEL
GORIGHT:
	LDA	#(XPOSMIN-4)&255
	STA	XPOSH+25
	LDA	#1		; XVEL 1 = RIGHT TO LEFT
STORXVEL:
	STA	XVELH+25
	LDA	#0		; LO BYTE OF XVEL SET TO ZERO
	STA	XVELL+25
	BEQ	ZYVEL		;INITIALLY UFO HAS ZERO Y VELOCITY

NOTNEW:
	LDA	FRMCNT
	CMP	#$FE
	BCC	NOCHNGY		;CHANGE Y VELOCITY ONLY PERIODICALLY
	LDA	DIFF		;FOR INTER ALWAYS STRAIGHT ACROSS
	CMP	#1
	BEQ	ZYVEL
	JSR	NEWRAND		;GET NEW RANDOM VALUE
	CMP	#$AA	
	BCS	MOVEDN		;ONE THIRD OF THE TIME MOVE DOWN
	CMP	#$55
	BCS	MOVEUP		;ONE THIRD MOVE UP
	;DON'T GO STRAIGHT IF TOO CLOSE TO TOP OR BOTTOM: AVOID CLIPPED UFO
	LDA	YPOSH+25
	CMP	#YPOSMAX-20
	BCS	NOCHNGY
	CMP	#YPOSMIN+10
	BCC	NOCHNGY
ZYVEL:
	LDA	#0		;ONE THIRD GO STRAIGHT ACROSS
	STA	YVELH+25
	STA	YVELL+25
	BEQ	NOCHNGY
MOVEDN:
	LDA	#(-1)&255
	BMI	STORYVEL	;BMI = JMP
MOVEUP:
	LDA	#1
STORYVEL:
	STA	YVELH+25	;STORE Y VELOCITY
	LDA	#0
	STA	YVELL+25
NOCHNGY:
	LDA	XVELH+25	;CHECK IF UFO GOES OFF THE SCREEN
	CLC
	ADC	XPOSH+25
	CMP	#XPOSMAX+4	;UFO GOES PAST RIGHT?
	BCC	UCHKSHOT	; NO.  CHECK IF HE MAY SHOOT.
	CMP	#(XPOSMIN-3)&255	;UFO GOES PAST LEFT?
	BCS	UCHKSHOT	; NO.  CHECK IF HE MAY SHOOT.
UFODONE:
	LDA	#$FF		;UFO HAS GONE OFF SCREEN: NUKE HIM
	STA	STATUS+25
	LDA	#$08		;KILL UFO TUNES
	JSR	KILLTUNE
	LDA	#$09
	JSR	KILLTUNE
	RTS

* CHECK TO SEE IF WE SHOULD FIRE NOW
UCHKSHOT:
	LDX	#1		;HAVE 2 UFO SHOTS TO USE
UFOSHOT:
	LDA	STATUS+26,X	;TEST SHOT STATUS
	BMI	ADDUSHOT	;SEE IF SHOT IS ALREADY ON SCREEN
	DEX			;YES, TRY OTHER SHOT
	BPL	UFOSHOT
	BMI	UANIMATE	;NO MORE SHOTS, JUMP TO VARY STAMPS

ADDUSHOT:
	DEC	USHOTCNT	;CHECK COUNTER FOR NEXT SHOT
	BNE	UANIMATE	;NOT TIME YET, JUMP TO VARY STAMPS
	LDA	#$20		;RESET COUNTER
	STA	USHOTCNT
	LDA	#SHOT		;STORE STATUS AS SHOT
	STA	STATUS+26,X
	LDA	#$EC		;STORE COUNTER VALUE
	STA	SHOTCNT,X
	LDA	COLXPOSH+25	;STORE SHOT POSITION AS CENTER OF UFO
	CMP	#XPOSMAX
	BCC	USTXPOS
	SBC	#XPOSMAX
USTXPOS:
	STA	XPOSH+26,X
	LDA	COLYPOSH+25
	CMP	#YPOSMAX
	BCC	USTYPOS
	SBC	#YPOSMAX
USTYPOS:
	STA	YPOSH+26,X
	LDA	#00
	STA	XPOSL+26,X
	STA	YPOSL+26,X

	LDA	STATUS+25	;DETERMINE HOW TO SHOOT
	CMP	#SMALLUFO
	BEQ	AIMSHOT		;MR. BILL AIMS HIS SHOTS
	JSR	NEWRAND		;SLUGGO IS RANDOM
USHOOT:
	AND	#$1F
	TAY
	LDA	HUSHVCTX,Y
	STA	XVELH+26,X
	LDA	USHVCTX,Y
	STA	XVELL+26,X
	LDA	HUSHVCTY,Y
	STA	YVELH+26,X
	LDA	USHVCTY,Y
	STA	YVELL+26,X
	LDA	#$0D		;PLAY UFO SHOT SOUND
	JSR	DOTUNE

UANIMATE:
	LDA	FRMCNT		;VARY UFO STAMPS WITH TIME
	LSR
	LSR
	AND	#$3		;MASK ALL BUT 2 LSBITS

	LDY	STATUS+25	;WHICH TYPE?
	CPY	#SMALLUFO
	BEQ	UANIMSM
	ASL			;BIG UFO HAS 2 BYTES PER ANIMATION
	CLC
	ADC	#UFOL1 & 255	;ADD IN POINTER TO BASE OF LARGE UFO
	JMP	USTACYC
UANIMSM:
	CLC
	ADC	#UFOS1 & 255
USTACYC:
	STA	ACYC+25		;STORE ANIMATION FRAME POINTER
	RTS

AIMSHOT:
* INITIALIZE FLAGS FOR OCTANT SELECTION
	LDA	#0
	STA	TEMP+2		;UDXNEG
	STA	TEMP+3		;UDYNEG
	STA	TEMP+4		;UDIAGNEG

* DETERMINE WHICH SHIP TO SHOOT AT
	LDA	MODE
	CMP	#1
	BMI	ZNOTTEAM	;ISSOLATE CASE OF TEAM PLAY

ZTEAM:
	LDA	STATE		;SEE IF BOTH ALIVE
	AND	STATE+1
	BEQ	PICKSRAN
	LDA	STATE		;NO, SEE WHICH IS, KNOW AT LEAST 1 IS
	BNE	AIMSHIP2

AIMSHIP1:
	LDY	#0		;AIM AT SHIP 1
	BPL	COMPVECT	;BPL = JMP

PICKSRAN:
	JSR	NEWRAND		;PICK A SHIP RANDOMLY
	ASL			;WE'RE SUCH ASL'S
	BCC	AIMSHIP1

AIMSHIP2:
	LDY	#8		;AIM AT SHIP 2
	BPL	COMPVECT	;BPL = JMP HERE

ZNOTTEAM:
	LDY	OFFPLAY2

* COMPUTE VECTORS
COMPVECT:
	LDA	COLXPOSH+24,Y
	SEC
	SBC	COLXPOSH+25	;SUBTRACT UFO'S POSITION TO GET 'DX'
	BCS	UDXPOS
	INC	TEMP+2
	EOR	#$FF
;	CLC			;CARRY IS CLEAR ALREADY
	ADC	#1
UDXPOS:
	STA	TEMP		;SAVE DX

	LDA	COLYPOSH+24,Y
	SEC
	SBC	COLYPOSH+25	;SUBTRACT UFO'S POSITION TO GET 'DY'
	BCS	UDYPOS
	INC	TEMP+3
	EOR	#$FF
;	CLC
	ADC	#1
UDYPOS:
	STA	TEMP+1		;SAVE DY

* NORMALIZE VECTOR TO CORRECT FOR ASPECT RATIO.  WE ALSO SCALE DOWN TO AVOID
* OVERFLOW.  ALSO, FLIP THE VECTOR TO THE FIRST OCTANT (ABOVE THE LINE Y = X).
	LSR			;5/8 = 1/2 + 1/8
	STA	TEMP+5
	LSR
	LSR
	CLC
	ADC	TEMP+5
	CMP	TEMP
	BCS	UDIAGOK		;ON CORRECT SIDE OF DIAGONAL Y = X.
	INC	TEMP+4		;NOT ON CORRECT SIDE:
	TAY			; SWAP DX AND DY
	LDA	TEMP
	STY	TEMP
UDIAGOK:
	LSR			;SCALE    DY <- DY / 4
	LSR
	STA	TEMP+1

* COMPUTE AND SAVE "3/8 DX", TO BE USED BELOW.
	LDA	TEMP		;TEMP+6 <- DX/4 + DX/8
	LSR
	LSR
	STA	TEMP+5
	LSR
	CLC
	ADC	TEMP+5
	STA	TEMP+6

* COMPUTE CORRECT SECTOR (32TH OF CIRCLE) IN Y.
* FIRST, FIGURE OUT WHICH 16TH OF THE CIRCLE.
* WE USE THE 68.2 DEGREE LINE, 'CAUSE IT'S EASIER TO COMPUTE (ATAN(5/8 / 2/8)).
	LDA	TEMP		;5/8 = 1/2 + 1/8
	LSR
	STA	TEMP+5
	LSR
	LSR
	CLC
	ADC	TEMP+5

	LDY	#0
	CMP	TEMP+1
	BCC	SECTOR01
	LDY	#2		;SECTOR 2 OR 3
	LDA	#0
	BEQ	SECTOR23	;UNCONDITIONAL BRANCH
SECTOR01:
	LDA	TEMP
SECTOR23:
	CLC
	ADC	TEMP+6		;1 +  3/8 = 11/8
	CMP	TEMP+1
	BCC	SECTOR02
SECTOR13:
	INY
SECTOR02:
	STY	TEMP

* UNFOLD VECTOR INTO CORRECT OCTANT, QUADRANT AND HALF-SPACE
	LDY	TEMP+4		;CHECK UDIAGNEG
	BEQ	NODIAGN
	LDA	#7
	SEC
	SBC	TEMP
	STA	TEMP
NODIAGN:
	LDY	TEMP+3		;CHECK UDYNEG
	BEQ	NODYNEG
	LDA	#15
	SEC
	SBC	TEMP
	STA	TEMP
NODYNEG:
	LDY	TEMP+2		;CHECK UDXNEG
	BEQ	NODXNEG
	LDA	#31
	SEC
	SBC	TEMP
	STA	TEMP
NODXNEG:
	; PERTERB VECTOR BY RANDOM NUMBER OF INDEX NOTCHES.
	LDA	UFOACC		;COMPUTE UFOACC / 2
	LSR
	STA	TEMP+6

UTOOPOOR:
	JSR	NEWRAND
	LDY	TEMP+6
	AND	UFOPMASK-1,Y	;TABLE IS 1-ORIGIN (Y > 0)
	CMP	UFOACC
	BCS	UTOOPOOR	;TOO POOR A SHOT, TRY AGAIN

;	CLC			;CARRY IS CLEAR
	ADC	TEMP		;ADD TO PRECISE VECTOR
	SEC
	SBC	TEMP+6		;SUBTRACT UFOACC/2 (OFFSET)
	JMP	USHOOT

UFOPMASK:
	.DC.B	$03,$07,$07,$0F	;RANGE MASKS FOR RANDOM #'S


* UFO SHOT VECTORS.
HUSHVCTX:
	.DC.B	$00,$00,$01,$02,$03,$03,$04,$04
	.DC.B	$04,$04,$04,$03,$03,$02,$01,$00
	.DC.B	$00,$FF,$FE,$FD,$FC,$FC,$FB,$FB
	.DC.B	$FB,$FB,$FB,$FC,$FC,$FD,$FE,$FF

USHVCTX:
	.DC.B	$00,$DB,$AD,$6E,$18,$A3,$0B,$4A
	.DC.B	$60,$4A,$0B,$A3,$18,$6E,$AD,$DB
	.DC.B	$00,$26,$54,$93,$E9,$5E,$F6,$B7
	.DC.B	$A1,$B7,$F6,$5E,$E9,$93,$54,$26

HUSHVCTY:
	.DC.B	$07,$06,$06,$05,$04,$03,$02,$01
	.DC.B	$00,$FE,$FD,$FC,$FB,$FA,$F9,$F9
	.DC.B	$F9,$F9,$F9,$FA,$FB,$FC,$FD,$FE
	.DC.B	$00,$01,$02,$03,$04,$05,$06,$06

USHVCTY:
	.DC.B	$00,$DE,$78,$D2,$F3,$E4,$AE,$5E
	.DC.B	$00,$A3,$53,$1D,$0E,$2F,$89,$23
	.DC.B	$01,$23,$89,$2F,$0E,$1D,$53,$A3
	.DC.B	$00,$5E,$AE,$E4,$F3,$D2,$78,$DE

	.DC.B	$01,$23,$89,$2F,$0E,$1D,$53,$A3
	.DC.B	$00,$5E,$AE,$E4,$F3,$D2,$78,$DE


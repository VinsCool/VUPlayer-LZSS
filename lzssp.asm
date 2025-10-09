;* Main code and data structure needed for Building VUPlayer, most of the operations are handled by the Makefile script
;* To Build: Make sure MADS is assigned to PATH, then Run 'make' in the project folder, and that should do the trick
;* If everything went well, Object files will first be Assembled, then Linked to the finished Executable Atari Binary
;* Note that currently, VUPlayer is assuming the target machine is the Atari 800xl or better, at least for now
;* This is only a technicality, simply because this is the only machine I have at my disposal for proper hardware tests

;-----------------

;//---------------------------------------------------------------------------------------------

	opt H+ R- F-
	icl "Global.def"
	
;-----------------

.if (OPTION == 1)		;* LZData
	org LZDATA
	icl "SongIndex.asm"
LZDATAEND
	
	.echo "> LZDATA size of ", LZDATAEND - LZDATA, ", from ", LZDATA, " to ", LZDATAEND
	
;-----------------

.elseif (OPTION == 2)		;* Relocator
	org RELOCATOR
	sei
	cld
	mva #%00000000 NMIEN
	mva #%11111110 PORTB
	
RELOCATORHIJACK
	;* JMP to Run Address will be written here
	mva #$4C RELOCATORHIJACK
	mwa ORG_ADDRESS+6 RELOCATORHIJACK+1
	mwa #ORG_ADDRESS+12 RELOCATORFROM+1
	mwa ORG_ADDRESS+8 RELOCATORTO+1
	sec
	lda ORG_ADDRESS+10
	sbc ORG_ADDRESS+8
	eor #%11111111
	tax
	lda ORG_ADDRESS+11
	sbc ORG_ADDRESS+9
	eor #%11111111
	tay
		
RELOCATORLOOP
RELOCATORFROM
	lda $FFFF
RELOCATORTO
	sta $FFFF
	inc RELOCATORFROM+1
	sne:inc RELOCATORFROM+2
	inc RELOCATORTO+1
	sne:inc RELOCATORTO+2
	inx
	sne:iny
	bne RELOCATORLOOP
	mva #%11111111 PORTB
	mva #%11000000 NMIEN
	cli
	rts
RELOCATOREND
	
	.echo "> RELOCATOR size of ", RELOCATOREND - RELOCATOR, ", from ", RELOCATOR, " to ", RELOCATOREND
	
;-----------------

.elseif (OPTION == 3)		;* VUPlayer
	run VUPLAYER
	org DRIVER
VUFONT
	ins "font.fnt"
VUDATA
	icl "VUData.asm"
VUPLAYER
	icl "VUPlayer.asm"
PLAYLZ16
	icl "playlzs16-dumb.asm"
VUPLAYEREND
	
	.echo "> DRIVER size of ", VUPLAYEREND - DRIVER, ", from ", DRIVER, " to ", VUPLAYEREND
	.echo "> Run Address at ", VUPLAYER
	
;-----------------

.elseif (OPTION == 4)		;* PlayLZ16 (Minimal Driver, TODO later)

	.echo "> Not yet implemented..."
	
;-----------------

.elseif (OPTION == 5)		;* MergeXEX
	opt H-
	ins "/ASSEMBLED/Relocator.obx"
	opt H+
	run RELOCATOR
	org ORG_ADDRESS
	ins "/ASSEMBLED/VUPlayer.obx"
	ini RELOCATOR
	opt H-
	ins "/ASSEMBLED/LZData.obx"
	
	.echo "> Object Files Linked and Assembled to the Executable Atari Binary"
	.echo "> VUPlayer was built successfully!"
	
;-----------------

.elseif (OPTION == 6)		;* MergeSAP (Using PlayLZ16, TODO later)

	.echo "> Not yet implemented..."
	
;-----------------

.endif

;-----------------

;//---------------------------------------------------------------------------------------------


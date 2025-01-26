;* When used in a project, the LZSS driver must be assembled from this file!
;* Include everything needed below, and edit accordingly.

;-----------------

;//---------------------------------------------------------------------------------------------

.def INVALID = -1
.def TRUE = 1
.def FALSE = 0
.def NULL = 0

;SAP_BINARY		equ 0		; 0 == XEX (VUPlayer-LZSS), 1 == SAP (Minimal LZSS Driver)

;* ORG addresses can always be changed based on how memory is layed out, as long as it fits, it should work fine

ZEROPAGE		equ $0080
STACK			equ $0100
;LZDATA			equ $2000
;RELOCATOR		equ STACK
;DRIVER			equ $D800
;BUFFERS		equ $ED00

;* Screen line for synchronization, important to set with a good value to get smooth execution

VLINE			equ 22
VBLANK_SCANLINE		equ (248 / 2)
PAL_SCANLINE		equ (312 / 2)
NTSC_SCANLINE		equ (262 / 2)

;* Rasterbar

RASTERBAR_TOGGLE	equ %10000000	; Bit 7 -> Toggle on/off
RASTERBAR_COLOUR	equ $69		; $69 is a nice purpleish hue

;* Default Subtune to be played upon loading

TUNE_DEF		equ 0
;TUNE_NUM		equ [(SongTableEnd - SongTable) / 8]

;-----------------

;//---------------------------------------------------------------------------------------------

	opt H+ R- F-
	icl "atari.def"
	
	org ZEROPAGE
	icl "lzsspZP.asm"
	
	org BUFFERS
	.ds ((2 * 9) * 256)
	
	.if (OPTION == 1)		;* LZData
		org LZDATA
		icl "SongIndex.asm"
		
		.echo "> LZDATA size of ", * - LZDATA, ", from ", LZDATA, " to ", *
	
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
RELOCATORFROM	lda $FFFF
RELOCATORTO	sta $FFFF
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
		
		.echo "> RELOCATOR size of ", * - RELOCATOR, ", from ", RELOCATOR, " to ", *
	
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
DRIVEREND
		
		.echo "> DRIVER size of ", * - DRIVER, ", from ", DRIVER, " to ", *
		.echo "> Run Address at ", VUPLAYER
			
	.elseif (OPTION == 4)		;* PlayLZ16 (Minimal Driver, TODO later)
	
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
		
	.elseif (OPTION == 6)		;* MergeSAP (Using PlayLZ16, TODO later)
	
	.endif

;* Original Assembly Configuration

/*
	icl "atari.def"
	org ZEROPAGE
	icl "lzsspZP.asm"
	
	.if (SAP_BINARY)
		opt H-
		icl "sap.asm"
	.endif

	opt H+ R- F-
	org DRIVER
	
	.if (SAP_BINARY)
		icl "LZSS_SAP.asm"
	.else
VUFONT
		ins "font.fnt"
VUDATA
		icl "VUData.asm"
VUPLAYER
		icl "VUPlayer.asm"
		run VUPLAYER
	.endif
	
PLAYLZ16
	icl "playlzs16-dumb.asm"
	
	org LZDATA
	icl "SongIndex.asm"
	
	org BUFFERS
	.ds ((2 * 9) * 256)
*/

;-----------------

;//---------------------------------------------------------------------------------------------


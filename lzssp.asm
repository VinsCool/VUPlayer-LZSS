;* Assemble from this file!
;* Include everything needed below

		OPT R+ F-
		icl "atari.def"

;//---------------------------------------------------------------------------------------------

ZEROPAGE	equ $0000		; Zeropage
DRIVER		equ $1000		; Unrolled LZSS driver by rensoupp
VUPLAYER	equ $1C00		; VUPlayer by VinsCool
FONT    	equ $2800       	; Custom font 
VUDATA 		equ $2C00		; Text and data used by VUPlayer
SONGINDEX	equ $2F00		; Songs index, alligned memory for easier insertion from RMT
SONGDATA	equ $3000		; Songs data, alligned memory for easier insertion from RMT

;//---------------------------------------------------------------------------------------------

		ORG ZEROPAGE
.PAGES 1
                icl "lzsspZP.asm"
.ENDPG

;//---------------------------------------------------------------------------------------------

;* The unrolled LZSS driver + Buffer will be inserted here first

		org DRIVER
                icl "playlzs16u.asm"

;//---------------------------------------------------------------------------------------------
                
;* VUPlayer will now be inserted here, and be the main program running, calling the LZSS driver when needed

 		org VUPLAYER
		icl "VUPlayer.asm"
		
        	org FONT 
        	ins "font.fnt" 		
		
		org VUDATA
		icl "VUData.asm"
		
		run start		; set run address to VUPlayer in this case

;//---------------------------------------------------------------------------------------------

;* Songs index and data will be inserted here, after everything else, that way they are easy to modify externally

		org SONGINDEX	
		icl "SongIndex.asm"

		org SONGDATA 
		icl "SongData.asm"

;//---------------------------------------------------------------------------------------------


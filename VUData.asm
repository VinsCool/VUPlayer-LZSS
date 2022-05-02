;* Text strings, each line holds 40 characters, running in mode 2, line 5 is toggled with the SHIFT key
;* Volume bars and POKEY registers are 20 characters per line, running in mode 6, either is toggled with the 'R' key
;* TODO: add a help/about pageflip for more details and credits 

; topmost line, displays region and speed 

line_0	dta d"                                        "

;* debug display
;line_0	dta d"             VCOUNT: 00 SCANLINES: 00   "

; volume bars, mode 6, 4 lines

mode_6	dta d"                    "
mode_6a	dta d"                    "
mode_6b	dta d"                    "
mode_6c	dta d"                    "

; POKEY registers, mode 6, 4 lines

POKE1	dta d"  POKEY REGISTERS   "
POKE2	dta d"AUDF $00 $00 $00 $00"
POKE3	dta d"AUDC $00 $00 $00 $00"
POKE4	dta d"AUDCTL $00 SKCTL $00"

; topmost border, under the volume bars, back to mode 2

mode_2d dta $43,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
	dta $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$41 

; timer, order, row, etc display

line_0a	dta $44 
;	dta d" Time: 00:00  Spd: 00 Ord: 00 Row: 00 "
	dta d" Time: 00:00 S: 00/00 Ord: 00 Row: 00 "
	dta $44

; top border

line_0b dta $44,$43,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
	dta $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$41,$44

; middle playback progress line

line_0c	dta $44,$44
	dta d"  StartPtr: $0000   EndPtr: $0000   "
	dta $44,$44

; bottom border

line_0d dta $44,$42,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
	dta $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$40,$44

; subtunes display 

line_0e	dta $44
	dta d" Tune: "
subtpos	dta d"01"
	dta d"/"
subtall	dta d"01   "

; control buttons 
	
line_0e1	
	dta $7B,$00 			; STOP button, will be overwritten 
	dta d"STOP   "			; STOP text, will be overwritten 

; buttons for music player display

b_handler				; index for the buttons handler
b_seekr	dta $58,$00			; 0, Seek Reverse
b_fastr	dta $7F,$00 			; 1, Fast Reverse
b_play	dta $7C,$00 			; 2, PLAY or PAUSE, it will be overwritten when needed! 
b_fastf	dta $7E,$00 			; 3, Fast Forward
b_seekf	dta $57,$00 			; 4, Seek Forward
b_stop	dta $7B,$00 			; 5, Stop
b_eject	dta $56,$00 			; 6, Eject, will act as a fancy "Exit" button for now... 
	dta $44

; bottomest border

line_0f dta $42,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
	dta $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$40

; currently below the volume bars, mode 2, 5 lines, where 1 of them is swapped using the SHIFT key

line_1	dta d"Line 1                                  "
line_2	dta d"Line 2                                  "
line_3	dta d"Line 3                                  "
line_4	dta d"Line 4 (hold SHIFT to toggle)           "
line_5	dta d"Line 5 (SHIFT is being held right now)  "

; version and credit

line_6	dta d"VUPlayer + LZSS by VinsCool         "
	dta d"v0.3"* 
	
; Display list

dlist       
	:6 dta $70		; 6 empty lines
	dta $42,a(line_0)	; ANTIC mode 2, for the first line of infos drawn on the screen 
	dta $70			; 1 empty line
	dta $46			; ANTIC mode 6, 4 lines, for the volume bars, or 4 lines of POKEY registers display
mode6_toggle 
	dta a(mode_6) 
	:3 dta $06
	dta $42,a(mode_2d)	; back to mode 2 with the main player display under the VU meter/POKEY registers
	:6 dta $02
	dta $70			; 1 empty line
	:3 dta $02		; 3 lines of user input text from RMT
	dta $42			
txt_toggle
	dta a(line_4)		; memory address set to line_4 by default, or line_5 when SHIFT is held
	:3 dta $70		; 3 empty lines
	dta $42,a(line_6)	; 1 final line of mode 2, must have its own addressing or else the SHIFT toggle affects it 
	dta $41,a(dlist)	; Jump and wait for vblank, return to dlist

;-----------------

;* Text strings, each line holds 40 characters, running in mode 2, line 5 is toggled with the SHIFT key
;* Volume bars and POKEY registers are 20 characters per line, running in mode 6, either is toggled with the 'R' key
;* TODO: add a help/about pageflip for more details and credits 

;-----------------

;* Topmost line, mode 2 displays region and speed 

line_0	dta d"                                        "

;* Currently below the volume bars, mode 2, 5 lines, where 1 of them is swapped using the SHIFT key

line_1	dta d"Line 1                                  "
line_2	dta d"Line 2                                  "
line_3	dta d"Line 3                                  "
line_4	dta d"Line 4 (hold SHIFT to toggle)           "
line_5	dta d"Line 5 (SHIFT is being held right now)  "

;* Version and credit

line_6
	dta d"VUPlayer-LZSS by VinsCool           "
	dta d"v2.0"* 

;-----------------

;* Volume bars, mode 2, 4 lines, this is also the default screen used when the program is loaded, which will be overwritten

mode_6	dta d"                                        "
mode_6a	dta d"        Welcome to VUPlayer 2.0!        "
mode_6b	dta d"       Playback will begin soon...      "
mode_6c	dta d"                                        "

;* POKEY registers, mode 2, 4 lines

POKE1	dta d"      LEFT POKEY      - RIGHT POKEY     "
POKE2	dta d" AUDF $00 $00 $00 $00 - $00 $00 $00 $00 "
POKE3	dta d" AUDC $00 $00 $00 $00 - $00 $00 $00 $00 "
POKE4	dta d" AUDCTL&SKCTL $00 $00 -         $00 $00 "

;-----------------

;* Topmost border, under the volume bars, back to mode 2

mode_2d dta $43,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
	dta $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$41 

;* Timer, order, row, etc display

line_0a	dta $44 
	;dta d" Time: 00:00 S: 00/00 Ord: 00 Row: 00 "
	;dta d" Time: 00:00                          "
	dta d" Time: 00:00  Start: $0000 End: $0000 "
	dta $44

;* Top border

line_0b ;dta $44,$43,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
	;dta $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$41,$44
	dta $44
	dta d"                                      "
	dta $44

;* Middle playback progress line

line_0c	;dta $44,$44
	;dta d"  StartPtr: $0000   EndPtr: $0000   "
	;dta $44,$44
	dta $44
	dta d"  [                                ]  "
	dta $44

;* Bottom border

line_0d ;dta $44,$42,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
	;dta $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$40,$44
	dta $44
	dta d"                                      "
	dta $44

;* Subtunes display 

line_0e	dta $44
	dta d" Tune: "
subtpos	dta d"00"
	dta d"/"
subtall	dta d"00   "

;* Control buttons 
	
line_0e1	
	dta $7B,$00 			; STOP button, will be overwritten 
	dta d"STOP   "			; STOP text, will be overwritten 

;* Buttons for music player display

b_handler				; index for the buttons handler
b_seekr	dta $5F,$00			; 0, Seek Reverse
b_fastr	dta $7F,$00 			; 1, Fast Reverse
b_play	dta $7C,$00 			; 2, PLAY or PAUSE, it will be overwritten when needed! 
b_fastf	dta $7E,$00 			; 3, Fast Forward
b_seekf	dta $5E,$00 			; 4, Seek Forward
b_stop	dta $7B,$00 			; 5, Stop
b_eject	dta $5D,$00 			; 6, Eject, will act as a fancy "Exit" button for now... 
	dta $44

;* Bottomest border, this is the last line of the player interface displayer, anything else is optional

line_0f dta $42,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45
	dta $45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$45,$40

;-----------------
	
; Display list

dlist       
	:6 dta $70		; start with 6 empty lines
	dta $C2
	dta a(line_0)		 
	dta $70	
	dta $42	
mode6_toggle 
	dta a(mode_6)
	:3 dta $02
	dta $42			; ANTIC mode 2, 7 + 5 lines, the main player display, under the VU Meter/POKEY registers
	dta a(mode_2d)		; top of the player interface, must have its own addressing since the lines below can change	
mode2_0	dta $42			; ANTIC mode 2, 5 lines, which can be switched on the fly
mode2_toggle
	dta a(line_0a)		; this part will also be used to display the help screen with the 'H' key
mode2_1	:4 dta $02		; the next 4 lines are all used for the main player interface, or help screen
	dta $42			; ANTIC mode 2, 1 line
	dta a(line_0f)		; bottom of the player interface, must have its own addressing since the lines above can change
	dta $70			; finish this part with 1 empty line
	dta $42			; ANTIC mode 2, 3+2 lines, user input text overwritten using RMT's export feature
	dta a(line_1)
	:2 dta $02		; the next 2 lines are directly underneath
	dta $42			; ANTIC mode 2, 1+1 line, which can be switched on the fly 
txt_toggle
	dta a(line_4)		; the memory address is set to line_4 by default, or line_5 when SHIFT is held
	:3 dta $70		; finish with 3 empty lines
	dta $42			; ANTIC mode 2, 1 line, for the VUPlayer version
	dta a(line_6)		; 1 final line of mode 2, must have its own addressing or else the SHIFT toggle affects it!
	dta $41,a(dlist)	; Jump and wait for vblank, return to dlist

;-----------------


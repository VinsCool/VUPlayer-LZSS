;************************************************;
;* VUPlayer, Version v0.3 WIP                   *;
;* by VinsCool, 2022                            *;
;* This project branched from Simple RMT Player *;
;* And has then become its own thing...         *;
;************************************************;

DISPLAY 	equ $FE		; Display List indirect memory address

;---------------------------------------------------------------------------------------------------------------------------------------------;

;* start of VUPlayer definitions...

; song speed xVBI

SongSpeed	equ 1		; 1 => 50/60hz, 2 => 100/120hz, etc

; playback speed will be adjusted accordingly in the other region

REGIONPLAYBACK	equ 1		; 0 => PAL, 1 => NTSC

; currently, Stereo is not supported with the LZSS driver...

;	STEREO	equ 0		; 0 => MONO, 1 => STEREO, 2 => DUAL MONO

; screen line for synchronization, important to set with a good value to get smooth execution

VLINE		equ 16		; nice round numbers fit well with multiples of 8 for every xVBI...
		ERT VLINE>155	; VLINE cannot be higher than 155!

; rasterbar colour

RASTERBAR	equ $69		; $69 is a nice purpleish hue

; VU Meter decay rate and speed

RATE		equ 1		; set the amount of volume decay is done, 0 is no decay, 15 is instant
SPEED		equ 1		; set the speed of decay rate, 0 is no decay, 255 is the highest amount of delay (in frames) 

;* end of dasmplayer definitions...

;---------------------------------------------------------------------------------------------------------------------------------------------;
	
; now assemble VUPlayer here... 
;* TODO: fix a lot of this shit

start       
	ldx #0			; disable playfield and the black colour value
	stx SDMCTL		; write to Shadow Direct Memory Access Control address
	jsr wait_vblank		; wait for vblank before continuing
	stx COLOR4		; Shadow COLBK (background colour), black
	stx COLOR2		; Shadow COLPF2 (playfield colour 2), black
	mwa #dlist SDLSTL	; Start Address of the Display List
	mva #>FONT CHBASE     	; load the font address into the character register, I'm not sure why at the moment but it seems like I must reload it every frame during the initialisation...

;-----------------

;* TODO: fix this shit
;* TODO: optimise timing space so NTSC time actually "divides" evenly... it's trying to fit calculations for 312 lines!
;* that means multispeed songs are not quite "right" in NTSC, because the interval is not actually constant between plays!

region_loop	
	lda VCOUNT
	beq check_region	; vcount = 0, go to check_region and compare values
	tax			; backup the value in index y
	bne region_loop 	; repeat
check_region
	stx region_byte		; will define the region text to print later
	ldy #SongSpeed		; defined speed value, which may be overwritten by RMT as well
	sty instrspeed		; will be re-used later as well for the xVBI speed value printed
	IFT REGIONPLAYBACK==0	; if the player region defined for PAL...
	lda tabppPAL-1,y
	sta acpapx2		; lines between each play
	cpx #$9B		; compare X to 155
	bmi set_ntsc		; negative result means the machine runs at 60hz		
	lda tabppPALfix-1,y
	bne region_done 
set_ntsc
	lda tabppNTSCfix-1,y	; if NTSC is detected, adjust the speed from PAL to NTSC
	ELI REGIONPLAYBACK==1	; else, if the player region defined for NTSC...
	lda tabppNTSC-1,y
	sta acpapx2		; lines between each play
	cpx #$9B		; compare X to 155	
	bpl set_pal		; positive result means the machine runs at 50hz 
	lda tabppNTSCfix-1,y
	bne region_done 
set_pal
	lda tabppPALfix-1,y	; if PAL is detected, adjust the speed from NTSC to PAL
	EIF			; endif 
region_done
	sta ppap		; stability fix for screen synchronisation		

;----------------- 

; print instrument speed and region, and set colours, done once per initialisation

	mwa #line_0 DISPLAY	; initialise the Display List indirect memory address for later
	ldy #4			; 4 characters buffer 
	lda #0
	instrspeed equ *-1
	jsr printhex_direct
	lda #0
	dey			; Y = 4 here, no need to reload it
	sta (DISPLAY),y 
	mva:rne txt_VBI-1,y line_0+5,y- 
	ldy #4			; 4 characters buffer 
	lda #0
	region_byte equ *-1
	cmp #$9B
	bmi is_NTSC
is_PAL				; VUMeter colours, adjusted for PAL 
	lda #$2A
	sta COLOR3
	sta col3bak
	lda #$BF
	sta COLOR1
	sta col1bak
	lda #$DE
	sta COLOR0
	sta col0bak
	ldx #50
	mva:rne txt_PAL-1,y line_0-1,y-
	beq is_DONE
is_NTSC				; VUMeter colours, NTSC colours were originally used
	lda #$4A
	sta COLOR3
	sta col3bak
	lda #$DF
	sta COLOR1
	sta col1bak
	lda #$1E
	sta COLOR0
	sta col0bak
	ldx #60
	mva:rne txt_NTSC-1,y line_0-1,y-
is_DONE				
	sty v_second		; Y is 0, reset the timer with it
	sty v_minute	
	stx framecount		; X is either 50 or 60, defined by the region initialisation
	stx v_frame		; also initialise the actual frame counter with this value
	ldy #6			
	sty VSCROL		; this will set the initial vertical position for the VU Meter/POKEY registers toggle scroll
	jsr stop_pause_reset	; clear the POKEY registers first
	jsr SetNewSongPtrsFull	; initialise the LZSS driver with the song pointer using default values always 
	jsr set_subtune_count	; update the subtunes position and total values
	jsr set_highlight	; set the first highlighted button selection, PLAY by default 

;------------------

;* TODO: fix this shit too

	lda SKSTAT		; Serial Port Status
	and #$08		; SHIFT key being held?
	beq no_dma		; yes, skip the next 2 instructions
	ldx #$22		; DMA enable, normal playfield
	stx SDMCTL		; write to Shadow Direct Memory Access Control address
no_dma
	sta dma_flag		; will allow skipping drawing the screen if it was not enabled!
	ldx #120		; load into index x a 120 frames buffer
wait_init   
	jsr wait_vblank		; wait for vblank => 1 frame
	mva #>FONT CHBASE	
	dex			; decrement index x
	bne wait_init		; repeat until x = 0, total wait time is ~2 seconds
init_done
	sei			; Set Interrupt Disable Status
	mwa VVBLKI oldvbi       ; vbi address backup
	mwa #vbi VVBLKI		; write our own vbi address to it 
	
	mwa #deli VDSLST
	
;	mva #$40 NMIEN		; enable vbi interrupts
	mva #$C0 NMIEN
	mva #>FONT CHBASE
	
ready_to_play 
	ldy #7			; long enough characters buffer, used to set the PLAY status display 
	mva:rne txt_PLAY-1,y line_0e1-1,y- 
	
;-----------------
	
wait_sync
	lda VCOUNT		; current scanline 
	cmp #VLINE		; will stabilise the timing if equal
	bcc wait_sync		; nope, repeat

;-----------------

;---------------------------------------------------------------------------------------------------------------------------------------------;

;* main loop, code runs from here ad infinitum after initialisation

loop
	ldy #RASTERBAR			; custom rasterbar colour
rasterbar_colour equ *-1
acpapx1
	lda spap
	ldx #0
cku	equ *-1
	bne keepup
	lda VCOUNT			; vertical line counter synchro
	tax
	sub #VLINE
lastpap	equ *-1
	scs:adc #$ff
ppap	equ *-1
	sta dpap
	stx lastpap
	lda #0
spap	equ *-1
	sub #0
dpap	equ *-1
	sta spap
	bcs acpapx1
keepup
	adc #$ff
acpapx2	equ *-1
	sta spap
	ldx #0
	scs:inx
	stx cku
	sty WSYNC			; horizontal sync for timing purpose

;* debug code

;	lda VCOUNT 
;	sta VCOUNTER 
	
check_play_flag	
	lda is_playing_flag 		; 0 -> is playing, else it is either stopped or paused, and must not run into rmtplay again 
	bne loop			; otherwise, the player is either paused or stopped, in this case, nothing will happen until it is changed back to 0

	lda #0				; lda #$80 to display the rasterbar by default, 0 sets it hidden otherwise 
	rasterbar_toggler equ *-1
	bpl do_play			; a positive value means the rasterbar is not displayed 
	sty COLBK			; background colour
	sty COLPF2			; playfield colour 2
	
do_play 
	jsr setpokeyfast		; VUPlayer's variant of the subroutine
	jsr LZSSPlayFrame		; Play 1 LZSS frame
	jsr LZSSUpdatePokeyRegisters	; double buffer to let setpokeyfast match the RMT timing

finish_loop_code
	jsr fade_volume_loop		; run the fadeing out code from here until it's finished
	lda is_playing_flag		; was the player paused/stopped after fadeing out?
	bne finish_loop_code_a		; if not equal, it was most likely stopped, and so there is nothing else to do here
	jsr LZSSCheckEndOfSong		; is the current LZSS index done playing?
	bne finish_loop_code_a		; if not, go back to the loop and wait until the next call
	jsr SetNewSongPtrs		; update the subtune index for the next one in adjacent memory 
	lda #0
	sta LZS.Initialized		; reset the state of the LZSS driver to not initialised so it can play the next tune or loop	
	
finish_loop_code_a	
	sta WSYNC			; horizontal sync

;* debug code

;	lda VCOUNT
;	sec
;	sbc VCOUNTER
;	asl @
;	sta VSCANLINES
	
	ldy #0				; black colour value
	sty COLBK			; background colour
	sty COLPF2			; playfield colour 2 
	jmp loop			; infinitely

;-----------------

;---------------------------------------------------------------------------------------------------------------------------------------------;

;* VBI loop, run through all the code that is needed, then return with a RTI 

vbi
	sta WSYNC		; horizontal sync, so we're always on the exact same spot, seems to help with timing stability 
	ldy #56			; debug colour 
	sty COLBK		; background colour
	sty COLPF2		; playfield colour 2
	lda #$FF		; DMA flag, set to allow skipping drawing the screen if it was not enabled
	dma_flag equ *-1
	beq continue_c		; if the value is 0, nothing will be drawn, else, continue with everything below
	ldy KBCODE		; Keyboard Code  
	ldx <line_4		; line 4 of text
	lda SKSTAT		; Serial Port Status
	and #$08		; SHIFT key being held?
	bne set_line_4		; nope, skip the next ldx
	ldx <line_5		; line 5 of text (toggled by SHIFT) 
	tya
	eor #$40		; invert the SHIFT key flag so it will be ignored later-- is this actually necessary? I forgor
	tay
set_line_4  
	stx txt_toggle		; write to change the text on line 4 
	
check_key_pressed 	
	lda SKSTAT		; Serial Port Status
	and #$04		; last key still pressed?
	bne continue		; if not, skip ahead, no input to check
	lda #0 			; was the last key pressed also held for at least 1 frame? This is a measure added to prevent accidental input spamming
	held_key_flag equ *-1
	bmi continue_b		; the held key flag was set if the value is negative! skip ahead immediately in this case 
	jsr check_keys		; each 'menu' entry will process its action, and return with RTS, the 'held key flag' must then be set!
	ldx #$FF
	bmi continue_a		; skip ahead and set the held key flag! 
continue			; do everything else during VBI after the keyboard checks 
	ldx #0			; reset the held key flag! 
continue_a 			; a new held key flag is set when jumped directly here
	stx held_key_flag 
continue_b 			; a key was detected as held when jumped directly here
	;jsr draw_scanlines	; debug code, could be commented out 
	jsr test_vumeter_toggle	; process the VU Meter and POKEY registers display routines there	
	jsr set_subtune_count	; update the subtune count on screen	
	
	lda help_toggler
	bmi continue_c
	
	jsr print_player_infos	; print most of the stuff on screen using printhex or printinfo in bulk (TODO: fix this shit) 
continue_c	
	jsr calculate_time 	; update the timer, this one is actually necessary, so even with DMA off, it will be executed 
return_from_vbi			
	sta WSYNC		; horizontal sync, this seems to make the timing more stable
	ldy #0			; clear debug colour 
	sty COLBK		; background colour
	sty COLPF2		; playfield colour 2
	pla			;* since we're in our own vbi routine, pulling all values manually is required! 
	tay
	pla
	tax
	pla
	rti			; return from interrupt, this ends the VBI time, whenever it actually is "finished" 

;-----------------

;* DLI loop, run through all the code that is needed, then return with a RTI 

deli
	pha
	mwa #deli2 VDSLST	; set the next DLI
	lda #2
	sta delicounter
	sta WSYNC

deliloop 
	sta WSYNC
	lda col3bak		; Red
	and #$F0
	clc
	adc delicounter
	sta COLPF3
	lda col0bak		; Yellow
	and #$F0
	clc
	adc delicounter
	sta COLPF0
	lda col1bak		; Green
	and #$F0
	clc
	adc delicounter
	sta COLPF1
	inc delicounter
	lda #0
	delicounter equ *-1
	sta WSYNC
	cmp #15
	bne deliloop
deliloop2
	sta WSYNC
	lda col3bak		; Red
	and #$F0
	clc
	adc delicounter
	sta COLPF3
	lda col0bak		; Yellow
	and #$F0
	clc
	adc delicounter
	sta COLPF0
	lda col1bak		; Green
	and #$F0
	clc
	adc delicounter
	sta COLPF1
	dec delicounter
	sta WSYNC
	lda delicounter
	bne deliloop2
	sta delicounter
	sta WSYNC
delivered 	
	lda #0
	col0bak equ *-1
	sta COLPF0
	lda #0
	col1bak equ *-1
	sta COLPF1
	lda #0
	col3bak equ *-1
	sta COLPF3
	pla
	rti
//
deli2
	pha
	mwa #deli VDSLST	; now the adress is reset to the first DLI
	lda delicounter
	beq delivered		; most likely finished, so do not overwrite the stack pointer addresses!
	pla
	sta delibackup
	stx delibackup2	
	pla
	tax
	pla
	pla
	lda >delivered
	pha
	lda <delivered
	pha
	txa
	pha
	lda #0
	delibackup equ *-1
	ldx #0
	delibackup2 equ *-1
	rti
//

;---------------------------------------------------------------------------------------------------------------------------------------------;

;* everything below this point is either stand alone subroutines that can be called at any time, or some misc data such as display list 

; wait for vblank subroutine

wait_vblank 
	lda RTCLOK+2		; load the real time frame counter to accumulator
wait        
	cmp RTCLOK+2		; compare to itself
	beq wait		; equal means it vblank hasn't began
	rts

;-----------------

; print text from data tables, useful for many things 

printinfo 
	sty charbuffer
	ldy #0
do_printinfo
        lda $ffff,x
infosrc equ *-2
	sta (DISPLAY),y
	inx
	iny 
	cpy #0
charbuffer equ *-1
	bne do_printinfo 
	rts

;-----------------

; print hex characters for several things, useful for displaying all sort of debugging infos
	
printhex
	ldy #0
printhex_direct     ; workaround to allow being addressed with y in different subroutines
	pha
	:4 lsr @
	;beq ph1    ; comment out if you want to hide the leftmost zeroes
	tax
	lda hexchars,x
ph1	
        sta (DISPLAY),y+
	pla
	and #$f
	tax
	mva hexchars,x (DISPLAY),y
	rts
hexchars 
        dta d"0123456789ABCDEF"

;-----------------

; quick and dirty way to convert a hex value to decimal for display purposes
; note that the higher the number to convert, the slower this process becomes!
;* OPTIMISATION: count from 10 instead of 0, which would be a lot faster since 0 to 9 don't need conversion

hex2dec_convert
	cmp #10			; below 10 -> 0 to 9 inclusive will display like expected, skip the conversion
	bcc hex2dec_convert_b
	sec
	sbc #10			; subtract 10 first, this will save 10 loops of this code!
	tay
	lda #$10		; add from 10 (hex) 
	dey 
	bmi hex2dec_convert_b	; overflow! set the value directly
	clc
	sed
hex2dec_convert_a
	adc #1 
	dey
	bpl hex2dec_convert_a
	cld
hex2dec_convert_b
	rts
	
;-----------------
	
;* VUPlayer specific code, for displaying the current player state

do_stop_toggle
	jsr stop_toggle
	ldx #16				; offset by 16 for STOP characters
	bne play_pause_button_toggle_a	; finish in the play_pause code from here, unconditional 

;-----------------

;* VUPlayer specific code, for displaying the current player state

do_play_pause_toggle
	jsr play_pause_toggle
	lda is_playing_flag
	beq play_pause_button_toggle_a
play_pause_button_toggle 
	ldx #8				; offset by 8 for PAUSE characters	
play_pause_button_toggle_a 
	ldy #7				; 7 character buffer is enough 
	mwa #line_0e1 DISPLAY		; move the position to the correct line
	mwa #txt_PLAY infosrc		; set the pointer for the text data to this location
	jsr printinfo 			; write the new text in this location 
	ldx line_0e1			; the play/pause/stop character
	cpx #$7B			; is it the STOP character?
	bne play_pause_button_toggle_b	; if not, overwrite the character in the buttons display with either PLAY or PAUSE
	inx				; else, make sure PLAY is loaded, then write it in memory 
play_pause_button_toggle_b	
	stx b_play 			; overwrite the Play/Pause character
	jsr set_highlight		; refresh the display for the updated graphics, and also to display which player button is highlighted
	rts 

;-----------------

set_subtune_count
	lda #0
SongIdx	equ *-1
	cmp #$FF
current_subtune equ *-1
	beq set_subtune_count_d	; still playing the same subtune, skip this subroutine
	sta current_subtune	; set the new value in memory	
set_subtune_count_a
	jsr reset_timer 	; also reset the timer so new tunes always play from 0:00
set_subtune_count_b
	mwa #subtpos DISPLAY	; get the right screen position first
	lda SongIdx		; index position from LZSSP
	jsr hex2dec_convert	; convert it to decimal 
	jsr printhex		; Y may not be 0 after the decimal conversion, do not risk it
	lda rasterbar_colour
	clc
	adc #16
	sta rasterbar_colour
set_subtune_count_c
	lda SongTotal		; index total from LZSSP, this won't change once it was set, except during the initialisation
	cmp #0
total_subtune equ *-1
	beq set_subtune_count_d	; still the same total, nothing else to do here
	sta total_subtune	; set the new value in memory	
	jsr hex2dec_convert	; convert it to decimal 
	ldy #3			; offset to update the other number
	jsr printhex_direct	; this time Y will position where the character is written
set_subtune_count_d
	rts
	
;-----------------

; stop and quit

stopmusic 
	jsr stop_pause_reset 
	mwa oldvbi VVBLKI	; restore the old vbi address
	ldx #$00		; disable playfield 
	stx SDMCTL		; write to Direct Memory Access (DMA) Control register
	dex			; underflow to #$FF
	stx CH			; write to the CH register, #$FF means no key pressed
	cli			; this may be why it seems to crash on hardware... I forgot to clear the interrupt bit!
	jsr wait_vblank		; wait for vblank before continuing
	jmp (DOSVEC)		; return to DOS, or Self Test by default

;----------------- 

;* menu input handler subroutine, all jumps will end on a RTS, and return to the 'set held key flag' execution 

do_button_selection   
	lda #2			; by default, the PLAY/PAUSE button 
button_selection_flag equ *-1
	asl @
	asl @ 
	sta b_index+1
b_index	bcc *
b_0	jmp seek_reverse 	; #0 => seek reverse 
	nop
b_1	jmp fast_reverse	; #1 => fast reverse (decrement speed) 
	nop
b_2	jmp do_play_pause_toggle	; #2 => play/pause 
	nop
b_3	jmp fast_forward 	; #3 => fast forward (increment speed) 
	nop
b_4	jmp seek_forward 	; #4 => seek forward 
	nop
b_5	jmp do_stop_toggle 	; #5 => stop
	nop
b_6	jmp stopmusic 		; #6 => eject 
	
;-----------------

;* check all keys that have a purpose here... 
;* this is the world's most cursed jumptable ever created!
;* regardless, this finally gets rid of all the spaghetti code I made previously!

check_keys
	cpy #64				; within the valid range of key input?
	bcc do_check_keys		; below 64, it's good to go!
	rts				; else, return immediately from the subroutine
do_check_keys
	ldx button_selection_flag	; this will be used for the menu selection below, if the key is matching the input... could be better
	tya				; transfer to the accumulator to make a quick and dirty jump table
	asl @				; ASL only once, allowing a 2 bytes index, good enough for branching again immediately and unconditionally, 128 bytes needed sadly...
	sta k_index+1			; branch will now match the value of Y
k_index	bne * 
	bcc do_toggle_loop		; Y = 0 -> L key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	bcc do_key_left			; Y = 6 -> Atari 'Left' / '+' key
	bcc do_key_right		; Y = 7 -> Atari 'Right' / '*' key 
	bcc b_5				; Y = 8 -> 'O' key (not zero!!) 
	rts:nop
	bcc b_2				; Y = 10 -> 'P' key
	rts:nop
	bcc do_button_selection		; Y = 12 -> 'Enter' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	bcc b_3				; Y = 24 -> '4' key
	rts:nop
	bcc b_1				; Y = 26 -> '3' key
	bcc do_ppap_forward		; Y = 27 -> '6' key
	bcc b_6				; Y = 28 -> 'Escape' key
	bcc do_ppap_reverse		; Y = 29 -> '5' key
	bcc b_4				; Y = 30 -> '2' key
	bcc b_0				; Y = 31 -> '1' key
	rts:nop
	bcc do_toggle_rasterbar 	; Y = 33 -> 'Spacebar' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	bcc do_toggle_vumeter		; Y = 40 -> 'R' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	bcc do_scroll_up		; Y = 46 -> 'W' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
	bcc do_lastpap_reverse		; Y = 51 -> '7' key
	rts:nop
	bcc do_lastpap_forward		; Y = 53 -> '8' key
	rts:nop
	rts:nop
	bcc do_trigger_fade_immediate	; Y = 56 -> 'F' key
	bcc do_toggle_help		; Y = 57 -> 'H' key
	bcc do_key_right		; Y = 58 -> 'D' key
	rts:nop
	rts:nop
	rts:nop
	bcc do_scroll_down		; Y = 62 -> 'S' key
	bcc do_key_left			; Y = 63 -> 'A' key
do_toggle_loop
	jmp toggle_loop			; toggle the player 'loop' flag on/off
do_toggle_rasterbar
	jmp toggle_rasterbar		; toggle the rasterbar display on/off
do_toggle_vumeter
	jmp toggle_vumeter		; toggle the VU Meter display with POKEY registers display
do_trigger_fade_immediate
	jmp trigger_fade_immediate	; immediately set the 'fadeout' flag then stop the player once finished
do_key_left
	jmp dec_index_selection 	; decrement the index by 1	
do_key_right
	jmp inc_index_selection 	; increment the index by 1 
do_ppap_reverse	
	jmp fast_reverse2 		; decrement speed value 2 (ppap) 
do_ppap_forward
	jmp fast_forward2		; increment speed value 2 (ppap) 
do_lastpap_reverse
	jmp fast_reverse3		; decrement speed value 3 (lastpap) 
do_lastpap_forward
	jmp fast_forward3		; increment speed value 3 (lastpap) 
do_scroll_up
	jmp scroll_up			; manually input VSCROL up for the VU Meter toggle, debug code
do_scroll_down
	jmp scroll_down			; manually input VSCROL down for the VU Meter toggle, debug code
do_toggle_help
	jmp toggle_help			; toggle the main player interface/help screen 
	
;----------------- 

; index_selection 

dec_index_selection
	dex 				; decrement the index
	bpl done_index_selection	; if the value did not underflow, done 
	ldx #6				; if it went past the boundaries, load the last valid index to wrap around
	bpl done_index_selection	; unconditional
inc_index_selection
	inx				; increment the index
	cpx #7				; compare to the maximum of 7 button indexes
	bcc done_index_selection	; if below 7, everything is good
	ldx #0				; else, load 0 to wrap around
done_index_selection
	stx button_selection_flag 	; overwrite the index value
	jsr set_highlight		; refresh the display for the chosen player button
	rts				; done
	
;-----------------

; timing modifyer inputs, only useful for debugging 

fast_reverse
	inc acpapx2
	rts
fast_forward
	dec acpapx2
	rts 
fast_reverse2
	inc ppap
	rts
fast_forward2
	dec ppap
	rts 
fast_reverse3
	inc lastpap
	rts
fast_forward3	
	dec lastpap
	rts
	
;-----------------

toggle_vumeter
	lda scroll_buffer
	bne no_toggle_interrupt
	lda #0			; vumeter flag, 0 is vumeter, else FF displays the POKEY registers
	vumeter_toggle equ *-1
	eor #$FF		; invert bits 
	sta vumeter_toggle	; overwrite the flag with the new value
	lda #33
	sta scroll_buffer
no_toggle_interrupt
	rts 

;-----------------
	
toggle_rasterbar 
	lda rasterbar_toggler	; rasterbar flag, a negative value means the rasterbar display is active 
	eor #$FF		; invert bits 
	sta rasterbar_toggler	; overwrite the rasterbar flag, execution continues like normal from here 
	rts 
	
;-----------------

toggle_loop
	lda loop_toggle		; loop flag, 0 is unset, else it is set with FF
	eor #$FF		; invert bits 
	sta loop_toggle		; overwrite the flag with the new value
	rts 
	
;-----------------

toggle_help
	lda #0
	help_toggler equ *-1
	eor #$FF
	sta help_toggler
	bmi display_help
display_player
	lda <line_0a
	sta mode2_toggle
	lda >line_0a
	sta mode2_toggle+1
	rts
display_help	
	lda <help_0
	sta mode2_toggle
	lda >help_0
	sta mode2_toggle+1
	rts

;-----------------

;* menu buttons highlight subroutine

set_highlight 
	ldx #6				; 7 buttons to index
set_highlight_a
	txa 				; transfer to accumulator
	asl @				; multiply by 2
	tay 				; transfer to Y, use to index the values directly
	lda b_handler,y			; load the character from this location
	bpl set_highlight_b		; positive -> no highlight, skip overwriting it
	eor #$80 			; invert the character
	sta b_handler,y			; overwrite, no highlight to see again 
set_highlight_b
	dex 				; decrease the index and load the next character using it
	bpl set_highlight_a		; as long as X is positive, do this again until all characters were reset 
set_highlight_c 
	lda button_selection_flag	; load the button flag value previously set in memory
	asl @				; multiply it by 2 for the index 
	tay				; transfer to Y, use it to index the character directly
	lda b_handler,y 		; load the character in memory 
	eor #$80 			; invert the character, this will now define it as "highlighted"
	sta b_handler,y 		; write the character in memory, it is now selected, and will be processed again later 
	rts

;-----------------

;* debug code, for displaying the VCOUNT and number of scanlines used during the LZSS driver play

/*
draw_scanlines
	mwa #line_0 DISPLAY	; move the display pointer to the correct position first
	lda #0
	VCOUNTER equ *-1
	jsr hex2dec_convert	; convert it to decimal 
	ldy #21
	jsr printhex_direct 
	lda #0
	VSCANLINES equ *-1
	jsr hex2dec_convert	; convert it to decimal 
	ldy #35
	jsr printhex_direct
*/
	
;-----------------

;* print most infos on screen
;* TODO: optimise the code running here so it won't hog all the VBI time
	
print_player_infos
	mwa #line_0a DISPLAY 	; get the right screen position

print_minutes
	lda v_minute
	cmp #0
	old_minute 	equ *-1
	beq print_seconds
	sta old_minute
	ldy #8
	jsr printhex_direct
	
print_seconds
	ldx v_second
	cpx #0
	old_second	equ *-1
	beq print_speed
	stx old_second
	txa
	ldy #10
	and #1
	beq no_blink 
	lda #0
	beq blink
no_blink 
	lda #":" 
blink
	sta (DISPLAY),y 
	iny 
done_blink
	txa
	jsr printhex_direct

print_speed
	lda acpapx2
	cmp #0
	old_speed 	equ *-1
	beq print_speed2
	sta old_speed
	ldy #17
;	eor #$FF			; invert the value so it looks like faster == higher value
	jsr printhex_direct 
	

print_speed2
	lda ppap
	cmp #0
	old_speed2 	equ *-1
	beq print_order
	sta old_speed2
	ldy #20
;	eor #$FF			; invert the value so it looks like faster == higher value
	jsr printhex_direct


print_order	
	lda ZPLZS.SongPtr+1
	cmp #0
	old_order	equ *-1
	beq print_row
	sta old_order
	ldy #28
	jsr printhex_direct
	
print_row
	lda ZPLZS.SongPtr 
	cmp #0
	old_row		equ *-1
	beq print_loop
	sta old_row 
	ldy #36
	jsr printhex_direct	
	
; verify if the loop flag is set to update the graphics accordingly

print_loop
	ldy #174
	lda loop_toggle
	bmi yes_loop			; it *should* be 0 if not looping, it will be overwritten anyway
	lda #0
	beq no_loop
yes_loop
	lda #"*" 
no_loop
	sta (DISPLAY),y 

;* print current subtune pointers addresses, the code could be a lot better than that...

Print_pointers
	mwa #line_0a DISPLAY		; get the right screen position first
	ldy #95
	lda LZS.SongStartPtr+1
	jsr printhex_direct
	iny
	lda LZS.SongStartPtr
	jsr printhex_direct	
	ldy #111
	lda LZS.SongEndPtr+1
	jsr printhex_direct
	iny
	lda LZS.SongEndPtr
	jsr printhex_direct
	rts
	
;-----------------

test_vumeter_toggle
	lda #0			; the scroll buffer value, if it has a value, it will be used for the amount to scroll
	scroll_buffer equ *-1
	beq no_vertical_scroll	; if the value is 0, skip this subroutine
	jmp do_vumeter_toggle	; else, draw BOTH for the duration of the transition! it will also end with a RTS there
no_vertical_scroll 
	lda vumeter_toggle	; the toggle flag will set which direction the scrolling goes
	bpl do_begindraw	; positive flag, VU Meter, else, POKEY registers, it will be one or the other
do_draw_registers
	jmp draw_registers	; end with a RTS
do_begindraw
	jmp begindraw		; end with a RTS
do_vumeter_toggle 
	lda vumeter_toggle	; the toggle flag will set which direction the scrolling goes
	bpl scroll_down		; positive flag, scroll down, else, scroll up 
scroll_up
	inc vertiscroll
	lda vertiscroll
	cmp #8
	bcc scroll_done
        clc
        lda mode6_toggle
        adc #20
        sta mode6_toggle
        lda mode6_toggle+1
        adc #0
        sta mode6_toggle+1
	lda #0
	sta vertiscroll
	beq scroll_done
scroll_down
	dec vertiscroll
	bpl scroll_done
        sec
        lda mode6_toggle
        sbc #20
        sta mode6_toggle
        lda mode6_toggle+1
        sbc #0
        sta mode6_toggle+1 
	lda #7
	sta vertiscroll
scroll_done
	lda #6
	vertiscroll equ *-1
	sta VSCROL 
	dec scroll_buffer
	bpl scroll_done_a
	lda #0			; once it finished scrolling, the buffer is reset to 0
	sta scroll_buffer
scroll_done_a
	jsr draw_registers	; draw BOTH for the duration of the transition!
	jsr begindraw		; using JSR is easier since they go one after the other without any further work
	rts

;-----------------

;* draw POKEY registers
;* this is incredibly crappy code but it gets the job done...

draw_registers
	mwa #POKE1 DISPLAY	; set the position on screen
	ldy #26
	ldx #0
draw_registers_a
	stx countdown
	lda SDWPOK0,x
	jsr printhex_direct
	:3 iny
	ldx countdown
	:2 inx
	cpx #8
	bne draw_registers_a
	lda SDWPOK0,x
	ldy #68
	jsr printhex_direct	
	ldy #46
	ldx #1
draw_registers_b	
	stx countdown
	lda SDWPOK0,x
	jsr printhex_direct
	:3 iny
	ldx countdown
	:2 inx
	cpx #9
	bne draw_registers_b
	lda SDWPOK0,x
	ldy #78
	jsr printhex_direct
	rts
	nop
	countdown equ *-1

;-----------------

;* draw the volume blocks

;* TODO: move this code elsewhere, this hogs too much VBI time!
;* TODO2: this code could be MUCH better too...
	
; index ORA
; #$00 -> COLPF0
; #$40 -> COLPF1 (could be exploited since the font seems to only change brightness), use on numbers and green bars level
; #$80 -> COLPF2 cannot be used!! conflicts with rasterbar, unless I used a DLI
; #$C0 -> COLPF3
	
; current order: red, green (2x), yellow, and numbers in green again...
; line 1: pf3
; line 2-3: pf1, use also on numbers below line 5
; line 4: pf0 

; rambles...
; LSR @ 2x from the volume values lead to this observation:

; F to C => 3
; B to 8 => 2
; 7 to 4 => 1
; 3 to 0 => 0

; now... how could this actually helps me...?
; hmmm... 

; one way to imagine this is, using these values as JMPs, I would land on the first line that does have characters to draw
; but there I still cannot exactly know where I am really supposed to be, so that is still going to be a problem...

; another idea is to make a table of JMP/Branches, but then I get other problems... this is tricky.
; I could also go on a column by column basis, where X is the index for variables, and Y handles the screen index?
; but then again that still gets messy... argh.

; ok here's an idea:
; use AND operations as BIT, make jumps based on them, through the necessary LSR needed to get the values
; that will remove the necessity from using X for line index, and maybe save the CPU this time... I hope

; line 1 => AND with #$0C, BEQ draw blank tile, remaining values are LSR twice, then branched to the appropriate tile
; line 2 => AND with #$08, BEQ draw blank tile, remaining values are LSR once, then branched to the appropriate tile
; line 3 => AND with #$04, BEQ draw blank tile, remaining values are used directly to branch to the appropriate tile

; ...
; ... no that won't work, bleh.
; too tired for today.
; maybe I could do with subtractions?
; heh I need sleep

begindraw
	mwa #mode_6+2 DISPLAY	; set the position on screen, offset by 2 in order to be centered
	lda #$c0		; change the colour to red 
	sta colour_bar 
	ldx #7			; 4 AUDF + 4 AUDC
	
begindraw1
	lda SDWPOK0,x
	and #$0F
	beq reset_decay_a	; 0 = no volume to write into the buffer
	sta temp_volume		; self modifying code
	
begindraw2
	lda SDWPOK0-1,x
	eor #$FF		; invert the value, the pitch goes from lowest to highest from the left side
	:4 lsr @		; divide by 16
	tay			; transfer to Y
	
begindraw3 
	lda #0
temp_volume equ *-1		; to hopefully speed up the operations without clogging more bytes
	cmp decay_buffer,y	; what is the volume level in memory?
	bcc reset_decay_a	; below the value in memory will be ignored
reset_decay
	sta decay_buffer,y	; if above the buffer value, write the new value in memory, the decay is now reset for this column
reset_decay_a
	:2 dex			; due to the change in values position, indexing uses 8 iterations, for AUDC and AUDF
	bpl begindraw1		; repeat until all channels are done 
	
do_index_line	
	inx 			; line index = 0, for a total of 4 lines 
	ldy #15			; 16 columns, including 0 
	
do_index_line_a
	lda decay_buffer,y	; volume value in the corresponding column 
	beq draw_nothing	; a value of 0 is immediately drawing a blank tile on screen 
	
do_index_line_b
	cpx #1
	bcc vol_12_to_15	; X = 0
	beq vol_8_to_11		; X = 1
	cpx #2
	beq vol_4_to_7		; X = 2, else, the last line is processed by default 

vol_0_to_3
	cmp #4
	bcs draw_4_bar 
	cmp #1			; must be equal or above
	beq draw_1_bar		; 1
	cmp #2
	beq draw_2_bar		; 2
	bne draw_3_bar
	
vol_4_to_7
	cmp #8
	bcs draw_4_bar 	
	cmp #5			; must be equal or above
	bcc draw_0_bar		; overwrite with a blank tile, always
	beq draw_1_bar		; 5
	cmp #6
	beq draw_2_bar		; 6
	bne draw_3_bar
	
vol_8_to_11
	cmp #12
	bcs draw_4_bar
	cmp #9			; must be equal or above
	bcc draw_0_bar		; overwrite with a blank tile, always
	beq draw_1_bar		; 9
	cmp #10
	beq draw_2_bar		; 10
	bne draw_3_bar
	
vol_12_to_15 
	cmp #15
	beq draw_3_bar
	cmp #13			; must be equal or above
	bcc draw_0_bar		; overwrite with a blank tile, always 
	beq draw_1_bar		; 13 

draw_2_bar
	lda #60
	bne draw_line1
draw_3_bar
	lda #27
	bne draw_line1
draw_4_bar			
	lda #5
	bne draw_line1
draw_0_bar
	lda #0
	beq draw_nothing
draw_1_bar
	lda #63 

draw_line1
	ora #0
colour_bar equ *-1 

draw_nothing
	sta (DISPLAY),y 
	dey
	bpl do_index_line_a	; continue until all columns were read
	cpx #3
	beq finishedloop	; all channels were done if equal 
	
goloopagain
	lda DISPLAY		; current memory address used for the process
	add #20			; mode 6 uses 20 characters 
	sta DISPLAY		; adding 20 will move the pointer to the next line
	scc:inc DISPLAY+1	; in case the boundary is crossed, the pointer MSB will increment as well
	
verify_line
	cpx #1
	bcc change_line23	; below 1 
change_line4
	lda #$40		; change the colour to green 
	bne colour_changed 
change_line23 
	lda #$00 		; change the colour to yellow 
colour_changed
	sta colour_bar		; new colour is set for the next line 
	jmp do_index_line 	; repeat the process for the next line until all lines were drawn  

;-----------------

decay_buffer
	:16 dta $00 
decay_speed
	dta SPEED		; set the speed of decay rate, 0 is no decay, 255 is the highest amount of delay (in frames) 

finishedloop
	ldy #0 			; reset value if needed
	ldx #15			; 16 columns index, including 0 
	
do_decay
	dec decay_speed
	bpl decay_done		; if value is positive, it's over, wait for the next frame 
reset_decay_speed
	lda #SPEED
	sta decay_speed		; reset the value in memory, for the next cycle
decay_again 
	lda decay_buffer,x
	beq decay_next		; 0 equals no decay 
	sub #RATE 
	bpl decay_again_a	; if positive, write the value in memory 
	tya
decay_again_a
	sta decay_buffer,x	; else, write 0 to it
decay_next
	dex			; next column index
	bpl decay_again		; repeat until all columns were done 
decay_done
	rts
	
;-----------------

;---------------------------------------------------------------------------------------------------------------------------------------------;

;* line counter spacing table for instrument speed from 1 to 16

;-----------------

;* the idea here is to pick the best sweet spots each VBI multiples to form 1 "optimal" table, for each region
;* it seems like the number of lines for the 'fix' value MUST be higher than either 156 for better stability
;* else, it will 'roll' at random, which is not good! better sacrifice a few lines to keep it stable...
;* strangely enough, NTSC does NOT suffer from this weird rolling effect... So that one can use values above or below 131 fine

;	    x1  x2  x3  x4  x5  x6  x7  x8  x9  x10 x11 x12 x13 x14 x15 x16 

tabppPAL	; "optimal" PAL timing table
	dta $9C,$4E,$34,$27,$20,$1A,$17,$14,$12,$10,$0F,$0D,$0C,$0C,$0B,$0A
	
tabppPALfix	; interval offsets for timing stability 
	dta $9C,$9C,$9C,$9C,$A0,$9C,$A1,$A0,$A2,$A0,$A5,$9C,$9C,$A8,$A5,$A0
	
;-----------------
	
;* NTSC needs its own adjustment table too... And so will cross-region from both side... Yay numbers! 
;* adjustments between regions get a lot trickier however...
;* for example: 
;* 1xVBI NTSC to PAL, 130 on 156 does work for a stable rate, but it would get all over the place for another number 

;	    x1  x2  x3  x4  x5  x6  x7  x8  x9  x10 x11 x12 x13 x14 x15 x16 
	
tabppNTSC	; "optimal" NTSC timing table
	dta $82,$41,$2B,$20,$1A,$15,$12,$10,$0E,$0D,$0B,$0A,$0A,$09,$08,$08

tabppNTSCfix	; interval offsets for timing stability 
	dta $82,$82,$81,$80,$82,$7E,$7E,$80,$7E,$82,$79,$78,$82,$7E,$78,$80

;-----------------

;* TODO: add cross region tables fix, might be a pain in the ass, blegh...

;-----------------

oldvbi	
	dta a(0)		; vbi address backup
	
;-----------------

; some plaintext data used in few spots
        
txt_NTSC
        dta d"NTSC"*
txt_PAL
        dta d"PAL"*,d" "
txt_VBI
	dta d"xVBI (Stereo)"
	
txt_PLAY
	dta $7C,$00 		; PLAY button
	dta d"PLAY  "
txt_PAUSE
	dta $7D,$00 		; PAUSE button
	dta d"PAUSE "
txt_STOP
	dta $7B,$00 		; STOP button
	dta d"STOP  "

;---------------------------------------------------------------------------------------------------------------------------------------------;

; and that's all :D


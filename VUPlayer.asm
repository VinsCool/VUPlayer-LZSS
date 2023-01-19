;************************************************;
;* VUPlayer, Version v2.0                       *;
;* by VinsCool, 2022-2023                       *;
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

; Stereo is now supported with the LZSS driver!

STEREO		equ 0		; 0 => MONO, 255 => STEREO, 1 => DUAL MONO

; screen line for synchronization, important to set with a good value to get smooth execution

VLINE		equ 20		; nice round numbers fit well with multiples of 8 for every xVBI...
		ERT VLINE>155	; VLINE cannot be higher than 155!

; rasterbar colour

RASTERBAR	equ $69		; $69 is a nice purpleish hue

; VU Meter decay speed

SPEED		equ 1		; set the speed of decay rate, 0 is no decay, 255 is the highest amount of delay (in frames) 

;* Subtune index number is offset by 1, meaning the subtune 0 would be subtune 1 visually

TUNE_NUM	equ (SongIndexEnd-SongIndex)/4

;* end of VUPlayer definitions...

;---------------------------------------------------------------------------------------------------------------------------------------------;
	
; now assemble VUPlayer here... 

start       
	ldx #0			; disable playfield and the black colour value
	stx SDMCTL		; write to Shadow Direct Memory Access Control address
	jsr wait_vblank		; wait for vblank before continuing
	stx COLOR4		; Shadow COLBK (background colour), black
	stx COLOR2		; Shadow COLPF2 (playfield colour 2), black
	dex
	stx COLOR1
	mwa #dlist SDLSTL	; Start Address of the Display List
	mva #>FONT CHBAS     	; load the font address into the shadow character register
region_loop	
	lda VCOUNT
	beq check_region	; vcount = 0, go to check_region and compare values
	tax			; backup the value in index y
	bne region_loop 	; repeat
check_region
	stx region_byte		; will define the region text to print later
	ldy #SongSpeed		; defined speed value, which may be overwritten by RMT as well
PLAYER_SONG_SPEED equ *-1
	sty instrspeed		; will be re-used later as well for the xVBI speed value printed
	IFT REGIONPLAYBACK==0	; if the player region defined for PAL...
PLAYER_REGION_INIT equ *	
	lda tabppPAL-1,y
	sta acpapx2		; lines between each play
	cpx #$9B		; compare X to 155
	bmi set_ntsc		; negative result means the machine runs at 60hz		
	lda tabppPALfix-1,y
	bne region_done 
set_ntsc
	lda tabppNTSCfix-1,y	; if NTSC is detected, adjust the speed from PAL to NTSC
	ELI REGIONPLAYBACK==1	; else, if the player region defined for NTSC...
PLAYER_REGION_INIT equ *	
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
	lda #$20
	sta col3bak		; Red
	lda #$D0+1	
	sta col2bak		; Yellow
	lda #$B0-2
	sta col1bak		; Green
	ldx #50
	mva:rne txt_PAL-1,y line_0-1,y-
	beq is_DONE
is_NTSC				; VUMeter colours, NTSC colours were originally used
	lda #$40
	sta col3bak		; Red
	lda #$10+1	
	sta col2bak		; Yellow
	lda #$D0-2
	sta col1bak		; Green
	ldx #60
	mva:rne txt_NTSC-1,y line_0-1,y-
is_DONE	
	stx framecount		; X is either 50 or 60, defined by the region initialisation
	stx v_frame		; also initialise the actual frame counter with this value
	sty v_second		; Y is 0, reset the timer with it
	sty v_minute
	jsr stop_toggle		; clear the POKEY registers, initialise the LZSS driver, and set VUPlayer to Stop
	jsr set_subtune_count	; update the subtunes position and total values
	lda SKSTAT		; Serial Port Status
	and #$08		; SHIFT key being held?
	beq no_dma		; yes, skip the next 2 instructions
	ldx #$22		; DMA enable, normal playfield
	stx SDMCTL		; write to Shadow Direct Memory Access Control address
no_dma
	sta dma_flag		; will allow skipping drawing the screen if it was not enabled!
	ldx #120		; load into index x a 120 frames buffer
	jsr wait_vblank		; wait for vblank => 1 frame
	mwa #deli VDSLST	; set our own dli address to jump to
	mva #$C0 NMIEN		; enable vbi and dli interrupts
wait_init   
	jsr wait_vblank		; wait for vblank => 1 frame
	dex			; decrement index x
	bne wait_init		; repeat until x = 0, total wait time is ~2 seconds
init_done
	sei			; Set Interrupt Disable Status
	mwa VVBLKI oldvbi       ; vbi address backup
	mwa #vbi VVBLKI		; write our own vbi address to it 
wait_sync
	lda VCOUNT		; current scanline 
	cmp #VLINE		; will stabilise the timing if equal
	bne wait_sync		; nope, repeat
	jsr toggle_vumeter	; make sure this is also set properly before playing
	jsr play_pause_toggle	; now is the good time to set VUPlayer to Play

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
	sta WSYNC
check_play_flag
	lda is_playing_flag 		; 0 -> is playing, else it is either stopped or paused 
	bne loop			; in this case, nothing will happen until it is changed back to 0 
	lda #$80
	rasterbar_toggler equ *-1
	bpl do_play
	sty COLBK			; background colour 
	sty lastbk
do_play
	jsr setpokeyfull		; update the POKEY registers first, for both the SFX and LZSS music driver 
	jsr LZSSPlayFrame		; Play 1 LZSS frame
	jsr CheckForTwoToneBit		; if set, the Two-Tone Filter will be enabled 
	jsr set_progress_bar		; update the frames counter used by the progress bar for the current subtune 
	lda is_stereo_flag		; What is the current setup?
	beq dont_swap			; Mono detected -> do nothing 
	bmi do_swap			; Stereo detected -> swap Left and Right POKEY pointers
	jsr SwapBufferCopy		; Dual Mono detected -> copy the Left POKEY to Right POKEY directly
	bmi dont_swap			; Unconditional, the subroutine return with the value of $FF in Y 
do_swap	
	jsr SwapBufferCopy 		; copy over the register values, since this will be overwritten
	jsr LZSSCheckEndOfSong		; is the current LZSS index done playing? This might help catch the pointer overshooting it
	bne catch_a_loop		; if it did not yet reach the end, carry on, nothing to worry about here
	jsr SetNewSongPtrs		; in case it went out of bounds, this should prevent garbage data from playing back
catch_a_loop
	jsr LZSSPlayFrame		; Play 1 LZSS frame (for Right POKEY) 
	jsr CheckForTwoToneBit		; check for Two-Tone again too
	jsr SwapBuffer			; swap the POKEY memory addresses for Stereo compatibility during a fadeout
	jsr fade_volume_loop		; hah! got ya with this one running first this time, again for the same purpose
	jsr SwapBuffer			; revert to the original memory addresses for the next frame
dont_swap
	jsr fade_volume_loop		; run the fadeing out code from here until it's finished
	lda is_playing_flag		; was the player paused/stopped after fadeing out?
	beq do_play_next		; if equal, continue
	lda #0				; should VUPlayer play the next tune?
	stop_on_fade_end equ *-1
	bne do_stop			; if negative, the next tune will not play unless play is pressed again
dont_stop
	jsr do_play_pause_toggle	; since it's technically stopped, set back to play for the next tune
do_stop
	jsr seek_forward		; play the next tune
do_play_next
	jsr LZSSCheckEndOfSong		; is the current LZSS index done playing?
	bne do_play_done		; if not, go back to the loop and wait until the next call
	jsr SetNewSongPtrs		; update the subtune index for the next one in adjacent memory 
do_play_done
	ldy #$00			; black colour value
	sty COLBK			; background colour
	sty lastbk
VU_PLAYER_RTS_NOP equ *
	jmp loop			; infinitely

;-----------------

;---------------------------------------------------------------------------------------------------------------------------------------------;

;* VBI loop, run through all the code that is needed, then return with a RTI 

vbi
;	sta WSYNC		; horizontal sync, so we're always on the exact same spot, seems to help with timing stability 
	lda #0
;	lda #56
	sta COLBK
	ldx <line_4		; line 4 of text
	lda SKSTAT		; Serial Port Status
	and #$08		; SHIFT key being held?
	bne set_line_4		; nope, skip the next ldx
	ldx <line_5		; line 5 of text (toggled by SHIFT) 
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
	lda #$FF		; DMA flag, set to allow skipping drawing the screen if it was not enabled
	dma_flag equ *-1
	beq continue_c		; if the value is 0, nothing will be drawn, else, continue with everything below
	jsr test_vumeter_toggle	; process the VU Meter and POKEY registers display routines there
	jsr set_subtune_count	; update the subtune count on screen
	jsr set_play_pause_stop_button
	jsr set_highlight
	jsr print_player_infos	; print most of the stuff on screen using printhex or printinfo in bulk 
	jsr draw_progress_bar	; draw the progress bar during playback, using frames counted during export
continue_c	
	jsr calculate_time 	; update the timer, this one is actually necessary, so even with DMA off, it will be executed 
return_from_vbi			
	lda #0
	lastbk equ *-1
	sta COLBK
;	sta WSYNC		; horizontal sync, this seems to make the timing more stable
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
	txa
	pha
	tya
	pha
delistart
	lda #0
;	lda #$56
	sta COLBK
	lda #4
	sta COLPF0		; Gray
	ldx #3
	ldy #15
deliloop 
	sta WSYNC
	lda vumeter_toggle	; VUMeter or Registers View?
	bmi deliloop_a		; BMI -> Registers View, skip PF2 and PF3 update
	txa
	adc #0
	col3bak equ *-1		; Red
	sta COLPF3
	txa
	adc #0
	col2bak equ *-1		; Yellow
	sta COLPF2
deliloop_a
	txa
	adc #0
	col1bak equ *-1		; Green
	sta COLPF1
	dey
	bmi delireversal	; process the DEX branch if Y < 0
	inx
	sta WSYNC
	cpx #15
	bcc deliloop	
	ldy #0			; if Y does not match X yet, force it
	beq deliloop
delireversal
	dex
	cpx #7
	sta WSYNC
	bne deliloop
delivered	
	lda #0
	sta COLPF2		; necessary for clearing the PF2 colour to black before the DLI is finished
	sta COLBK
	sta WSYNC 	
	lda #$0F		; necessary for setting up the mode 2 text brightness level, else it's all black!
	sta COLPF1
delidone
	pla
	tay
	pla
	tax
	pla
	rti

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

;* Convert Hexadecimal numbers to Decimal without lookup tables 
;* Based on the routine created by Andrew Jacobs, 28-Feb-2004 
;* http://6502.org/source/integers/hex2dec-more.htm 

hex2dec_convert
	cmp #10			; below 10 -> 0 to 9 inclusive will display like expected, skip the conversion
	bcc hex2dec_convert_b
	cmp #100		; process with numbers below 99, else skip the conversion entirely 
	bcs hex2dec_convert_b  
hex2dec_convert_a
	sta hex_num		; temporary 
	sed
	lda #0			; initialise the conversion values
	sta dec_num
	sta dec_num+1
	ldx #7			; 8 bits to process 
hex2dec_loop
	asl hex_num 
	lda dec_num		; And add into result
	adc dec_num
	sta dec_num
	lda dec_num+1		; propagating any carry
	adc dec_num+1
	sta dec_num+1
	dex			; And repeat for next bit
	bpl hex2dec_loop
	cld			; Back to binary
	lda dec_num 
hex2dec_convert_b
	rts			; the value will be returned in the accumulator 

dec_num dta $00,$00
hex_num dta $00
	
;-----------------
	
;* VUPlayer specific code, for displaying the current player state

set_play_pause_stop_button
	ldx is_playing_flag		; what is the current state of the player?
	beq play_button_toggle		; #$00 -> is playing
	bpl pause_button_toggle		; #$01 -> is paused 
	ldx #16				; #$FF -> is stopped
stop_button_toggle
	bne play_button_toggle		; unconditional
pause_button_toggle 
	ldx #8				; offset by 8 for PAUSE characters	
play_button_toggle
	ldy #7				; 7 character buffer is enough 
	mwa #line_0e1 DISPLAY		; move the position to the correct line
	mwa #txt_PLAY infosrc		; set the pointer for the text data to this location
	jsr printinfo 			; write the new text in this location 
	ldx line_0e1			; the play/pause/stop character
	cpx #$7B			; is it the STOP character?
	bne play_button_toggle_a	; if not, overwrite the character in the buttons display with either PLAY or PAUSE
	inx				; else, make sure PLAY is loaded, then write it in memory 
play_button_toggle_a	
	stx b_play 			; overwrite the Play/Pause character
	rts

;-----------------

set_subtune_count
	ldx SongIdx
	inx
	cpx #$FF
current_subtune equ *-1
	beq set_subtune_count_done
	stx current_subtune		; set the new value in memory
	mwa #subtpos DISPLAY		; get the right screen position first
	txa
	jsr hex2dec_convert		; convert it to decimal 
	ldy #0
	jsr printhex_direct		; Y may not be 0 after the decimal conversion, do not risk it
	lda #TUNE_NUM
	SongTotal equ *-1
	jsr hex2dec_convert		; convert it to decimal 
	ldy #3				; offset to update the other number
	jsr printhex_direct		; this time Y will position where the character is written
set_subtune_count_done	
	rts
	
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
b_2	jmp do_play_pause_toggle; #2 => play/pause 
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
	ldx button_selection_flag	; this will be used for the menu selection below, if the key is matching the input... could be better
	lda KBCODE			; Keyboard Code  
	and #$3F			; clear the SHIFT and CTRL bits out of the key identifier for the next part
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
	bcc do_toggle_dli		; Y = 35 -> 'N' key
	rts:nop
	bcc do_toggle_pokey_mode	; Y = 37 -> 'M' key
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
	bcc do_set_speed_down		; Y = 48 -> '9' key
	rts:nop
	bcc do_set_speed_up		; Y = 50 -> '0' key
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
do_key_left
	jmp dec_index_selection 	; decrement the index by 1	
do_key_right
	jmp inc_index_selection 	; increment the index by 1 
do_trigger_fade_immediate
	lda is_playing_flag
	bne do_trigger_fade_immediate_a	; only engage the fadeout if playing
	lda is_fadeing_out
	beq do_trigger_fade_immediate_b	; only engage the fadeout if it is not already active
do_trigger_fade_immediate_a
	rts
do_trigger_fade_immediate_b
	dec stop_on_fade_end
	jmp trigger_fade_immediate	; immediately set the 'fadeout' flag then stop the player once finished
do_ppap_reverse	
	jmp fast_reverse2 		; decrement speed value 2 (ppap) 
do_ppap_forward
	jmp fast_forward2		; increment speed value 2 (ppap) 
do_lastpap_reverse
	jmp fast_reverse3		; decrement speed value 3 (lastpap) 
do_lastpap_forward
	jmp fast_forward3		; increment speed value 3 (lastpap) 
do_scroll_up
;	jmp scroll_up			; manually input VSCROL up for the VU Meter toggle, debug code
	rts
do_scroll_down
;	jmp scroll_down			; manually input VSCROL down for the VU Meter toggle, debug code
	rts
do_toggle_help
	rts
;	jmp toggle_help			; toggle the main player interface/help screen 
do_play_pause_toggle
	lda #0
	sta stop_on_fade_end
	jmp play_pause_toggle
do_stop_toggle
	lda #0
	sta stop_on_fade_end
	jmp stop_toggle
do_toggle_dli
	jmp toggle_dli
do_toggle_pokey_mode
	jmp toggle_pokey_mode
do_set_speed_down
	jmp set_speed_down
do_set_speed_up
	jmp set_speed_up
	
;----------------- 

; seek forward and reverse, both use the initialised flag + the new song pointers subroutine to perform it quickly
; reverse will land in the forward code, due to the way the song pointers are initialised, forward doesn't even need to increment the index!

seek_reverse
	ldx SongIdx
	dex
	bpl seek_done	
seek_wraparound
	ldx SongTotal
	dex 
	bne seek_done
seek_forward
	ldx SongIdx
	inx 
	cpx SongTotal
	bcc seek_done
	ldx #0
seek_done
	stx SongIdx
	jsr stop_pause_reset
	jsr reset_timer
	lda #0
	sta stop_on_fade_end		; always reset the flag for the next tune, regardless of being stopped first
	jmp SetNewSongPtrsFull

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
	rts
	
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

set_speed_up
	ldy PLAYER_SONG_SPEED
	iny
	cpy #17
	bcc set_speed_next
	ldy #0
	beq set_speed_next
set_speed_down
	ldy PLAYER_SONG_SPEED
	dey 
	bpl set_speed_next
	ldy #16
set_speed_next	
	sty PLAYER_SONG_SPEED
	lda region_byte
	cmp #$9B 
	bmi set_speed_ntsc
set_speed_pal
	lda tabppPAL-1,y
	sta acpapx2
	lda tabppPALfix-1,y
	sta ppap
	rts	
set_speed_ntsc
	lda tabppNTSC-1,y
	sta acpapx2
	lda tabppNTSCfix-1,y
	sta ppap
	rts

;-----------------

toggle_vumeter
	lda #$FF			; vumeter flag, 0 is vumeter, else FF displays the POKEY registers
	vumeter_toggle equ *-1
	eor #$FF		; invert bits 
	sta vumeter_toggle	; overwrite the flag with the new value
	bmi set_register_view
set_vumeter_view	
	mwa #mode_6 mode6_toggle
	lda #$44
	bpl set_view_addresses
set_register_view
	mwa #POKE1 mode6_toggle
	lda #$42
set_view_addresses
	sta mode6_toggle-1
	and #$0F
	ldx #2
set_view_addresses_loop
	sta mode6_toggle+2,x
	dex
	bpl set_view_addresses_loop
	rts

;-----------------
	
toggle_rasterbar 
	lda rasterbar_toggler	; rasterbar flag, a negative value means the rasterbar display is active 
	eor #$FF		; invert bits 
	sta rasterbar_toggler	; overwrite the rasterbar flag, execution continues like normal from here 
	rts 
	
;-----------------

toggle_loop
	lda loop_count		; loop flag, 0 is unset, else it is set with FF
	eor #$FF		; invert bits 
	sta loop_count		; overwrite the flag with the new value
	rts 
	
;-----------------

toggle_pokey_mode
	ldx is_stereo_flag
	beq toggle_dual_mono
	bpl toggle_stereo
toggle_mono
	lda #0
	ldx #8
toggle_mono_loop
	sta SDWPOK1,x			; clear the Right POKEY before switching back to Mono
	dex 
	bpl toggle_mono_loop 
	jsr setpokeyfullstereo		; apply the changes immediately to avoid any garbage data left in memory 
	beq toggle_pokey_mode_done 	; unconditional, all registers were set to 0 there :D
toggle_dual_mono
	inx 
	bpl toggle_pokey_mode_done
toggle_stereo
	ldx #$FF
toggle_pokey_mode_done
	stx is_stereo_flag
	rts

;-----------------

toggle_dli
	lda #$C0 
	dli_toggler equ *-1
	eor #$80
	sta dli_toggler
	sta NMIEN
	rts

;-----------------

; stop and quit

stopmusic 
	jsr stop_pause_reset 
	mwa oldvbi VVBLKI	; restore the old vbi address
	mva #$40 NMIEN		; enable vbi 
	ldx #$00		; disable playfield 
	stx SDMCTL		; write to Direct Memory Access (DMA) Control register
	dex			; underflow to #$FF
	stx CH			; write to the CH register, #$FF means no key pressed
	cli			; this may be why it seems to crash on hardware... I forgot to clear the interrupt bit!
	jsr wait_vblank		; wait for vblank before continuing
	jmp (DOSVEC)		; return to DOS, or Self Test by default

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

;* print most infos on screen
	
print_player_infos
	mwa #line_0a DISPLAY 	; get the right screen position
	
print_minutes
	lda v_minute
	ldy #8
	jsr printhex_direct
print_seconds
	ldx v_second
	txa
	iny
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

/*	
print_speed
	lda acpapx2
	ldy #17
	jsr printhex_direct 
print_speed2
	lda ppap
	ldy #20
	jsr printhex_direct
print_order	
	lda ZPLZS.SongPtr+1
	ldy #28
	jsr printhex_direct	
print_row
	lda ZPLZS.SongPtr 
	ldy #36
	jsr printhex_direct
*/
	
print_loop
	ldy #174
	lda loop_count		; verify if the loop flag is set to update the graphics accordingly
	bmi yes_loop		; it *should* be 0 if not looping, it will be overwritten anyway
	lda #0
	beq no_loop
yes_loop
	lda #"*" 
no_loop
	sta (DISPLAY),y 


Print_pointers
	ldy #23
	lda LZS.SongStartPtr+1
	jsr printhex_direct
	iny
	lda LZS.SongStartPtr
	jsr printhex_direct	
	ldy #34
	lda LZS.SongEndPtr+1
	jsr printhex_direct
	iny
	lda LZS.SongEndPtr
	jsr printhex_direct

/*
debug_progress_bar
	ldy #18
	lda bar_counter+0
	jsr printhex_direct
	iny
	lda bar_counter+1
	jsr printhex_direct
	iny
	lda bar_counter+2
	jsr printhex_direct
	iny
	iny
	lda bar_loop+0
	jsr printhex_direct
	iny
	lda bar_loop+1
	jsr printhex_direct
	iny
	lda bar_loop+2
	jsr printhex_direct
	iny
	iny
	lda bar_increment+0
	jsr printhex_direct
	iny
	lda bar_increment+1
	jsr printhex_direct
	iny
	lda bar_increment+2
	jsr printhex_direct
*/

	rts
	
;-----------------

test_vumeter_toggle
	lda vumeter_toggle	; the toggle flag will set which direction the scrolling goes
	bpl do_begindraw	; positive flag, VU Meter, else, POKEY registers, it will be one or the other
do_draw_registers
	jmp draw_registers	; end with a RTS
do_begindraw
	jmp begindraw		; end with a RTS

;-----------------

;* draw POKEY registers
;* this is incredibly crappy code but it gets the job done...

draw_registers
	mwa #POKE2 DISPLAY	; set the position on screen
	ldx #0
	ldy #7

draw_left_pokey
	lda SDWPOK0,x
	stx reload_x_left
	jsr printhex_direct
	:3 iny
	ldx #0
	reload_x_left equ *-1 
	:2 inx
	cpx #8
	bcc draw_left_pokey
	cpy #60
	bcs draw_left_pokey_next
	ldx #1
	ldy #47
	bpl draw_left_pokey
draw_left_pokey_next
	lda POKCTL0
	ldy #95
	jsr printhex_direct
	lda POKSKC0
	ldy #99
	jsr printhex_direct
	lda is_stereo_flag
;	beq draw_registers_mono	

draw_registers_done	
	rts

;-----------------

;* Draw the VUMeter display and process all the variables related to it

begindraw
	mwa #mode_6+4 DISPLAY
	ldx #7			; 4 AUDF + 4 AUDC
begindraw1
	lda SDWPOK0,x
	and #$0F
	beq reset_decay_a	; 0 = no volume to write into the buffer
	sta temp_volume		; self modifying code
begindraw2
	lda SDWPOK0-1,x
	eor #$FF		; invert the value, the pitch goes from lowest to highest from the left side
	:3 lsr @		; divide by 8
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
drawnow	
	ldx #3			; for 4 lines 
drawagain
	lda vu_tbl,x
	sta tbl_colour
	txa
	dex
	stx drawloopcount
	ldy #31
	asl @ 
	asl @ 
	sta drawlinesub
drawlineloop
	lda decay_buffer,y
	beq drawemptyline
	sub #0
	drawlinesub equ *-1
	beq drawemptyline
	bpl drawlineloop_good
drawemptyline
	lda #vol_0
	bpl drawlinenothing
drawlineloop_good
	cmp #4 
	bcc drawlineloop_part
	lda #3
drawlineloop_part
	adc #0			; carry will be added for values above 3, to draw 4 bars per line
	tbl_colour equ *-1
drawlinenothing
	sta (DISPLAY),y
	dey
	bpl drawlineloop
drawnext
	ldx #$FF
	drawloopcount equ *-1
	bmi drawdone
	lda DISPLAY		; current memory address used for the process
	add #40			; mode 4 uses 40 characters per line
	sta DISPLAY		; adding 20 will move the pointer to the next line
	scc:inc DISPLAY+1	; in case the boundary is crossed, the pointer MSB will increment as well
	jmp drawagain
drawdone
	dec decay_speed
	bpl decay_done		; if value is positive, it's over, wait for the next frame 
reset_decay_speed
	lda #SPEED
	sta decay_speed		; reset the value in memory, for the next cycle
do_decay
	ldx #31 
	lda #0
decay_next
	dec decay_buffer,x
	bpl decay_good
	sta decay_buffer,x
decay_good
	dex
	bpl decay_next	
decay_done
	rts
	
vol_0	equ $46
vol_grn	equ $47
vol_ylw	equ $4B
vol_red	equ $CB

decay_buffer
	:32 dta $00 
decay_speed
	dta $00
vu_tbl
	dta vol_grn-1, vol_grn-1, vol_ylw-1, vol_red-1

;-----------------

;* An attempt to display the subtune progression on screen with a progress bar and a cursor to nearest point in time
;* There are 32 sections, and 8 subsections within each ones of them, for a total of 256 pixels that could be used with this
;* Roughly, I need to divide a target value by 32 for the coarse movements, then by 8 for the fine movements, I think?
;* The result should then be the value number of bytes per coarse/fine movements, which can then be used to draw the progress bar
;* I might be very wrong, but this is worth a try :D
;* Cross region situations are to be expected, 50 frames per second will be assumed by default for all time references
;* This is some code I've managed to reverse engineer from rensoupp's LZSS export binary player... :eyes:

bar_cur	equ $4F
bar_lne	equ $57

bar_counter
	dta $00,$00,$00
bar_loop
	dta $00,$00,$00
bar_increment
	dta $00,$00,$00

set_progress_bar
	clc
	lda bar_counter+2
	adc bar_increment+2
	sta bar_counter+2
	lda bar_counter+1
	adc bar_increment+1
	sta bar_counter+1
	lda bar_counter+0
	adc bar_increment+0
	bcc calculate_progress_bar_a
	lda #$FF				; bar was maxed out, it won't be updated further
calculate_progress_bar_a
	sta bar_counter+0
set_progress_bar_done
	rts

draw_progress_bar
	mwa #line_0c+4 DISPLAY 
	lda bar_counter+0
	tax
	lsr @
	lsr @
	lsr @
	tay 
	sta draw_empty_bar_count
	txa
	and #$07
	clc 
	adc #bar_cur
	sta (DISPLAY),y
	dey 
	bmi draw_progress_bar_below_8
	lda #bar_lne 
draw_progress_bar_loop1
	sta (DISPLAY),y
	dey 
	bpl draw_progress_bar_loop1
draw_progress_bar_below_8
	ldy #31
	tya
	sec 
	sbc #0
	draw_empty_bar_count equ *-1
	tax 
	dex 
	bmi draw_progress_bar_done
	lda #0
draw_progress_bar_loop2
	sta (DISPLAY),y
	dey 
	dex
	bpl draw_progress_bar_loop2 
draw_progress_bar_done
	rts

;---------------------------------------------------------------------------------------------------------------------------------------------;

;* line counter spacing table for instrument speed from 1 to 16

;-----------------

;* the idea here is to pick the best sweet spots each VBI multiples to form 1 "optimal" table, for each region
;* it seems like the number of lines for the 'fix' value MUST be higher than either 156 for better stability
;* else, it will 'roll' at random, which is not good! better sacrifice a few lines to keep it stable...
;* strangely enough, NTSC does NOT suffer from this weird rolling effect... So that one can use values above or below 131 fine

;	    x1  x2  x3  x4  x5  x6  x7  x8  x9  x10 x11 x12 x13 x14 x15 x16 

	dta $EA
tabppPAL	; "optimal" PAL timing table
	dta $9C,$4E,$34,$27,$20,$1A,$17,$14,$12,$10,$0F,$0D,$0C,$0C,$0B,$0A
	
	dta $9C
tabppPALfix	; interval offsets for timing stability 
	dta $9C,$9C,$9C,$9C,$A0,$9C,$A1,$A0,$A2,$A0,$A5,$9C,$9C,$A8,$A5,$A0
	
;-----------------
	
;* NTSC needs its own adjustment table too... And so will cross-region from both side... Yay numbers! 
;* adjustments between regions get a lot trickier however...
;* for example: 
;* 1xVBI NTSC to PAL, 130 on 156 does work for a stable rate, but it would get all over the place for another number 

;	    x1  x2  x3  x4  x5  x6  x7  x8  x9  x10 x11 x12 x13 x14 x15 x16 
	
	dta $FC
tabppNTSC	; "optimal" NTSC timing table
	dta $82,$41,$2B,$20,$1A,$15,$12,$10,$0E,$0D,$0B,$0A,$0A,$09,$08,$08
	
	dta $7E
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


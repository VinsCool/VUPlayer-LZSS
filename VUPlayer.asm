;************************************************;
;* VUPlayer, Version v0.2 WIP                   *;
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

REGIONPLAYBACK	equ 0		; 0 => PAL, 1 => NTSC

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

start       
	ldx #0			; disable playfield and the black colour value
	stx SDMCTL		; write to Shadow Direct Memory Access Control address
	jsr wait_vblank		; wait for vblank before continuing
	stx COLOR4		; Shadow COLBK (background colour), black
	stx COLOR2		; Shadow COLPF2 (playfield colour 2), black
	mwa #dlist SDLSTL	; Start Address of the Display List
	mva #>FONT CHBASE     	; load the font address into the character register, I'm not sure why at the moment but it seems like I must reload it every frame during the initialisation...
;	mwa #line_0 DISPLAY	; initialise the Display List indirect memory address for later

;-----------------
	
set_colours			; VUMeter colours -- TODO: adjust between PAL and NTSC palettes
	lda #74
	sta COLOR3
	lda #223
	sta COLOR1
	lda #30
	sta COLOR0

;-----------------

;* TODO: fix this shit
	
initialise_player
	jsr stop_pause_reset	; clear the POKEY registers first
	jsr SetNewSongPtrsFull	; initialise the LZSS driver with the song pointer using default values always
	ldy #SongSpeed		; hardcoded to 1 for the moment
adjust_check
	beq adjust_check_a	; Y is 0 if equal, this is invalid!
	bpl adjust_check_b	; Y = 1 to 127, however, 16 is the maximum supported
adjust_check_a
	ldy #1			; if Y is 0, nagative, or above 16, this will be bypassed!
adjust_check_b
	cpy #17			; Y = 17?
	bcs adjust_check_a	; everything equal or above 17 is invalid! 
adjust_check_c
	sty instrspeed		; print later ;)
	cpy #5
	bcc do_speed_init	; all values between 1 to 4 don't need adjustments
	beq adjust_5vbi
	cpy #7
	beq adjust_7vbi
	cpy #8
	beq adjust_8vbi
	cpy #9
	beq adjust_9vbi
	cpy #10
	beq adjust_10vbi	
	cpy #11
	beq adjust_7vbi
	cpy #14
	beq adjust_7vbi
	cpy #15
	beq adjust_10vbi 
adjust_9vbi			; 16 is the maximal number supported, and uses the 9xVBI fix
	lda #153		; fixes 9xVBI, 16xVBI
	bne do_vbi_fix
adjust_5vbi
	lda #155		; fixes 5xVBI
	bne do_vbi_fix
adjust_7vbi
	lda #154		; fixes 7xVBI, 11xVBI, 14xVBI
	bne do_vbi_fix
adjust_8vbi
	lda #152		; fixes 8xVBI
	bne do_vbi_fix
adjust_10vbi
	lda #150		; fixes 10xVBI, 15xVBI
do_vbi_fix
	sta onefiftysix
	
;-----------------
	
do_speed_init
	lda tabpp-1,y		; load from the line counter spacing table
	sta acpapx2		; lines between each play
	sta backup_speed	; will be used to reset the speed in FF/RW mode
current_speed equ *-1
	lda SKSTAT		; Serial Port Status
	and #$08		; SHIFT key being held?
	beq no_dma		; yes, skip the next 2 instructions
	ldx #$22		; DMA enable, normal playfield
	stx SDMCTL		; write to Shadow Direct Memory Access Control address
no_dma
	ldx #100		; load into index x a 100 frames buffer
wait_init   
	jsr wait_vblank		; wait for vblank => 1 frame
	mva #>FONT CHBASE	
	dex			; decrement index x
	bne wait_init		; repeat until x = 0, total wait time is ~2 seconds
region_init			; 50 Hz or 60 Hz?
	stx VCOUNT		; x = 0, use it here
	ldx #156		; default value for all regions
onefiftysix equ *-1		; adjustments
region_loop	
	lda VCOUNT
	beq check_region	; vcount = 0, go to check_region and compare values
	tay			; backup the value in index y
	bne region_loop 	; repeat
	
;-----------------
	
check_region
	cpy #$9B		; compare index y to 155
	IFT REGIONPLAYBACK==0	; if the player region defined for PAL...
	bpl region_done		; negative result means the machine runs at 60hz
	ldx #130		; NTSC is detected, adjust the speed from PAL to NTSC
	ELI REGIONPLAYBACK==1	; else, if the player region defined for NTSC...
	bmi region_done		; positive result means the machine runs at 50hz
	ldx #186		; PAL is detected, adjust the speed from NTSC to PAL
	lda instrspeed		; Note that this timing hack is poorly executed, and unfinished, this code will be rewritten in a future VUPlayer revision...
	cmp #1
	beq subonetotiming	; 1xVBI is stable if 1 is subtracted from the value, 186 must be used!
	cmp #2
	beq subfourtotiming	; 2xVBI is stable if 4 is subtracted from the value, 185 must be used!
	cmp #3
	beq region_done		; 3xVBI is stable without a subtraction
	cmp #4
	beq subtwototiming	; 4xVBI is stable if 2 is subtracted from the value, 185 must be used!
subfourtotiming
;	ldx #185
	dec acpapx2		; stabilise NTSC timing in PAL mode
subthreetotiming
	dec acpapx2		; stabilise NTSC timing in PAL mode
subtwototiming
	ldx #185
	dec acpapx2		; stabilise NTSC timing in PAL mode	
subonetotiming
	dec acpapx2		; stabilise NTSC timing in PAL mode
	EIF			; endif

;-----------------
	
region_done
	sty region_byte		; set region flag to print later
	stx ppap		; value used for screen synchronisation
	sei			; Set Interrupt Disable Status
	mwa VVBLKI oldvbi       ; vbi address backup
	mwa #vbi VVBLKI		; write our own vbi address to it	
	mva #$40 NMIEN		; enable vbi interrupts
	mva #>FONT CHBASE
	
;-----------------

; print instrument speed, done once per initialisation

	mwa #line_0 DISPLAY	; initialise the Display List indirect memory address for later
	ldy #4			; 4 characters buffer 
	lda #0
instrspeed 	equ *-1
	jsr printhex_direct
	lda #0
	dey			; Y = 4 here, no need to reload it
	sta (DISPLAY),y 
	mva:rne txt_VBI-1,y line_0+5,y-
	
;-----------------
	
; print region, done once per initialisation

	ldy #4			; 4 characters buffer 
	lda #0
region_byte	equ *-1
	cmp #$9B
	bmi is_NTSC
is_PAL
	ldx #50
	mva:rne txt_PAL-1,y line_0-1,y-
	beq is_DONE
is_NTSC
	ldx #60
	mva:rne txt_NTSC-1,y line_0-1,y-
is_DONE				
	sty v_second		; Y is 0, reset the timer with it
	sty v_minute	
	stx framecount		; X is either 50 or 60, defined by the region initialisation
	stx v_frame		; also initialise the actual frame counter with this value
ready_to_play
	ldy #7			; enough characters buffer, used to set the PLAY status display 
	mva:rne txt_PLAY-1,y line_0e1-1,y- 
	jsr set_subtune_count	; update the subtunes position and total values
	jsr set_highlight	; set the first highlighted button selection, PLAY by default 

;------------------
	
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
	
check_play_flag	
	lda is_playing_flag 		; 0 -> is playing, else it is either stopped or paused, and must not run into rmtplay again 
	bne loop			; otherwise, the player is either paused or stopped, in this case, nothing will happen until it is changed back to 0

	lda #$80			; lda #$80 to display the rasterbar by default, 0 sets it hidden otherwise 
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
	ldy #0				; black colour value
	sty WSYNC			; horizontal sync
	sty COLBK			; background colour
	sty COLPF2			; playfield colour 2 
	jmp loop			; infinitely

;-----------------

;---------------------------------------------------------------------------------------------------------------------------------------------;

;* VBI loop

vbi
	sta WSYNC		; horizontal sync, so we're always on the exact same spot
	ldy KBCODE		; Keyboard Code  
	ldx <line_4		; line 4 of text
	lda SKSTAT		; Serial Port Status
	and #$08		; SHIFT key being held?
	bne set_line_4		; nope, skip the next ldx
	ldx <line_5		; line 5 of text (toggled by SHIFT) 
	tya
	eor #$40		; invert the SHIFT key flag so it will be ignored later
	tay
set_line_4  
	stx txt_toggle		; write to change the text on line 4 
	
;-----------------
	
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
	
;-----------------	
	
continue_b 			; a key was detected as held when jumped directly here
	jsr set_subtune_count	; update the subtune count on screen

calculate_time 
	lda is_playing_flag 
	bne notimetolose	; not playing -> no time counter increment  
	dec v_frame		; decrement the frame counter
	bne notimetolose	; not 0 -> a second did not yet pass
	lda #0
framecount equ *-1		; 50 or 60, defined by the region initialisation
	sta v_frame		; reset the frame counter
	bne addasecond		; unconditional
	nop
v_frame equ *-1			; the NOP instruction is overwritten by the frame counter	
addasecond
	sed			; set decimal flag first
	lda #0
v_second equ *-1
	clc			; clear the carry flag first, the keyboard code could mess with this part now...
	adc #1			; carry flag is clear, add 1 directly
	sta v_second
	cmp #$60		; 60 seconds, must be a HEX value!
	bne cleardecimal 	; if not equal, no minute increment
	ldy #0			; will be used to clear values quicker
addaminute
	lda #0
v_minute equ *-1
	adc #0			; carry flag is set above, adding 0 will add 1 instead
	sta v_minute
	sty v_second		; reset the second counter
cleardecimal 
	cld			; clear decimal flag 
notimetolose
	
;-----------------
	
;* TODO: optimise the code running here so it won't hog all the VBI time
	
; get the right screen position
	mwa #line_0a DISPLAY 

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
	beq print_order
	sta old_speed
	ldy #20
	eor #$FF			; invert the value so it looks like faster == higher value
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
	bmi yes_loop		; it *should* be 0 if not looping, it will be overwritten anyway
	lda #0
	beq no_loop
yes_loop
	lda #"*" 
no_loop
	sta (DISPLAY),y 
	
;-----------------

	jsr print_pointers	; update the pointers displayed on screen (terrible code but I want to make a proper loop for it...) 
	lda vumeter_toggle
	bpl begindraw

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
	
	jmp return_from_vbi 	; done
	nop
	countdown equ *-1

;-----------------

;* TODO: move this code elsewhere, this hogs too much VBI time!
;* TODO2: this code could be MUCH better too...

; draw the volume blocks
	
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
	
;-----------------

return_from_vbi
	pla			; since we're in our own vbi routine, pulling all values manually is required
	tay
	pla
	tax
	pla
	sta WSYNC		; horizontal sync, this seems to make the timing more stable
	rti			; return from interrupt

;-----------------

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

; fast setpokey variant, intended for double buffering the decompressed LZSS bytes as fast as possible for timing and cosmetic purpose

SDWPOK0
POKF0	dta $00
POKC0	dta $00
POKF1	dta $00
POKC1	dta $00
POKF2	dta $00
POKC2	dta $00
POKF3	dta $00
POKC3	dta $00
POKCTL0	dta $00
POKSKC0	dta $03		; SKCTL, currently not used by the LZSS driver...

setpokeyfull
	lda POKSKC0	; SKCTL initialisation is never done from the LZSS driver, so let's do it manually here
	sta $D20F	; SKCTL, currently not used by the LZSS driver...
setpokeyfast
	ldy POKCTL0
	lda POKF0
	ldx POKC0
	sta $D200
	stx $D201
	lda POKF1
	ldx POKC1
	sta $D202
	stx $D203
	lda POKF2
	ldx POKC2
	sta $D204
	stx $D205
	lda POKF3
	ldx POKC3
	sta $D206
	stx $D207
	sty $D208
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

; toggle Stop, similar to pause, but Play will restart the subtune from the beginning
; unlike Play/Pause, Stop could only be done once! 
; this is done in order to prevent the "pressing Stop causes the player to seek 1 tune back" bug...
;* TODO: make this a proper subroutine

stop_toggle
	jsr stop_pause_reset		; pause the player and clear the AUDC registers 
	lda is_playing_flag		; is it already stopped?
	cmp #1
	bne stop_toggle_a		; not equal -> not yet stopped
	rts 
stop_toggle_a
	ldy #1
	sty is_playing_flag		; 1 -> player stopped
	dey				; Y = 1 -> Y = 0
	sty LZS.Initialized		; reset LZSS initialisation flag
	sty is_fadeing_out		; make sure to stop it too!
	sty stop_on_fade_end
	dec SongIdx			; decrement the index position from LZSSP only once, essentially resetting the subtune
	jsr SetNewSongPtrsLoopsOnly	; update the pointers and also reset the play/loop count in the process
	jsr reset_timer 		; clear the timer in STOP mode, unlike PAUSE, which would simply freeze the value until it is unpaused
	ldx #16				; offset by 16 for STOP characters
	bne play_pause_button_toggle_a	; finish in the play_pause code from here, unconditional 

;-----------------

; toggle Play/Pause mode
;* TODO: make this a proper subroutine

play_pause_toggle 
	lda #156
backup_speed equ *-1
	cmp acpapx2
	beq play_pause_toggle_a
	sta acpapx2
	bne set_play			; return to normal speed and continue playing
play_pause_toggle_a
	lda #0
	is_playing_flag equ *-1 
	beq set_pause			; 0 -> currently playing, else, it was either paused or stopped 
set_play 
	ldx #0				; will set the play flag to 0, and also the offset for the PLAY characters 
	stx is_playing_flag
	beq play_pause_button_toggle_a
set_pause 
	dec is_playing_flag		; 00 -> FF
	jsr stop_pause_mute		; pause the player and clear the AUDC registers 
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

reset_timer
	lda #0
	sta v_second		; reset the seconds counter
	sta v_minute		; reset the minutes counter
	lda framecount		; number of frames defined at initialisation  
	sta v_frame		; reset the frames counter 
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

; pause the player and reset the registers

stop_pause_reset
	lda #0			; default values
	ldy #8
stop_pause_reset_a 
	sta SDWPOK0,y		; clear the POKEY values in memory
	dey 
	bpl stop_pause_reset_a	; repeat until all channels were cleared 
	jsr setpokeyfull	; overwrite the actual registers, including SKCTL, just in case
	rts

;----------------- 

; mute the channels but do not overwrite the AUDF or AUDCTL so the contents gets re-used as soon as it's playing 

stop_pause_mute
	lda #0			; default values
	ldy #7			; begin on the last channel's AUDC
stop_pause_mute_a 
	sta SDWPOK0,y		; clear the AUDC values ONLY
	:2 dey 			; DEY twice to avoid the AUDF values
	bpl stop_pause_mute_a	; repeat until all channels were cleared 
	jsr setpokeyfast	; overwrite the actual registers
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
b_2	jmp play_pause_toggle	; #2 => play/pause 
	nop
b_3	jmp fast_forward 	; #3 => fast forward (increment speed) 
	nop
b_4	jmp seek_forward 	; #4 => seek forward 
	nop
b_5	jmp stop_toggle 	; #5 => stop
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
	rts:nop
	bcc b_6				; Y = 28 -> 'Escape' key
	rts:nop
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
	bcc do_trigger_fade_immediate	; Y = 56 -> 'F' key
	rts:nop
	bcc do_key_right		; Y = 58 -> 'D' key
	rts:nop
	rts:nop
	rts:nop
	rts:nop
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

; songline_seek, must be rewritten

fast_reverse
	inc acpapx2
	rts
fast_forward
	dec acpapx2
	rts 
	
;-----------------	

; seek forward and reverse, both use the initialised flag + the new song pointers subroutine to perform it quickly
; reverse will land in the forward code, due to the way the song pointers are initialised, forward doesn't even need to increment the index!

seek_wraparound
	ldx total_subtune		; the total number is also offset by 1
	inx				; increment once, reverse will decrement twice!
	stx SongIdx			; overwrite the index with the new value, continue like normal in the reverse code
seek_reverse
	dec SongIdx			; decrement the index position from LZSSP 
	beq seek_wraparound		; in case it landed on 0, do not go further! else it will be out of bounds!
	dec SongIdx			; decrement again if it was not on 0, it will increment back to the expected value 
seek_forward
	lda #0
	sta LZS.Initialized		; reset the LZSS state again
	sta is_fadeing_out		; make sure to disable fading out as well!
	jsr SetNewSongPtrsLoopsOnly	; update the pointers and also reset the play/loop count in the process
	rts 

;-----------------

toggle_vumeter
	ldx <mode_6
	lda #0			; vumeter flag, 0 is vumeter, else FF displays the POKEY registers
	vumeter_toggle equ *-1
	eor #$FF		; invert bits 
	sta vumeter_toggle	; overwrite the flag with the new value
	bpl toggle_vumeter_a
	ldx <POKE1
toggle_vumeter_a	
	stx mode6_toggle
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

;* Volume fadeout subroutine

fade_volume_loop
	lda is_playing_flag	; is the tune currently playing?
	bne fade_volume_done	; if paused or stopped, skip this subroutine!
check_if_fading 
	lda #0			; fadeing out timer and flag
	is_fadeing_out equ *-1
	beq fade_volume_done	; equal 0 means it is not set, and must be skipped
	bpl continue_fadeout	; above 0 means it is already set, skip initialising again
begin_fadeout
	lda #1			; unit of volume to subtract
	sta is_fadeing_out	; flag and initial fade volume set
	lda v_second		; current second
	sta last_second_seen	; initialise the timer for fadeout
continue_fadeout	
	ldy #7			; index from the 4th AUDC 
fade_volume_loop_a
	lda SDWPOK0,y		; current POKEY buffer
	tax			; backup for the next step
	and #$0F		; keep only the volume values
	sec			; set carry for the subtraction
	sbc is_fadeing_out	; subtract the fading value directly
	beq volume_loop_again	; if value = 0, write that value directly
	bpl set_new_volume	; else if the subtraction did not overflow, continue with the next step
	lda #0			; else, set the volume to 0 
	beq volume_loop_again	; unconditional 
set_new_volume	
	sta ora_volume		; this value will be used for the ORA instruction 
	txa			; get back the AUDC value loaded a moment before
	and #$F0		; only keep the Distortion bits
	ora #0			; combine the new volume to it
	ora_volume equ *-1
volume_loop_again
	sta SDWPOK0,y		; write the new AUDC value in memory for later
	:2 dey			; decrement twice to only load the AUDC
	bpl fade_volume_loop_a	; continue this loop until Y overflows to $FF 
	lda v_second		; current second count
	cmp #0			; compare to the last second loaded 
	last_second_seen equ *-1
	beq fade_volume_done	; equal means 1 second has not yet passed, done
	sta last_second_seen	; otherwise, this becomes the new value to compare
	inc is_fadeing_out	; increment the fadeout value to subtract by 1 
	lda is_fadeing_out	; load that value for the comparison 
	cmp #11			; 10 seconds must have passed to reach 10 units
	bcc fade_volume_done	; if the value is below the count, done 	
	lda #0			; this flag tells the player if it should also stop upon fadeing out!
	stop_on_fade_end equ *-1
	bpl fade_volume_play	; positive value: continue playing
	jmp stop_toggle		; else, stop the player once the end of the fadeout is reached	
fade_volume_play	
	jmp seek_forward	; end the song prematurely, and seek the next subtune as soon as this is reached!
fade_volume_done
	rts

;-----------------

;* IMPORTANT NOTE: 
;*
;* Indexing using X the INX for the next subtune will only work properly if all tunes are in sequential order!
;* If things are not exactly adjacent, things will break!
;* The only reason why I decided to use this method was to index all subtunes very easily
;* But then I realised that re-using data will cause problems since the pointers won't be alligned anymore!
;* With that in mind, as long as the subtunes are all in sequential order, the method will work perfectly fine!
;* 
;* TODO: add an alternative index for 'looped' tunes, so they will seamlessly play infinitely!
;* This would also mitigate the issues organising all the data as well
           
SetNewSongPtrsFull       
	ldx #0
	stx SongIdx 	
	stx is_fadeing_out
SetNewSongPtrsLoopsOnly
	lda #4
	sta is_looping 
SetNewSongPtrs
	ldx SongIdx				; current song index
	cpx #SongsIndexEnd-SongsIndexStart 
	SongTotal equ *-1		
	bcc SetNewSongPtrs_a			; continue, index is in the valid range
	beq test_boundaries			; if index is equal to total, make sure it was from previously being set!
	bcs SetNewSongPtrsFull			; else, it overshot, and must wrap around!
test_boundaries 
	lda is_looping				; is the loop flag set? if it is not, there is a wrap around to do!	
	cmp #4					; 2 and below -> all good, 4 or above -> pointers are about to be set, bad!
	bcs SetNewSongPtrsFull
SetNewSongPtrs_a
	dec is_looping				; must start at 4!
	lda #4					; is the 'loop' flag set?
	is_looping equ *-1
	bmi SetNewSongPtrsFull			;* if this happens, you did something wrong, Vin!
	beq trigger_fade			; loop already set
	cmp #1
	beq DontSet				; looping, so no need to update pointers
	cmp #2
	beq iliketosingaloopy			; load the loop subtune pointers 
SetNewSongPtrs_b
	lda is_fadeing_out
	bne DontSet				; keep looping until fade finished, it's too early to load a new subtune!
	lda SongsSLOPtrs,x
	sta LZS.SongStartPtr
	lda SongsSHIPtrs,x
	sta LZS.SongStartPtr+1
	inx 					; Song end is always the one byte adjacent to it-- *see the note above
	lda SongsSLOPtrs,x
	sta LZS.SongEndPtr
	lda SongsSHIPtrs,x
	sta LZS.SongEndPtr+1
	stx SongIdx				; update the index with X already 1 position ahead
	jsr check_loop_for_dummies		; carry flag will be returned
	bcc SetNewSongPtrs			; carry clear -> dummy
DontSet	
	rts

;-----------------	
		
;* TODO: index this shit better, this is just poorly done, Vin! You can do better than that
		
iliketosingaloopy
	dex				; first start by DEX so it will land on the correct spot always!
	lda LoopsSLOPtrs,x
	sta LZS.SongStartPtr
	lda LoopsSHIPtrs,x
	sta LZS.SongStartPtr+1
	inx				; Song end is always the one byte adjacent to it-- *see the note above
	lda LoopsSLOPtrs,x
	sta LZS.SongEndPtr
	lda LoopsSHIPtrs,x
	sta LZS.SongEndPtr+1
	stx SongIdx			; update the index with X already 1 position ahead
	jsr check_loop_for_dummies	; carry flag will be returned
	bcs DontSet			; carry set -> not a dummy
	jmp SetNewSongPtrsLoopsOnly	; else, return to the subroutine's start and do it again!

;-----------------

;* TODO: make the fadeout trigger its own subroutine, and also force a play/loop count flag to initialise a 'loop' as well
;* this would provide the ability to initialise a fadeout from anything that may require a transition in a game/demo :3
	
trigger_fade_immediate
	lda is_playing_flag	; is the player currently in 'play' mode?
	bne trigger_fade_b	; if not, skip this subroutine, there is nothing else to do
	lda is_fadeing_out	; is the tune currently playing already engaged in a fadeout?
	bne trigger_fade_b	; if not 0, there is a fadeout in progress! skip this subroutine
	lda #3			; will roll back to 2 on the end of song if reached early, allowing loop during fadeout
	sta is_looping		
	dec stop_on_fade_end	; set the flag to tell the player to send a stop command once this is reached!
	bne trigger_fade_a	; unconditional, this will also bypass the player's own 'loop' flag!
trigger_fade 
	lda #0			; new 'loop' flag, instead of using the already messy counter value
	loop_toggle equ *-1
	bpl trigger_fade_a	; if positive, not looping, finish like normal with a fadeout!
	inc is_looping		; 0 -> 1, sneaky way to work around it, it will loop infinitely
	bpl trigger_fade_b	; unconditional, the tune will now loop for as long as the flag is set!	
trigger_fade_a 
	dec is_fadeing_out	; $00 -> $FF, the fadeout flag is set
trigger_fade_b
	rts
	
;-----------------

;* Carry flag returns the status
;* Carry Clear -> Dummy/Invalid subtune length
;* Carry Set -> Should be perfectly fine data, unless wrong pointers were set, garbage would play!

check_loop_for_dummies
	lda LZS.SongEndPtr+1
	cmp LZS.SongStartPtr+1
	bne dummy_check_done	; END is either above or below START, in any case, the Carry flag will tell the truth!
maybe_a_dummy	
	lda LZS.SongEndPtr
	sec
	sbc LZS.SongStartPtr
	cmp #2			; should be short enough...
dummy_check_done
	rts			; done! the carry flag will dictate what to do
        
;-----------------

;* print current subtune pointer addresses 
;* this could be a lot better than that...

Print_pointers
	mwa #line_0a DISPLAY	; get the right screen position first
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

;---------------------------------------------------------------------------------------------------------------------------------------------;
        
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

; line counter spacing table for instrument speed from 1 to 16

tabpp       
	dta 156,78,52,39,31,26,22,19,17,15,14,13,12,11,10,9 

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


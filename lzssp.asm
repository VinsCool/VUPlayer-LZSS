;* When used in a project, the LZSS driver must be assembled from this file!
;* Include everything needed below, and edit accordingly.

;-----------------

;//---------------------------------------------------------------------------------------------

;* Build flags, they are not the requirement, and could be changed if necessary 

	OPT R- F-
	icl "atari.def"			; Missing or conflicting labels cause build errors, be extra careful! 

;-----------------

;//---------------------------------------------------------------------------------------------

;* ORG addresses can always be changed based on how memory is layed out, as long as it fits, it should work fine

ZEROPAGE	equ $0000		; Zeropage, the addresses may be changed if necessary, required
DRIVER		equ $0800		; LZSS driver and data 

;-----------------

;//---------------------------------------------------------------------------------------------

;* The Zeropage is a requirement, but could be edited is necessary 

	ORG ZEROPAGE
.PAGES 1
	icl "lzsspZP.asm"
.ENDPG

;-----------------

;//---------------------------------------------------------------------------------------------

;* The unrolled LZSS driver + Buffer will be inserted here first, it is a requirement!

	org DRIVER
;	icl "playlzs16u.asm"		; Unrolled LZSS driver by rensoupp, faster but requires more memory 
	icl "playlzs16-dumb.asm"	; Modified LZSS driver based on DMSC's original code, smaller but requires more CPU

;-----------------

;//---------------------------------------------------------------------------------------------
               
;* Several subroutines added for VUPlayer have been split to become part of the driver itself, allowing new features for future projects easily!

;-----------------

;* Song index initialisation subroutine, load pointers using index number, as well as loop point when it exists 
           
SetNewSongPtrsFull 			; if the routine is called from this label, index and loop are restarted
	ldx #0
	stx is_fadeing_out		; reset fadeout flag, the new index is loaded from start
	stx is_looping 			; reset the loop counter, the new index is loaded from start 
	stx loop_count
	lda #0				; current tune index, must be set before the routine is executed
	SongIdx equ *-1 
	asl @				; multiply by 2, for the hi and lo bytes of each address 
	asl @				; multiply again, offset each songs by 4 bytes
	tax 
	lda SongIndex,x
	sta SongPtr+0
	inx 
	lda SongIndex,x
	sta SongPtr+1
	inx 
	lda SongIndex,x
	sta SectionPtr+0
	inx 
	lda SongIndex,x
	sta SectionPtr+1
	
SetNewSongPtrs 				; if the routine is called from this label, it will use the current parameters instead 
	ldy #0 
	is_looping equ *-1 
	lda $FFFF,y
	SectionPtr equ *-2 
	bpl SetNewSongPtrs_b
	cmp #$FF
	bne SetNewSongPtrs_a
	jmp stop_toggle

SetNewSongPtrs_a
	and #$7F
	sta is_looping
	ldx #0
	loop_count equ *-1 
	bmi SetNewSongPtrs
	inx 
	stx loop_count
	cpx #2
	bne SetNewSongPtrs
	jsr trigger_fade_immediate
	jmp SetNewSongPtrs

SetNewSongPtrs_b	
	asl @
	tax
	ldy #0
	
SetNewSongPtrs_c
	lda $FFFF,x
	SongPtr equ *-2
	sta LZS.SongStartPtr,y
	inx
	iny
	cpy #4
	bcc SetNewSongPtrs_c
	inc is_looping 

SetNewSongPtrsDone
	lda #0
	sta LZS.Initialized		; reset the state of the LZSS driver to not initialised so it can play the next tune or loop 
	rts 	

;-----------------

;* Volume fadeout subroutine

fade_volume_loop 
	lda #0			; fadeing out timer and flag
	is_fadeing_out equ *-1 
	beq fade_volume_done	; equal 0 means it is not set, and must be skipped
	bpl continue_fadeout	; above 0 means it is already set, skip initialising again 
begin_fadeout			; below 0 means it is set, and must be initialised first 
	lda #1			; unit of volume to subtract
	sta is_fadeing_out	; flag and initial fade volume set
	lda v_second		; current second
	sta last_second_seen	; initialise the timer for fadeout
continue_fadeout	
	ldy #7			; index from the 4th AUDC 
fade_volume_loop_a
	lda SDWPOK0,y		; current POKEY buffer
	bufffade1 equ *-2
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
	bufffade2 equ *-2
	:2 dey			; decrement twice to only load the AUDC
	bpl fade_volume_loop_a	; continue this loop until Y overflows to $FF 
	lda v_second		; current second count
	cmp #0			; compare to the last second loaded 
	last_second_seen equ *-1
	bne fade_increment
fade_volume_done
	rts
fade_increment
	sta last_second_seen
	inc is_fadeing_out	; increment the fadeout value to subtract by 1 
	lda is_fadeing_out	; load that value for the comparison 
	cmp #11			; 10 seconds must have passed to reach 10 units
	bcc fade_volume_done	; if the value is below the count, done 

;-----------------

;* Toggle Stop, similar to pause, except Play will restart the tune from the beginning
;* The routine will continue into the following subroutines, a RTS will be found at the end of setpokeyfull further below 

stop_toggle 
	lda is_playing_flag 
	bpl set_stop			; the Stop flag will be set, regardless of Playing or being Paused 
	rts				; otherwise, the player is stopped already 
set_stop
	lda #$FF
	sta is_playing_flag		; #$FF -> Stop
	jsr SetNewSongPtrsFull 		; TODO: fix the index code, the tune won't restart properly  
	jsr reset_timer 		; clear the timer, unlike PAUSE, which would freeze the values until it is unpaused
	
;-----------------

;* Stop/Pause the player and reset the POKEY registers, a RTS will be found at the end of setpokeyfull further below 

stop_pause_reset
	lda #0			; default values
	ldy #8
stop_pause_reset_a 
	sta SDWPOK0,y		; clear the POKEY values in memory 
	sta SDWPOK1,y		; write to both POKEYs even if there is no Stereo setup, that won't harm anything
	dey 
	bpl stop_pause_reset_a	; repeat until all channels were cleared 

;----------------- 

;* Setpokey, intended for double buffering the decompressed LZSS bytes as fast as possible for timing and cosmetic purpose

setpokeyfull
	lda POKSKC0 
	sta $D20F 
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

;* 0 == Mono, FF == Stereo, 1 == Dual Mono (only SwapBuffer is necessary for it) 

	lda #STEREO
	is_stereo_flag equ *-1
	bne setpokeyfullstereo
	rts

setpokeyfullstereo
	lda POKSKC1 
	sta $D21F 
	ldy POKCTL1
	lda POKF4
	ldx POKC4
	sta $D210
	stx $D211
	lda POKF5
	ldx POKC5
	sta $D212
	stx $D213
	lda POKF6
	ldx POKC6
	sta $D214
	stx $D215
	lda POKF7
	ldx POKC7
	sta $D216
	stx $D217
	sty $D218
	rts

;-----------------

; Toggle Play/Pause 

play_pause_toggle 
	lda #0
	is_playing_flag equ *-1 	; #0 -> Play, #1 -> Pause, #$FF -> Stop 
	beq set_pause	
set_play 
	lda #0				; reset the Play flag, regardless of being Paused or Stopped  
	sta is_playing_flag		; #0 -> Play
	sta is_fadeing_out		; reset the fadeing out flag, in case it was set before pausing 
	rts
set_pause 
	inc is_playing_flag		; #0 -> #1 -> Pause 
	jmp stop_pause_reset		; clear the POKEY registers, end with a RTS
	
;-----------------

;* This routine provides the ability to initialise a fadeout for anything that may require a transition in a game/demo 
;* At the end of the routine, the is_playing flag will be set to a 'stop', which will indicate the fadeout has been completed
;* If a new tune index is loaded during a fadeout, it will be interrupted, and play the next tune like normal instead 
	
trigger_fade_immediate 
	lda is_playing_flag	; is the player currently in 'play' mode? 
	bne trigger_fade_done	; if not, skip this subroutine, there is nothing to fadeout 
	lda is_fadeing_out	; is the tune currently playing already engaged in a fadeout?
	bne trigger_fade_done	; if not 0, there is a fadeout in progress! skip this subroutine
	dec is_fadeing_out	; $00 -> $FF, the fadeout flag is set
trigger_fade_done
	rts 
	
;-----------------

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

; Check the Volume Only bit in CH1, if set but below the $Fx range, it's used, else, it's proper Volume Only output

CheckForTwoToneBit		
	ldy #1
	ldx SDWPOK0,y		; AUDC1
	bufftwo equ *-2
	cpx #$F0		; is the tune expected to run with Proper Volume Only output?
	bcs NoTwoTone		; if equal or above, this is not used for Two-Tone, don't set it
	txa
	and #$10		; test the Volume Only bit
	beq NoTwoTone		; if it is not set, there is no Two-Tone Filter active
	txa
	eor #$10		; reverse the Volume Only bit
	sta SDWPOK0,y		; overwrite the AUDC
	bufftone equ *-2
	lda #$8B		; set the Two-Tone Filter output
	bne SetTwoTone		; unconditional 
NoTwoTone
	lda #3			; default SKCTL register state
SetTwoTone
	ldy #9
	sta SDWPOK0,y		; overwrite the buffered SKCTL byte with the new value
	buffbit equ *-2
	rts

;-----------------

;* Swap POKEY buffers for Stereo Playback
;* This is a really dumb hack that shouldn't harm the LZSS driver if everything works as expected... 

SwapBuffer
	lda #<SDWPOK1
	cmp #<SDWPOK0
	buffset equ *-1
	bne SwapBufferSet
SwapBufferReset
	lda #<SDWPOK0
SwapBufferSet
	sta buffset
	sta buffstore
	sta bufffade1 
	sta bufffade2 
	sta bufftwo
	sta bufftone
	sta buffbit
SwapBufferDone
	rts
	
SwapBufferCopy
	ldy #9
SwapBufferLoop
	lda SDWPOK0,y
	sta SDWPOK1,y
	dey
	bpl SwapBufferLoop
	rts

;-----------------

;* Left POKEY

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
POKSKC0	dta $03	

;* Right POKEY

SDWPOK1	
POKF4	dta $00
POKC4	dta $00
POKF5	dta $00
POKC5	dta $00
POKF6	dta $00
POKC6	dta $00
POKF7	dta $00
POKC7	dta $00
POKCTL1	dta $00
POKSKC1	dta $03

;-----------------

;//---------------------------------------------------------------------------------------------

;* To be able to use all the subroutines, include lzssp.asm in the project that may use the driver, 
;* Alternatively, include the code directly below  
;* The ORG addresses could be changed or even omitted if necessary! 
	
	.align $400
FONT
	ins "font.fnt"
VUDATA
	icl "VUData.asm"
VUPLAYER
	icl "VUPlayer.asm"
	run VUPLAYER		; set run address to VUPlayer in this case

;-----------------

;//---------------------------------------------------------------------------------------------

;* Songs index and data will be inserted here, after everything else, that way they are easy to modify externally

	icl "SongIndex.asm" 
	
;-----------------

;//---------------------------------------------------------------------------------------------


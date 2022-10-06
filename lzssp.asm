;* Assemble from this file!
;* Include everything needed below

	OPT R- F-
	icl "atari.def"
		
BUILD_VUPLAYER	equ 1			; Build the full VUPlayer, else it will be excluded, useful for including the driver in different projects
LZSS_SAP	equ 0			; Build the driver with SAP format in mind

;//---------------------------------------------------------------------------------------------

ZEROPAGE	equ $0000		; Zeropage
DRIVER		equ $1000		; Unrolled LZSS driver by rensoupp

	IFT BUILD_VUPLAYER
VUPLAYER	equ $2000		; VUPlayer by VinsCool
FONT    	equ $2800       	; Custom font 
VUDATA 		equ $2C00		; Text and data used by VUPlayer
	EIF
	
SONGINDEX	equ $3000		; Songs index, alligned memory for easier insertion from RMT
SAPINDEX	equ $3080		; Allows running from SAP Type B container	
SONGDATA	equ $3100		; Songs data, alligned memory for easier insertion from RMT

;//---------------------------------------------------------------------------------------------

	ORG ZEROPAGE
.PAGES 1
	icl "lzsspZP.asm"
.ENDPG

;//---------------------------------------------------------------------------------------------

;* The unrolled LZSS driver + Buffer will be inserted here first

	org DRIVER
	icl "playlzs16u.asm"
                
;* Several subroutines added for VUPlayer have been split to become part of the driver itself, allowing new features for future projects easily!

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

	lda is_stereo_flag	; is it a Stereo setup?
	beq fade_volume_mono	; 0 == Mono
	ldy #7			; index from the 4th AUDC (Right POKEY)
	
fade_volume_loop_b
	lda SDWPOK1,y		; current POKEY buffer
	tax			; backup for the next step
	and #$0F		; keep only the volume values
	sec			; set carry for the subtraction
	sbc is_fadeing_out	; subtract the fading value directly
	beq volume_loop_again_a	; if value = 0, write that value directly
	bpl set_new_volume_a	; else if the subtraction did not overflow, continue with the next step
	lda #0			; else, set the volume to 0 
	beq volume_loop_again_a	; unconditional 
set_new_volume_a	
	sta ora_volume_a	; this value will be used for the ORA instruction 
	txa			; get back the AUDC value loaded a moment before
	and #$F0		; only keep the Distortion bits
	ora #0			; combine the new volume to it
	ora_volume_a equ *-1
volume_loop_again_a
	sta SDWPOK1,y		; write the new AUDC value in memory for later
	:2 dey			; decrement twice to only load the AUDC
	bpl fade_volume_loop_b	; continue this loop until Y overflows to $FF

fade_volume_mono
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
	IFT BUILD_VUPLAYER
	jmp do_stop_toggle	; else, stop the player once the end of the fadeout is reached, and update the display accordingly
	ELS
	jmp stop_toggle		; else, stop the player once the end of the fadeout is reached	
	EIF
fade_volume_play	
	jmp seek_forward	; end the song prematurely, and seek the next subtune as soon as this is reached!
fade_volume_done
	rts

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
	stx stop_on_fade_end
SetNewSongPtrsLoopsOnly
	lda #4
	sta is_looping 
SetNewSongPtrs
	IFT BUILD_VUPLAYER
	ldx SongIdx				; current song index
	ELS
	ldx #0
	SongIdx equ *-1
	EIF
	cpx #SongsIndexEnd-SongsIndexStart 
	SongTotal equ *-1		
	bcc SetNewSongPtrs_a			; continue, index is in the valid range
	beq test_boundaries			; if index is equal to total, make sure it was from previously being set!
;	bcs SetNewSongPtrsFull			; else, it overshot, and must wrap around!
test_boundaries 
	lda is_looping				; is the loop flag set? if it is not, there is a wrap around to do!	
	cmp #4					; 2 and below -> all good, 4 or above -> pointers are about to be set, bad!
	bcc SetNewSongPtrs_a
;	bcs SetNewSongPtrsFull
test_boundaries_a
	lda is_fadeing_out			; in case it was fadeing out but also reached the end of index...
	beq SetNewSongPtrsFull			; if not fadeing out, do not take a chance, wrap around
	bne SetNewSongPtrs_c			; else, catch whatever remains in that bit of code, it's 8:32 am and I most likely broke even more stuff now
	

SetNewSongPtrs_a
	dec is_looping				; must start at 4!
	lda #4					; is the 'loop' flag set?
	is_looping equ *-1
;	bmi SetNewSongPtrsFull			;* if this happens, you did something wrong, Vin!
	bmi DontSet				; of course I did something wrong, broke tunes looping before fade finished
	beq trigger_fade			; loop already set
	cmp #1
	beq DontSet				; looping, so no need to update pointers
	cmp #2
	beq iliketosingaloopy			; load the loop subtune pointers 
SetNewSongPtrs_b
	lda is_fadeing_out			; if it's too early to load a new subtune! A dummy was most likely detected!
	beq SetNewSongPtrs_e			; if not fadeing out, carry on
SetNewSongPtrs_c
	lda stop_on_fade_end			; is the tune intended to stop?
	bpl SetNewSongPtrs_d			; if no, override the subtune for the next one, and interrupt the fadeout
	lda #11					; else, load this number because 12 is nice
	sta is_fadeing_out			; then set the timer further immediately to end it!
	bne SetNewSongPtrs_e			; unconditional, since the tune should end anyway, no harm done here
SetNewSongPtrs_d
	lda #0
	sta is_fadeing_out			; interrupt the fadeout, the next tune should then load like normal
SetNewSongPtrs_e	
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
	sty stop_on_fade_end		; reset this flag once Stop has been set, this must be manually set!
	dec SongIdx			; decrement the index position from LZSSP only once, essentially resetting the subtune 
	jsr SetNewSongPtrsLoopsOnly	; update the pointers and also reset the play/loop count in the process
	jsr reset_timer 		; clear the timer in STOP mode, unlike PAUSE, which would simply freeze the value until it is unpaused
	rts
	
;-----------------

; toggle Play/Pause mode
;* TODO: make this a proper subroutine

play_pause_toggle 
	lda #0
	is_playing_flag equ *-1 
	beq set_pause			; 0 -> currently playing, else, it was either paused or stopped 
set_play 
	ldx #0				; will set the play flag to 0, and also the offset for the PLAY characters 
	stx is_playing_flag
	beq play_pause_toggle_done
set_pause 
	dec is_playing_flag		; 00 -> FF
	jsr stop_pause_mute		; pause the player and clear the AUDC registers 
play_pause_toggle_done
	rts
	
;-----------------

; seek forward and reverse, both use the initialised flag + the new song pointers subroutine to perform it quickly
; reverse will land in the forward code, due to the way the song pointers are initialised, forward doesn't even need to increment the index!

seek_wraparound
	IFT BUILD_VUPLAYER
	ldx total_subtune		; the total number is also offset by 1
	ELS
	ldx SongTotal			; the total number is also offset by 1 
	EIF
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

; pause the player and reset the registers

stop_pause_reset
	lda #0			; default values
	ldy #8
stop_pause_reset_a 
	sta SDWPOK0,y		; clear the POKEY values in memory
	sta SDWPOK1,y
	dey 
	bpl stop_pause_reset_a	; repeat until all channels were cleared 
	jsr setpokeyfull	; overwrite the actual registers
	rts

;----------------- 

; mute the channels but do not overwrite the AUDF or AUDCTL so the contents gets re-used as soon as it's playing 

stop_pause_mute
	lda #0			; default values
	ldy #7			; begin on the last channel's AUDC
stop_pause_mute_a 
	sta SDWPOK0,y		; clear the AUDC values ONLY
	sta SDWPOK1,y
	:2 dey 			; DEY twice to avoid the AUDF values
	bpl stop_pause_mute_a	; repeat until all channels were cleared 
	jsr setpokeyfull	; overwrite the actual registers
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
	ldy #3			; default SKCTL register state
	ldx POKC0		; AUDC1
	cpx #$F0		; is the tune expected to run with Proper Volume Only output?
	bcs NoTwoTone		; if equal or above, this is not used for Two-Tone, don't set it
	txa
	and #$10		; test the Volume Only bit
	beq NoTwoTone		; if it is not set, there is no Two-Tone Filter active
	txa
	eor #$10		; reverse the Volume Only bit
	sta POKC0		; overwrite the AUDC
	ldy #$8B		; set the Two-Tone Filter output
NoTwoTone
	sty POKSKC0		; overwrite the buffered SKCTL byte with the new value
	rts

;-----------------

; fast setpokey variant, intended for double buffering the decompressed LZSS bytes as fast as possible for timing and cosmetic purpose

SDWPOK0			;* Left POKEY
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

SDWPOK1			;* Right POKEY
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

;* Left POKEY is used by default, unless a Stereo setup is used, which will also write bytes to the Right POKEY 

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
	
	lda #STEREO			; 0 == Mono, FF == Stereo, 1 == Dual Mono (only SwapBuffer is necessary for it) 
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

;* Swap POKEY buffers for Stereo Playback, this is a really dumb hack but that saves the troubles of touching the unrolled LZSS driver's code

SwapBuffer
	ldy #9
SwapBufferLoop
	lda SDWPOK0,y
	sta SDWPOK1,y
	dey
	bpl SwapBufferLoop
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

;//---------------------------------------------------------------------------------------------
                
;* VUPlayer will now be inserted here, and be the main program running, calling the LZSS driver when needed

	IFT BUILD_VUPLAYER
	org VUPLAYER
	icl "VUPlayer.asm"
	org FONT
	ins "font.fnt"
	org VUDATA
	icl "VUData.asm"
	run start		; set run address to VUPlayer in this case
	ELS

;* example initialisation code for using this driver version, these steps may not have to be in this exact order but this is recommended for best results
	
	org $2000

SongSpeed 	equ 1
VLINE		equ 16

start
	jsr stop_pause_reset	; clear the POKEY registers first
	jsr SetNewSongPtrsFull	; initialise the LZSS driver with the song pointer using default values always 
	ldy #0
	ldx #60
	sty v_second		; Y is 0, reset the timer with it
	sty v_minute	
	stx framecount		; X is either 50 or 60, defined by the region initialisation
	stx v_frame		; also initialise the actual frame counter with this value
	dey
	sty stop_on_fade_end 	; once a fadeout is forced -> stop
	sty loop_toggle		; but a loop is also infinitely set! how does one escape from this trap? :3c See further below!
	
	lda #4
	sta SongIdx
	jsr SetNewSongPtrsLoopsOnly
wait_sync
	lda VCOUNT		; current scanline 
	cmp #VLINE		; will stabilise the timing if equal
	bcc wait_sync		; nope, repeat
loop

;* main loop, code runs from here ad infinitum after initialisation, most of this was copied from VUPlayer and stripped down to a bare minimum for example purpose

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
	
check_play_flag	
	lda is_playing_flag 		; 0 -> is playing, else it is either stopped or paused, and must not run for this frame
	bne loop			; otherwise, the player is either paused or stopped, in this case, nothing will happen until it is changed back to 0	
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
	jsr calculate_time		; needed for calculating the fadeout, and if a project needs a timer, well it could also be used if needed!

;	lda stop_on_fade_end
;	bmi loop
;	rts

	lda is_playing_flag
	beq loop_again
	rts
	
loop_again
	lda v_minute
	cmp #$1				; force a fadeout after exactly 1 minute
	bcc loop
	
	jsr trigger_fade_immediate	; engage a forced fadeout once the condition is met!
	
	jmp loop			; infinitely...? ;) 
	
	run start			; set run address to anything that is wanted here in this case, or comment this line out if it is set elsewhere
	EIF
	
;* Else, insert all the relevant code here, or include lzssp.asm in the project that may use it

;//---------------------------------------------------------------------------------------------

;* Songs index and data will be inserted here, after everything else, that way they are easy to modify externally

		org SONGINDEX	
		icl "SongIndex.asm"
		
		IFT LZSS_SAP
		org SAPINDEX
		icl "LZSS_SAP.asm"
		EIF
		
		org SONGDATA 
		icl "SongData.asm"

;//---------------------------------------------------------------------------------------------


;* Arrrgh, this will be fun! lol
;*

;* ----------------------------------------------------------------------------

;* So here it begins, yet another time, woohooo!!!

.proc LZSSPlayFrame
	ldx #8
	lda ZPLZS.SongStereo
	seq:ldx #17
	mva #>BUFFERS ZPLZS.ChannelBuffer+1
	ldy ZPLZS.BufferStatus
	beq LZSSPlayFrameBegin
	
LZSSInitialise:
	sty ZPLZS.ChannelBuffer+0
	iny
	sty ZPLZS.ChannelOffset
	sty ZPLZS.BufferStatus
	lda ZPLZS.BufferStart+0
	clc
	adc #3
	sta ZPLZS.BufferPointer+0
	lda ZPLZS.BufferStart+1
	adc #0
	sta ZPLZS.BufferPointer+1
	
LZSSInitialiseLoop:
	mva (ZPLZS.BufferPointer),y (ZPLZS.ChannelBuffer),y
	sta SDWPOK,x
	sty ZPLZS.ByteCount,x
	inc ZPLZS.BufferPointer+0
	sne:inc ZPLZS.BufferPointer+1
	inc ZPLZS.ChannelBuffer+1
	dex
	bpl LZSSInitialiseLoop
	sty ZPLZS.ChannelBuffer+0
	iny
	sty ZPLZS.BufferBitByte
	rts
	
LZSSPlayFrameBegin:
	sty ZPLZS.BufferOffset
	ldy #2
	
LZSSPlayFrameBegin_a:
	lda (ZPLZS.BufferStart),y
	sta ZPLZS.ChannelBitByte,y
	dey
	bpl LZSSPlayFrameBegin_a
	
LZSSPlayFrameContinue:
	lsr ZPLZS.ChannelBitByte+2
	ror ZPLZS.ChannelBitByte+1
	ror ZPLZS.ChannelBitByte+0
	bcc LZSSPlayFrameReadByte
	
LZSSPlayFrameSkipByte:
	ldy ZPLZS.ChannelOffset
	dey
	lda (ZPLZS.ChannelBuffer),y
	bcs LZSSPlayFrameWriteByte
	
LZSSPlayFrameReadByte:
	lda ZPLZS.ByteCount,x
	bne LZSSPlayFrameCopyByte
	lsr ZPLZS.BufferBitByte
	bne LZSSPlayFrameGetByte
	ldy ZPLZS.BufferOffset
	inc ZPLZS.BufferOffset
	lda (ZPLZS.BufferPointer),y
	ror @
	sta ZPLZS.BufferBitByte
	
LZSSPlayFrameGetByte:
	ldy ZPLZS.BufferOffset
	inc ZPLZS.BufferOffset
	lda (ZPLZS.BufferPointer),y
	bcs LZSSPlayFrameWriteByte
	sta ZPLZS.LastOffset,x
	ldy ZPLZS.BufferOffset
	inc ZPLZS.BufferOffset
	lda (ZPLZS.BufferPointer),y
	sta ZPLZS.ByteCount,x
	
LZSSPlayFrameCopyByte:
	inc ZPLZS.LastOffset,x
	ldy ZPLZS.LastOffset,x
	lda (ZPLZS.ChannelBuffer),y
	dec ZPLZS.ByteCount,x
	
LZSSPlayFrameWriteByte:
	ldy ZPLZS.ChannelOffset
	sta (ZPLZS.ChannelBuffer),y
	sta SDWPOK,x
	
LZSSPlayFrameNext:
	inc ZPLZS.ChannelBuffer+1
	dex
	bpl LZSSPlayFrameContinue
	
LZSSUpdate:
	inc ZPLZS.ChannelOffset
	lda ZPLZS.BufferPointer+0
	clc
	adc ZPLZS.BufferOffset
	sta ZPLZS.BufferPointer+0
	scc:inc ZPLZS.BufferPointer+1
	lda ZPLZS.BufferPointer+1
	cmp ZPLZS.BufferEnd+1
	bcc LZSSUpdateDone
	lda ZPLZS.BufferPointer+0
	cmp ZPLZS.BufferEnd+0
	bcs SetNewSongPtrs
	
LZSSUpdateDone:
	rts
.endp

;* ----------------------------------------------------------------------------

;* Song index initialisation subroutine, load pointers using index number, as well as loop point when it exists
;* If the routine is called from this label, index and loop are restarted

SetNewSongPtrsFull:
	lda ZPLZS.SongIndex		; Current song index
	asl @
	tax
	mwa LZDATA+6,x ZPLZS.SongPointer
	ldy #0				; Reset player variables
	lda (ZPLZS.SongPointer),y
	sty ZPLZS.SongStereo
	lsr @
	rol ZPLZS.SongStereo
	sty ZPLZS.AdjustSpeed
	lsr @
	ror ZPLZS.AdjustSpeed		; I honestly forgot why I added this parameter but whatever
	sty ZPLZS.SongRegion
	lsr @
	rol ZPLZS.SongRegion
	sta ZPLZS.SongSpeed		; 2 Unused Bits remain, but it's safe to assume no invalid data will be used
	sty ZPLZS.FadingOut
	sty ZPLZS.StopOnFadeout
	sty ZPLZS.SongSequence
	sty ZPLZS.LoopCount
	sty ZPLZS.ProgramStatus
	sty bar_counter+0
	sty bar_counter+1
	sty bar_counter+2
	iny
	mwa (ZPLZS.SongPointer),y bar_increment+0
	iny
	mwa (ZPLZS.SongPointer),y bar_increment+2
	iny
	tya
	adc ZPLZS.SongPointer+0		; Carry guaranteed to be Clear from Bitwise Operations
	sta ZPLZS.SongPointer+0
	scc:inc ZPLZS.SongPointer+1
	
;* If the routine is called from this label, it will use the current parameters instead

SetNewSongPtrs:
	ldy ZPLZS.SongSequence
	lda (ZPLZS.SongPointer),y
	bpl SetNewSongPtrs_c
	cmp #$FF
	bne SetNewSongPtrs_b
	bit ZPLZS.LoopCount
	bpl SetNewSongPtrs_a
	lda #0
	sta ZPLZS.SongSequence
	beq SetNewSongPtrs
	
SetNewSongPtrs_a:
	lda #$F0
	sta ZPLZS.FadingOut		; Force instant Song End
	bmi SetNewSongPtrsDone
	
SetNewSongPtrs_b:
	and #$7F
	sta ZPLZS.SongSequence
	lda bar_loop			; Set the Progress bar position at the start of the Loop Point
	sta bar_counter			; So it will match visually during playback
	ldx ZPLZS.LoopCount		; How many times the End of a Sequence was reached so far?
	bmi SetNewSongPtrs		; Bit 7 set -> Infinitely looping, resume playback from the Loop Point
	inx				; Increment the Loop Counter
	stx ZPLZS.LoopCount		; The update the value in memory
	cpx #2				; Has it been looping at least once?
	bcc SetNewSongPtrs		; If not, resume playback from the Loop Point
	jsr trigger_fade_immediate	; Initialise fadeout sequence for the remainder of playback time
	bmi SetNewSongPtrs		; Guaranteed to return with the Negative Flag set
	
SetNewSongPtrs_c:
	sta ZPLZS.SongSection		; Actually useless, this is just a value to Display for debugging purposes
	asl @
	tay
	mwa LZDATA+4 ZPLZS.TMP0
	mwa (ZPLZS.TMP0),y ZPLZS.BufferStart
	iny
	mwa (ZPLZS.TMP0),y ZPLZS.BufferEnd
	mva #$FF ZPLZS.BufferStatus
	inc ZPLZS.SongSequence
SetNewSongPtrsDone:
	rts
	
;-----------------

;* Volume Fadeout Subroutine

.proc UpdateVolumeFadeout
	bit ZPLZS.FadingOut
	bpl UpdateVolumeFadeoutDone
	lda ZPLZS.Frames
	sne:dec ZPLZS.FadingOut
	lda ZPLZS.FadingOut
	cmp #$F5
	bcs UpdateVolumeFadeoutDone
	jsr set_stop
	
UpdateVolumeFadeoutDone:
	rts
.endp

;-----------------

;* Toggle Stop, similar to pause, except Play will restart the tune from the beginning
;* The routine will continue into the following subroutines, a RTS will be found at the end of setpokeyfull further below 

stop_toggle 
	bit ZPLZS.PlayerStatus		; What is the current Player state?
	bpl set_stop			; The Stop flag will be set, regardless of Playing or being Paused
	rts				; Otherwise, the player is Stopped already, no further action needed
set_stop
	lda #%10000000			; Bit 7 set -> Stop Flag
	sta ZPLZS.PlayerStatus		; Update the Player state
	dec ZPLZS.ProgramStatus		; Force a Reset within Main Loop
	rts

;-----------------

;* Stop/Pause the player and reset the POKEY registers, a RTS will be found at the end of setpokeyfull further below 

stop_pause_reset
	lda #3				; Default SKCTL value, needed for handling Keyboard
	sta POKSKC+0
	sta POKSKC+1
	lda #0				; Default POKEY values
	ldx #8				; 4xAUDF + 4xAUDC + 1xAUDCTL
stop_pause_reset_a 
	sta SDWPOK0,x			; Clear all POKEY values in memory 
	sta SDWPOK1,x			; Write to both POKEYs even if there is no Stereo setup, that won't harm anything
	dex
	bpl stop_pause_reset_a		; Repeat until all channels were cleared
	rts

;----------------- 

;* Setpokey, intended for double buffering the decompressed LZSS bytes as fast as possible for timing and cosmetic purpose

setpokeyfull
	lda POKSKC+0
	sta $D20F 
	ldy SDWPOK0.POKCTL
	lda SDWPOK0.POKF0
	ldx SDWPOK0.POKC0
	sta $D200
	stx $D201
	lda SDWPOK0.POKF1
	ldx SDWPOK0.POKC1
	sta $D202
	stx $D203
	lda SDWPOK0.POKF2
	ldx SDWPOK0.POKC2
	sta $D204
	stx $D205
	lda SDWPOK0.POKF3
	ldx SDWPOK0.POKC3
	sta $D206
	stx $D207
	sty $D208
	lda ZPLZS.MachineStereo
	beq setpokeyfulldone
	
setpokeyfullstereo
	lda POKSKC+1
	sta $D21F 
	ldy SDWPOK1.POKCTL
	lda SDWPOK1.POKF0
	ldx SDWPOK1.POKC0
	sta $D210
	stx $D211
	lda SDWPOK1.POKF1
	ldx SDWPOK1.POKC1
	sta $D212
	stx $D213
	lda SDWPOK1.POKF2
	ldx SDWPOK1.POKC2
	sta $D214
	stx $D215
	lda SDWPOK1.POKF3
	ldx SDWPOK1.POKC3
	sta $D216
	stx $D217
	sty $D218
	
setpokeyfulldone
	rts

;-----------------

;* Toggle Play/Pause, and mute all channels, but do not overwrite the AUDF or AUDCTL registers, so they can be used right back
;* Otherwise, as soon as it's set back to Play from Pause, some junk data might stick in memory, and wouldn't be properly updated
;* It turns out, the idea from a few months ago actually worked well enough to counter this situation, so let's just use it again
;* TODO: Use Mute Volume Mask on all channels when the Pause Flag is set instead of this gross workaround

play_pause_toggle
	bit ZPLZS.PlayerStatus		; What is the current Player state?
	bmi set_play_from_a_stop	; Stopped -> Switch state to Play from a Stop
	bvs set_play			; Paused -> Switch state to Play from a Pause

set_pause
	lda #%01000000			; Bit 6 set -> Pause Flag
	sta ZPLZS.PlayerStatus		; Update the Player state
	rts
	
set_play_from_a_stop
	ldx #$01
	
set_play_from_a_stop_a
	stx $D201
	stx $D211
	stx $D203
	stx $D213
	stx $D205
	stx $D215
	stx $D207
	stx $D217
	stx $D209
	stx $D219
	dex
	bmi set_play_from_a_stop_b
	stx $D208
	stx $D218
	stx $D20F
	stx $D21F
	beq set_play_from_a_stop_a
	
set_play_from_a_stop_b
	dec ZPLZS.ProgramStatus		; Force a Reset within Main Loop
	
set_play
	lda #%00000000			; Bit 6 and 7 clear -> Play Flag
	sta ZPLZS.PlayerStatus		; Update the Player state
	rts
	
;----------------- 

;* This routine provides the ability to initialise a fadeout for anything that may require a transition in a game/demo 
;* At the end of the routine, the is_playing flag will be set to a 'stop', which will indicate the fadeout has been completed
;* If a new tune index is loaded during a fadeout, it will be interrupted, and play the next tune like normal instead 

trigger_fade_immediate
	bit ZPLZS.FadingOut		; Is the tune currently playing already engaged in a fadeout?
	bmi trigger_fade_done		; If there is a fadeout in progress, skip this subroutine!
	dec ZPLZS.FadingOut		; $00 -> $FF, the fadeout flag is set
trigger_fade_done
	rts
	
;-----------------

.proc CalculateTime
	inc ZPLZS.Frames		; Increment Frames
	lda ZPLZS.Frames
	cmp #50				; Did a Second pass yet?
	bcc CalculateTimeDone		; If not, there is nothing else to do
	lda #0
	sta ZPLZS.Frames		; Reset the Frames counter
	inc ZPLZS.Seconds		; Increment Seconds
	lda ZPLZS.Seconds
	cmp #60				; Did at least 60 seconds pass yet?
	bcc CalculateTimeDone		; If not, there is nothing else to do
	lda #0
	sta ZPLZS.Seconds		; Reset the Seconds counter
	inc ZPLZS.Minutes		; Increment Minutes, uncapped since it is very unlikely to be maxed out

CalculateTimeDone:
	rts
.endp

;-----------------

.proc ResetTimer
	lda #0
	sta ZPLZS.TimerOffset
	sta ZPLZS.Frames
	sta ZPLZS.Seconds
	sta ZPLZS.Minutes
	rts
.endp

;-----------------

;* Check if the Volume Only Bit is set in CH1 during playback
;* Below the $Fx range, it's a trigger for enabing Two-Tone Filter
;* Otherwise, it's proper Volume Only Output, and shouldn't be overridden

.proc CheckForTwoToneBit
CheckForTwoToneBitLeft:
	ldx #$03
	lda SDWPOK0.POKC0
	cmp #$F0
	bcs CheckForTwoToneBitLeft_a
	tay
	and #$10
	beq CheckForTwoToneBitLeft_a
	tya
	eor #$10
	sta SDWPOK0.POKC0
	ldx #$8B
	
CheckForTwoToneBitLeft_a:
	stx POKSKC+0
	
CheckForTwoToneBitRight:
	lda ZPLZS.MachineStereo
	beq CheckForTwoToneBitDone
	ldx #$03
	lda SDWPOK1.POKC0
	cmp #$F0
	bcs CheckForTwoToneBitRight_a
	tay
	and #$10
	beq CheckForTwoToneBitRight_a
	tya
	eor #$10
	sta SDWPOK1.POKC0
	ldx #$8B
	
CheckForTwoToneBitRight_a:
	stx POKSKC+1
	
CheckForTwoToneBitDone:
	rts
.endp

;-----------------

;* Swap POKEY buffers for Stereo Playback in Dual Mono

.proc SwapBufferCopy
	lda ZPLZS.MachineStereo
	beq SwapBufferCopyDone
	cmp ZPLZS.SongStereo
	beq SwapBufferCopyDone
	ldx #8
	lda POKSKC+0
	sta POKSKC+1
	
SwapBufferCopyLoop:
	lda SDWPOK0,x
	sta SDWPOK1,x
	dex
	bpl SwapBufferCopyLoop

SwapBufferCopyDone:
	rts
.endp

;-----------------

;* Set Volume Level in all POKEY channels, combined with Fadeout effect
;* Mute all POKEY channels with the Volume Mask toggle bit active

.proc SetVolumeLevel
	lda ZPLZS.VolumeMask
	sta ZPLZS.TMP1
	
SetVolumeLevelLeft:
	ldx #7
	ldy #3
	
SetVolumeLevelLeftLoop:
	asl ZPLZS.TMP1
	lda SDWPOK0,x
	and #$0F
	beq SetVolumeLevelLeftLoop_c
	bcs SetVolumeLevelLeftLoop_a
	adc ZPLZS.VolumeLevel+0,y
	spl:lda #0
	cmp #$10
	scc:lda #$0F
	add ZPLZS.FadingOut
	bpl SetVolumeLevelLeftLoop_b
	
SetVolumeLevelLeftLoop_a:
	lda #0
	
SetVolumeLevelLeftLoop_b:
	sta ZPLZS.TMP0
	lda SDWPOK0,x
	and #$F0
	ora ZPLZS.TMP0
	sta SDWPOK0,x
	
SetVolumeLevelLeftLoop_c:
	dey
	:2 dex
	bpl SetVolumeLevelLeftLoop
	
SetVolumeLevelRight:
	lda ZPLZS.MachineStereo
	beq SetVolumeLevelDone
	ldx #7
	ldy #3
	
SetVolumeLevelRightLoop:
	asl ZPLZS.TMP1
	lda SDWPOK1,x
	and #$0F
	beq SetVolumeLevelRightLoop_c
	bcs SetVolumeLevelRightLoop_a
	adc ZPLZS.VolumeLevel+4,y
	spl:lda #0
	cmp #$10
	scc:lda #$0F
	add ZPLZS.FadingOut
	bpl SetVolumeLevelRightLoop_b
	
SetVolumeLevelRightLoop_a:
	lda #0
	
SetVolumeLevelRightLoop_b:
	sta ZPLZS.TMP0
	lda SDWPOK1,x
	and #$F0
	ora ZPLZS.TMP0
	sta SDWPOK1,x
	
SetVolumeLevelRightLoop_c:
	dey
	:2 dex
	bpl SetVolumeLevelRightLoop
		
SetVolumeLevelDone:
	rts
.endp

;-----------------

;//---------------------------------------------------------------------------------------------

;* Detect the actual Machine Region in order to adjust Playback Speed among other things
;* PAL -> 0, NTSC -> 1

.proc DetectMachineRegion
	lda VCOUNT
	beq DetectMachineRegion_a
	tax
	bne DetectMachineRegion
	
DetectMachineRegion_a:
	sta ZPLZS.MachineRegion
	cpx #PAL_SCANLINE-1
	spl:inc ZPLZS.MachineRegion
	rts
.endp

;* ----------------------------------------------------------------------------

;* Detect second POKEY for Stereo Mode
;* Mono -> 0, Stereo -> 1

.proc DetectStereoMode
	ldx #$00
	stx $D20F
	stx $D21F
	ldy #$03
	sty $D21F
	:2 sta WSYNC
	lda #$FF
	
DetectStereoModeLoop:
	and RANDOM
	dex
	bne DetectStereoModeLoop
	stx ZPLZS.MachineStereo
	sty $D20F
	cmp #$FF
	sne:inc ZPLZS.MachineStereo
	
DetectStereoModeDone:
	rts
.endp

;* ----------------------------------------------------------------------------

.proc SetStereoMode
	lda #%00000000
	sta ZPLZS.VolumeMask
	lda ZPLZS.MachineStereo
	beq SetStereoModeDone
	cmp ZPLZS.SongStereo
	beq SetStereoModeDone
	lda #%01101001
	sta ZPLZS.VolumeMask
	
SetStereoModeDone:
	rts
.endp

;* ----------------------------------------------------------------------------


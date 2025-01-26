InitSAP:
	sta ZPLZS.SongIndex			; Set Song Index for the desired Subtune
	jsr DetectMachineRegion
	jsr DetectStereoMode
;	mwa SectionTable ZPLZS.SectionPointer
	jsr SetNewSongPtrsFull
	mva #%10000000 ZPLZS.LoopCount		; Set Loop Flag to Infinite
	jsr stop_pause_reset
	jsr setpokeyfull
	jsr SetStereoMode
	jsr SetPlaybackSpeed
	jsr WaitForVBlank
	jsr WaitForSync
PlaySAP:
	jsr WaitForScanline			; Wait until Playback is ready to process
	jsr setpokeyfull			; Update POKEY registers
	jsr LZSSPlayFrame			; Play 1 LZSS frame
;	scc:jsr SetNewSongPtrs			; Returning with Carry Flag Set -> Update Song Pointers
	jsr SwapBufferCopy			; Dual Mono -> Copy buffered values from Left POKEY to Right POKEY
	jsr SetVolumeLevel			; Apply Volume Level changes and Mute channels with the Volume Mask Bit Set
	jsr CheckForTwoToneBit			; Update SKCTL to use Two-Tone Filter if the Volume Only Bit from AUDC0 is Set
	jmp PlaySAP
	
;* Wait for VBlank manually, useful for situations in which NMIs are disabled
;* This might not be perfect but this should be good enough for most use cases

.proc WaitForVBlank
	lda VCOUNT		; Get Current Scanline / 2
	cmp #VBLANK_SCANLINE	; Is it time for VBlank yet?
	bne WaitForVBlank	; Not Equal -> Keep waiting
	rts
.endp

;* ----------------------------------------------------------------------------

;* Wait for a specific number of Frames, ranging from 1 and 256
;* Set the parameter in the X Register before calling this routine

.proc WaitForSomeTime
	:2 sta WSYNC		; Forcefully increment VCOUNT at least once
	jsr WaitForVBlank	; Wait until the end of the current Frame
	dex:bne WaitForSomeTime	; if (--X != 0) -> Keep waiting
	rts
.endp

;* ----------------------------------------------------------------------------

;* Wait until the Sync Scanline count is reached
;* Effectively the same as waiting for VBlank but with a different number of Scanlines

.proc WaitForSync
	lda VCOUNT		; Get Current Scanline / 2
	cmp #VLINE		; Is it time for Sync yet?
	bne WaitForSync		; Not Equal -> Keep waiting
	rts
.endp
	
;* ----------------------------------------------------------------------------

.proc WaitForScanline
	lda ZPLZS.SyncOffset
	asl ZPLZS.SyncStatus
	bcc WaitForScanlineSkip
	
WaitForScanlineContinue:
	lda VCOUNT
	tax
	sbc ZPLZS.LastCount
	scs:adc ZPLZS.SyncCount
	bcs WaitForScanlineNext
	adc #-1
	eor #-1
	adc ZPLZS.SyncOffset
	sta ZPLZS.SyncOffset
	lda #0
	
WaitForScanlineNext:
	sta ZPLZS.SyncDelta
	stx ZPLZS.LastCount
	lda ZPLZS.SyncOffset
	sbc ZPLZS.SyncDelta
	sta ZPLZS.SyncOffset
	bcs WaitForScanlineContinue
	
WaitForScanlineSkip:
	adc ZPLZS.SyncDivision
	sta ZPLZS.SyncOffset
	ror ZPLZS.SyncStatus
	
WaitForScanlineDone:
	rts
.endp
	
.proc SetPlaybackSpeed
	lda ZPLZS.MachineRegion
	bit ZPLZS.AdjustSpeed
	bpl SetPlaybackSpeed_b
	cmp ZPLZS.SongRegion
	beq SetPlaybackSpeed_b

SetPlaybackSpeed_a:
	clc
	adc #2
	
SetPlaybackSpeed_b:
	asl @
	asl @
	asl @
	adc ZPLZS.SongSpeed
	tay
	lda ScanlineDivisionTable,y
	sta ZPLZS.SyncDivision
	lda ScanlineCountTable,y
	sta ZPLZS.SyncCount
	
SetPlaybackSpeed_c:
	lda #VLINE
	sta ZPLZS.LastCount
	ldy #0
	sty ZPLZS.SyncOffset
	dey
	sty ZPLZS.SyncStatus
	rts
	
ScanlineDivisionTable:
DivPAL	.byte $9C,$4E,$34,$27,$1F,$1A,$16,$13
DivNTSC	.byte $83,$42,$2C,$21,$1A,$16,$13,$10
OffPAL	.byte $82,$41,$2D,$23,$1A,$14,$14,$0F
OffNTSC	.byte $9C,$4E,$34,$27,$1E,$1A,$18,$15

ScanlineCountTable:
NumPAL	.byte $9C,$9C,$9C,$9C,$9B,$9C,$9A,$98
NumNTSC	.byte $83,$84,$84,$84,$82,$84,$85,$80
FixPAL	.byte $9C,$9C,$A2,$A8,$9C,$90,$A8,$90
FixNTSC	.byte $82,$82,$82,$82,$7D,$82,$8C,$8C
.endp

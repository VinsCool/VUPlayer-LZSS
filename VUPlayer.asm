;************************************************;
;* VUPlayer, Version v3.0                       *;
;* by VinsCool, 2022-2025                       *;
;* This project branched from Simple RMT Player *;
;* And has then become its own thing...         *;
;************************************************;

;-----------------

;------------------------------------------------------------------------------------------------------------------------------------;

Start:

/*
	sei			; Set Interrupt Disable Status
	cld			; Clear Decimal Flag
	
;	jsr WaitForVBlank	; Too early, this will cause problems if it is executed before NMIEN is Reset in time!

	lda #%11111110		; Disable BASIC and OS ROMs, leaving almost all memory from $C000 to $FFFF available!	
	sta PORTB		; This will only work for extended XL memory, however
*/

	lda #0
	sta NMIEN
	sta IRQEN
	sta DMACTL

	tax
	sta.w:rne ZEROPAGE,x-	; Reset Zeropage Variables
	
	tsx
	stx ZPLZS.StackPointer	; Return Address from the Stack
	
	sta COLBK
	sta COLPF0
	sta COLPF2
	sta COLPF3
	lda #$0F
	sta COLPF1
	
;	ldx ZPLZS.MemBank
;	jsr BankSwitch
	
	jsr WaitForVBlank

	mva LZDATA+0 ZPLZS.SongIndex
	mva LZDATA+1 ZPLZS.SongCount
	mva LZDATA+2 ZPLZS.RasterbarToggle
	mva LZDATA+3 ZPLZS.RasterbarColour
	
	mva #2 ZPLZS.PlayerMenuIndex
	
	jsr WaitForVBlank
	jsr DetectMachineRegion
	jsr DetectStereoMode
	
	jsr WaitForVBlank
	jsr SetNewSongPtrsFull
	jsr stop_pause_reset
	jsr setpokeyfull
	jsr set_stop		; clear the POKEY registers, initialise the LZSS driver, and set VUPlayer to Stop
	jsr set_subtune_count	; update the subtunes position and total values
	jsr set_highlight
	jsr PrintSongInfos
	jsr WaitForVBlank
	
	lda ZPLZS.MachineRegion
	:2 asl @
	tax
	
	lda VUMeterColours+0,x
	sta ZPVOL.Colour+0	; Red
	lda VUMeterColours+1,x
	sta ZPVOL.Colour+1	; Yellow
	lda VUMeterColours+2,x
	sta ZPVOL.Colour+2	; Green
	lda VUMeterColours+3,x
	sta ZPVOL.Colour+3	; Gray
	
	jsr WaitForVBlank
	mwa #enemi NMI		; Set up our own Interrupt Vector Addresses
	mwa #dlist DLISTL	; Start Address of the Display List
	mva #%10000000 NMIEN	; Enable Display List Interrupts only for the Splash Screen gradient effect
	mva #>VUFONT CHBASE	; Load the font address into the shadow character register
	
	lda #$22		; DMA Enable, Normal Playfield
	sta ZPLZS.DMAToggle
	sta DMACTL		; Write to Direct Memory Access Control Address
	ldx #120		; Load into index x a 120 frames buffer
	jsr WaitForSomeTime
	mva #%11000000 NMIEN	; Enable Display List and VBlank Interrupts
	cli			; Clear Interrupt Disable Status
	
	jsr toggle_vumeter	; make sure this is also set properly before playing
	jsr set_play		; now is the good time to set VUPlayer to Play
	
ResetLoop:
	jsr SetNewSongPtrsFull
	jsr PrintSongInfos
	jsr ResetTimer
	
ResetLoop_a:
	jsr stop_pause_reset
	jsr setpokeyfull
	jsr SetPlaybackSpeed
	jsr WaitForVBlank
	jsr WaitForSync
	
/*
	ldx #0
	
ResetLoop_b:
	mva ZEROPAGE,x $C000,x
	dex
	bne ResetLoop_b
	nop
	mva #%11111111 PORTB
	nop
	mva #%11111110 PORTB
*/

;-----------------

;------------------------------------------------------------------------------------------------------------------------------------;

;* Main loop, code runs from here Ad Infinitum after initialisation

MainLoop:
	mva #0 COLBK				; Set Background colour to Black
	bit ZPLZS.ProgramStatus			; What is the current Program state?
	bmi ResetLoop				; Reset -> Playback may use new parameters and should be handled as such
	lda ZPLZS.PlayerStatus 			; What is the current Player state?
	bne ResetLoop_a				; Stopped or Paused -> Skip Playback
	jsr WaitForScanline			; Wait until Playback is ready to process
	bit ZPLZS.RasterbarToggle		; Is there a Rasterbar to display during playback?
	spl:mva ZPLZS.RasterbarColour COLBK	; Negative Flag Set -> Update Background colour
	jsr setpokeyfull			; Update POKEY registers
	jsr LZSSPlayFrame			; Play 1 LZSS frame
;	scc:jsr SetNewSongPtrs			; Returning with Carry Flag Set -> Update Song Pointers
	jsr SwapBufferCopy			; Dual Mono -> Copy buffered values from Left POKEY to Right POKEY
	jsr SetVolumeLevel			; Apply Volume Level changes and Mute channels with the Volume Mask Bit Set
	jsr CheckForTwoToneBit			; Update SKCTL to use Two-Tone Filter if the Volume Only Bit from AUDC0 is Set
	jmp MainLoop				; Infinitely
	
;-----------------

;------------------------------------------------------------------------------------------------------------------------------------;

;* VUMeter shading, from bottom to top, in this order

dlicoltbl
;	.byte $02, $04, $06, $08, $0A, $0C, $0C, $0E, $0C, $0C, $0A, $08, $06, $04, $02
	.byte $03, $05, $07, $09, $0B, $0D, $0D, $0E, $0D, $0C, $0A, $08, $06, $04, $02

;* Custom DLI and VBI vector, the NMI will jump here first, then branch according to NMIST bits

enemi
	pha
	txa
	pha
	tya
	pha
	bit NMIST
	jpl vbi			; Positive value from BIT -> VBI, otherwise, this is a DLI

;-----------------
	
;* DLI will run from here


deli
	bit vumeter_toggle
	jmi deli_d
	sta WSYNC
	lda #0
	sta COLBK
	sta COLPF0
	sta COLPF1
	sta COLPF2
	sta COLPF3
	sta WSYNC
	sta WSYNC
	
;	lda #$04
;	sta COLPF0
;	sta COLPF2
;	lda #$AF
;	sta COLPF3
	
	lda ZPLZS.GlobalTimer
	and #%00000001
	sne:sta WSYNC
	
	ldy #0
	ldx #2
	
deli_a
	lda dlicoltbl,y
	ora ZPVOL.Colour+0
	sta COLPF1
	sta WSYNC
	lda dlicoltbl,y
	lsr @
	adc #2
	sta COLPF0
	sta WSYNC
	iny
	dex
	bpl deli_a
	ldx #3
	
deli_b
	lda dlicoltbl,y
	ora ZPVOL.Colour+1
	sta COLPF1
	sta WSYNC
	lda dlicoltbl,y
	lsr @
	adc #2
	sta COLPF0
	sta WSYNC
	iny
	dex
	bpl deli_b
	ldx #7
	
deli_c
	lda dlicoltbl,y
	ora ZPVOL.Colour+2
	sta COLPF1
	sta WSYNC
	lda dlicoltbl,y
	lsr @
	adc #2
	sta COLPF0
	sta WSYNC
	iny
	dex
	bpl deli_c
	
deli_d
	sta WSYNC
	lda #0
	sta COLBK
	sta COLPF0
	sta COLPF2		; necessary for clearing the PF2 colour to black before the DLI is finished
	sta COLPF3
	lda #$0F		; necessary for setting up the mode 2 text brightness level, else it's all black!
	sta COLPF1
	jmp endnmi
	
;-----------------
	
;* VBI will run from here

vbi
	bit ZPLZS.RasterbarToggle
	bpl vbi_a
	lda #56
	sta COLBK
	
vbi_a
	sta NMIRES		; Reset NMI Status
	inc ZPLZS.GlobalTimer	; Increment Global Timer
	jsr HandleKeyboard	; Handle Keyboard and execute relevant subroutines based on Key presses
	lda ZPLZS.PlayerStatus	; What is the current Player state?
	bne vbi_f		; Stopped or Paused -> Do nothing
	
vbi_b
	dec ZPLZS.TimerOffset
	beq vbi_f
	bpl vbi_c
	lda ZPLZS.MachineRegion
	seq:lda #5
	sta ZPLZS.TimerOffset
	
vbi_c
	jsr CalculateTime 	; Update Timer
	jsr set_progress_bar	; Update Progress Bar
	
vbi_d
	jsr UpdateVolumeFadeout	; Update Fadeout
	bit ZPLZS.PlayerStatus	; What is the current Player state?
	bpl vbi_f		; Still Playing -> Continue like normal
	bit ZPLZS.StopOnFadeout	; Is it expected to be Stopped from the Fadeout?
	bmi vbi_f		; Yes -> Leave it Stopped
	
vbi_e
	jsr seek_forward	; Seek Next Song
	jsr set_play		; Switch Playback State to Play
		
vbi_f
	lda ZPLZS.DMAToggle
	beq vbi_i		; If the value is 0, nothing will be drawn, else, continue with everything below
	
vbi_g
	jsr test_vumeter_toggle	; process the VU Meter and POKEY registers display routines there
	jsr set_subtune_count	; update the subtune count on screen
	jsr set_play_pause_stop_button
	jsr set_highlight
	jsr print_player_infos	; print most of the stuff on screen using printhex or printinfo in bulk 
	jsr draw_progress_bar	; draw the progress bar during playback, using frames counted during export
	
vbi_h
	ldx <line_4		; Line 4 of text
	lda SKSTAT		; Serial Port Status
	and #$08		; SHIFT Key held down?
	sne:ldx <line_5		; line 5 of text (toggled by SHIFT)
	stx txt_toggle		; Write to change the text on line 4
	
vbi_i
	lda #0
	sta COLBK

;-----------------

endnmi
	pla
	tay
	pla
	tax
	pla
	rti

;-----------------

;------------------------------------------------------------------------------------------------------------------------------------;

;* everything below this point is stand alone subroutines that can be called at any time, or some misc data such as display list

;------------------------------------------------------------------------------------------------------------------------------------;

 ;* ----------------------------------------------------------------------------

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

;* ----------------------------------------------------------------------------

;* Set Playback speed using precalculated lookup tables, depending on the Machine Region
;* Cross-region adjustments are also supported, with few compatibility compromises

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

;* ----------------------------------------------------------------------------

; print text from data tables, useful for many things 

printinfo 
	sty charbuffer
	ldy #0
do_printinfo
        lda $ffff,x
infosrc equ *-2
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y
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
        sta (ZPLZS.TMP2),y+ ; sta (DISPLAY),y+
	pla
	and #$f
	tax
	mva hexchars,x (ZPLZS.TMP2),y ; (DISPLAY),y
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
;* TODO: Merge with the set_highlight subroutine?

set_play_pause_stop_button
	bit ZPLZS.PlayerStatus		; What is the current Player state?
	bmi stop_button_toggle		; Stopped
	bvs pause_button_toggle		; Paused
	ldx #0				; Playing
	beq play_button_toggle		; unconditional
stop_button_toggle
	ldx #16				; #$FF -> is stopped
	bne play_button_toggle		; unconditional
pause_button_toggle 
	ldx #8				; offset by 8 for PAUSE characters	
play_button_toggle
	ldy #7				; 7 character buffer is enough 
	mwa #line_0e1 ZPLZS.TMP2 ; DISPLAY		; move the position to the correct line
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

;* Display the currently playing subtune number, as well as the total number of subtunes
;* TODO: Optmise, this while thing, it's wasting a lot of CPU being redrawn every frame

set_subtune_count
	ldx ZPLZS.SongIndex
	inx
	cpx #$FF
current_subtune equ *-1
	beq set_subtune_count_done
	stx current_subtune		; set the new value in memory
	mwa #subtpos ZPLZS.TMP2 ; DISPLAY		; get the right screen position first
	txa
	jsr hex2dec_convert		; convert it to decimal 
	ldy #0
	jsr printhex_direct		; Y may not be 0 after the decimal conversion, do not risk it
	lda ZPLZS.SongCount
	jsr hex2dec_convert		; convert it to decimal 
	ldy #3				; offset to update the other number
	jsr printhex_direct		; this time Y will position where the character is written
set_subtune_count_done	
	rts
	
;-----------------

;* Menu input handler subroutine, all jumps will end on a RTS, and return to the 'set held key flag' execution 

do_button_selection
	rts
	
/*
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
*/

;* ----------------------------------------------------------------------------

;* Keyboard Input Handler, set up using Jump Tables

.proc HandleKeyboard
	lda SKSTAT			; Serial Port Status
	and #%00000100			; Last Key still pressed?
	beq HandleKeyboardContinue	; If yes, process further below
	lda #$FF
	sta ZPLZS.LastKeyPressed	; Reset Last Key registered

HandleKeyboardDone:
	rts
	
HandleKeyboardContinue:
	lda KBCODE			; Keyboard Code
	and #%00111111			; Clear the SHIFT and CTRL bits out of the Key Identifier
	cmp ZPLZS.LastKeyPressed	; Last Key currently held down?
	sta ZPLZS.LastKeyPressed	; Update Last Key registered
	beq HandleKeyboardDone		; If yes, there is nothing else to do here
	jsr TableJump			; Execute matching Subroutine otherwise
	
HandleKeyboardTable:
	.word toggle_loop-1		; 0 -> L key
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word dec_index_selection-1	; 6 -> Atari 'Left' / '+' key
	.word inc_index_selection-1	; 7 -> Atari 'Right' / '*' key 
	.word stop_toggle-1		; 8 -> 'O' key (not zero!!) 
	.word DoNothing-1
	.word play_pause_toggle-1	; 10 -> 'P' key
	.word DoNothing-1
	.word do_button_selection-1	; 12 -> 'Enter' key
	.word FrameAdvance-1		; 13 -> 'I' key
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1		; 21 -> 'B' key ; .word SwitchNextBank-1
	.word DoNothing-1
	.word DoNothing-1
	.word HandleKey_4-1		; 24 -> '4' key
	.word DoNothing-1
	.word HandleKey_3-1		; 26 -> '3' key
	.word HandleKey_6-1		; 27 -> '6' key
	.word ReturnToDOS-1		; 28 -> 'Escape' key
	.word HandleKey_5-1		; 29 -> '5' key
	.word HandleKey_2-1		; 30 -> '2' key
	.word HandleKey_1-1		; 31 -> '1' key
	.word DoNothing-1
	.word toggle_rasterbar-1	; 33 -> 'Spacebar' key
	.word DoNothing-1
	.word toggle_dli-1		; 35 -> 'N' key
	.word DoNothing-1
	.word toggle_pokey_mode-1	; 37 -> 'M' key
	.word DoNothing-1
	.word DoNothing-1
	.word toggle_vumeter-1		; 40 -> 'R' key
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word HandleKey_9-1		; 48 -> '9' key
	.word DoNothing-1
	.word HandleKey_0-1		; 50 -> '0' key
	.word HandleKey_7-1		; 51 -> '7' key
	.word DoNothing-1
	.word HandleKey_8-1		; 53 -> '8' key
	.word DoNothing-1
	.word DoNothing-1
	.word HandleKey_F-1		; 56 -> 'F' key
	.word DoNothing-1
	.word inc_index_selection-1	; 58 -> 'D' key
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word DoNothing-1
	.word dec_index_selection-1	; 63 -> 'A' key

HandleKey_1:
	jsr CheckForShiftAndCtrlPressed
	bcs HandleKey_1_a
	sne:jmp seek_reverse
	ldx #0
	jmp UpdateVolumeLevel
	
HandleKey_1_a:
	lda ZPLZS.VolumeMask
	eor #%00010000
	sta ZPLZS.VolumeMask
	rts
	
HandleKey_2:
	jsr CheckForShiftAndCtrlPressed
	bcs HandleKey_2_a
	sne:jmp seek_forward
	ldx #1
	jmp UpdateVolumeLevel
	
HandleKey_2_a:
	lda ZPLZS.VolumeMask
	eor #%00100000
	sta ZPLZS.VolumeMask
	rts

HandleKey_3:
	jsr CheckForShiftAndCtrlPressed
	bcs HandleKey_3_a
	sne:jmp fast_reverse
	ldx #2
	jmp UpdateVolumeLevel
	
HandleKey_3_a:
	lda ZPLZS.VolumeMask
	eor #%01000000
	sta ZPLZS.VolumeMask
	rts

HandleKey_4:
	jsr CheckForShiftAndCtrlPressed
	bcs HandleKey_4_a
	sne:jmp fast_forward
	ldx #3
	jmp UpdateVolumeLevel
	
HandleKey_4_a:
	lda ZPLZS.VolumeMask
	eor #%10000000
	sta ZPLZS.VolumeMask
	rts

HandleKey_5:
	jsr CheckForShiftAndCtrlPressed
	bcs HandleKey_5_a
	sne:jmp fast_reverse2
	ldx #4
	jmp UpdateVolumeLevel
	
HandleKey_5_a:
	lda ZPLZS.VolumeMask
	eor #%00000001
	sta ZPLZS.VolumeMask
	rts

HandleKey_6:
	jsr CheckForShiftAndCtrlPressed
	bcs HandleKey_6_a
	sne:jmp fast_forward2
	ldx #5
	jmp UpdateVolumeLevel
	
HandleKey_6_a:
	lda ZPLZS.VolumeMask
	eor #%00000010
	sta ZPLZS.VolumeMask
	rts

HandleKey_7:
	jsr CheckForShiftAndCtrlPressed
	bcs HandleKey_7_a
	sne:jmp fast_reverse3
	ldx #6
	jmp UpdateVolumeLevel
	
HandleKey_7_a:
	lda ZPLZS.VolumeMask
	eor #%00000100
	sta ZPLZS.VolumeMask
	rts

HandleKey_8:
	jsr CheckForShiftAndCtrlPressed
	bcs HandleKey_8_a
	sne:jmp fast_forward3
	ldx #7
	jmp UpdateVolumeLevel
	
HandleKey_8_a:
	lda ZPLZS.VolumeMask
	eor #%00001000
	sta ZPLZS.VolumeMask
	rts

HandleKey_9:
	bit KBCODE
	smi:jmp set_speed_down
	lda #%11111111
	svc:lda #%01101001
	sta ZPLZS.VolumeMask
	rts

HandleKey_0:
	bit KBCODE
	smi:jmp set_speed_up
	lda #%00000000
	svc:lda #%10010110
	sta ZPLZS.VolumeMask
	rts
	
HandleKey_F:
	bit ZPLZS.FadingOut
	bmi HandleKey_F_Done
	jsr trigger_fade_immediate
	dec ZPLZS.StopOnFadeout
	
HandleKey_F_Done:
	rts
.endp


.proc UpdateVolumeLevel
	bit KBCODE
	bmi UpdateVolumeLevelDecrement
	
UpdateVolumeLevelIncrement:
	inc ZPLZS.VolumeLevel,x
	lda ZPLZS.VolumeLevel,x
	cmp #$F0
	bcs UpdateVolumeLevelDone
	cmp #$10
	bcc UpdateVolumeLevelDone
	lda #$0F
	bpl UpdateVolumeLevelSet

UpdateVolumeLevelDecrement:
	dec ZPLZS.VolumeLevel,x
	lda ZPLZS.VolumeLevel,x
	cmp #$F0
	bcs UpdateVolumeLevelDone
	cmp #$10
	bcc UpdateVolumeLevelDone
	lda #$F0
	
UpdateVolumeLevelSet:
	sta ZPLZS.VolumeLevel,x

UpdateVolumeLevelDone:
	rts
.endp

;* Check for SHIFT and CTRL keys being held down
;* Status Flags will be returned accordingly
;* Carry Flag Set -> Both keys are pressed at once
;* Zero Flag Set -> Neither keys are pressed, since only Carry is checked for both keys specifically
;* Zero Flag Clear -> At least one key is pressed, regardless of which

.proc CheckForShiftAndCtrlPressed
	clc
	lda KBCODE
	and #%11000000
	beq CheckForShiftAndCtrlPressedDone
	cmp #%11000000
	
CheckForShiftAndCtrlPressedDone:
	rts
.endp
	
;* ----------------------------------------------------------------------------

;* General procedure for handling Jump Tables
;* Tables must be stored with a -1 offset right after the JSR to this Subroutine
;* Execution flow will resume like normal after the RTS hijack

.proc TableJump
	asl @
	tay
	iny
	iny
	pla
	sta ZPLZS.TMP2
	pla
	sta ZPLZS.TMP3
	lda (ZPLZS.TMP2),y
	pha
	dey
	lda (ZPLZS.TMP2),y
	pha
	rts
.endp

;* ----------------------------------------------------------------------------

;* A Subroutine that does absolutely nothing, intended for a Jump Table destination

.proc DoNothing
	rts
.endp

;* ----------------------------------------------------------------------------

/*
.proc SwitchNextBank
	ldx ZPLZS.MemBank
	inx
	cpx #33
	scc:ldx #0
	stx ZPLZS.MemBank
	bpl BankSwitch
.endp

.proc BankSwitch
	dex
	bpl BankSwitch_a
	lda #%11111110
	bmi BankSwitch_b
	
BankSwitch_a:
	txa
	and #%00000011
	:2 asl @
	ora #%00000010
	sta ZPLZS.TMP2
	txa
	and #%00011100
	:3 asl @
	ora ZPLZS.TMP2

BankSwitch_b:
	sta PORTB
	rts
.endp
*/

;* ----------------------------------------------------------------------------

;* Advance Playback for 1 Frame, at Playback Speed rate
;* Playback will be set to "Paused", regardless of its previous Status
;* Timing may be thrown off, but this should be close enough

.proc FrameAdvance
	bit ZPLZS.PlayerStatus
	svs:jmp set_pause
	
FrameAdvance_a:
	lda ZPLZS.SongSpeed
	sta ZPLZS.TMP2
	
FrameAdvance_b:
	jsr LZSSPlayFrame
	scc:jsr SetNewSongPtrs
;	jsr CheckForTwoToneBit
;	jsr SetVolumeFadeout
	jsr SwapBufferCopy
;	jsr SetVolumeMask
	dec ZPLZS.TMP2
	bpl FrameAdvance_b
	
FrameAdvance_c:
	dec ZPLZS.TimerOffset
	beq FrameAdvance_g
	bpl FrameAdvance_d
	lda ZPLZS.MachineRegion
	seq:lda #5
	sta ZPLZS.TimerOffset
	
FrameAdvance_d:
	jsr CalculateTime
	jsr set_progress_bar
	
FrameAdvance_e:
	jsr UpdateVolumeFadeout
	bit ZPLZS.PlayerStatus
	bpl FrameAdvance_g
	bit ZPLZS.StopOnFadeout
	bmi FrameAdvance_g
	
FrameAdvance_f:
	jsr seek_forward
	
FrameAdvance_g:
	jsr setpokeyfull
	
FrameAdvance_h:
	lda ZPLZS.PlayerStatus
	pha
	jsr set_play
	jsr begindraw
	pla
	sta ZPLZS.PlayerStatus
	
FrameAdvanceDone:
	rts
.endp

;* ----------------------------------------------------------------------------

; seek forward and reverse, both use the initialised flag + the new song pointers subroutine to perform it quickly
; reverse will land in the forward code, due to the way the song pointers are initialised
; forward doesn't even need to increment the index!

seek_reverse
	ldx ZPLZS.SongIndex
	dex
	bpl seek_done	
seek_wraparound
	ldx ZPLZS.SongCount
	dex 
	bne seek_done
seek_forward
	ldx ZPLZS.SongIndex
	inx 
	cpx ZPLZS.SongCount
	bcc seek_done
	ldx #0
seek_done
	stx ZPLZS.SongIndex
	dec ZPLZS.ProgramStatus		; Force a Reset within Main Loop
	rts
	
;-----------------

; index_selection 

dec_index_selection
inc_index_selection
	rts
	
/*
dec_index_selection
	ldx button_selection_flag
	dex 				; decrement the index
	bpl done_index_selection	; if the value did not underflow, done 
	ldx #6				; if it went past the boundaries, load the last valid index to wrap around
	bpl done_index_selection	; unconditional
inc_index_selection
	ldx button_selection_flag
	inx				; increment the index
	cpx #7				; compare to the maximum of 7 button indexes
	bcc done_index_selection	; if below 7, everything is good
	ldx #0				; else, load 0 to wrap around
done_index_selection
	stx button_selection_flag 	; overwrite the index value
	rts
*/

;-----------------

; timing modifyer inputs, only useful for debugging 

fast_reverse
	inc ZPLZS.SyncDivision
	sne:dec ZPLZS.SyncDivision
	rts
fast_forward
	dec ZPLZS.SyncDivision
	sne:inc ZPLZS.SyncDivision
	rts 
fast_reverse2
	inc ZPLZS.SyncCount
	sne:dec ZPLZS.SyncCount
	rts
fast_forward2
	dec ZPLZS.SyncCount
	sne:inc ZPLZS.SyncCount
	rts 
fast_reverse3
	inc ZPLZS.LastCount
/*
	lda ZPLZS.SyncOffset
	clc
	adc ZPLZS.SyncDivision
	sta ZPLZS.SyncOffset
	lda #0
	sta ZPLZS.SyncStatus
*/
	rts
fast_forward3	
	dec ZPLZS.LastCount
/*
	lda ZPLZS.SyncOffset
	sec
	sbc ZPLZS.SyncDivision
	sta ZPLZS.SyncOffset
	lda #0
	sta ZPLZS.SyncStatus
*/
	rts
	
;-----------------

set_speed_up
	ldy ZPLZS.SongSpeed
	iny
	cpy #8
	bcc set_speed_next
	ldy #0
	beq set_speed_next
set_speed_down
	ldy ZPLZS.SongSpeed
	dey 
	bpl set_speed_next
	ldy #7
set_speed_next	
	sty ZPLZS.SongSpeed
	jmp SetPlaybackSpeed

;-----------------

toggle_vumeter
	lda #$FF			; vumeter flag, 0 is vumeter, else FF displays the POKEY registers
vumeter_toggle equ *-1			; FIXME: Rename and move to Zeropage variables
	eor #$FF			; invert bits 
	sta vumeter_toggle		; overwrite the flag with the new value
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
	lda ZPLZS.RasterbarToggle	; Rasterbar toggle flag
	eor #%10000000			; Invert Bit 7
	sta ZPLZS.RasterbarToggle	; Overwrite with the new value
	rts 
	
;-----------------

toggle_loop
	lda ZPLZS.LoopCount		; Loop counter and flag
	eor #%10000000			; Invert Bit 7
	sta ZPLZS.LoopCount		; Overwrite with the new value
	rts 
	
;-----------------

toggle_pokey_mode
	lda ZPLZS.DMAToggle
	eor #$22
	sta ZPLZS.DMAToggle
	sta DMACTL
	rts
	
;-----------------

toggle_dli
	lda #$C0 
dli_toggler equ *-1			; FIXME: Rename and move to Zeropage variables
	eor #$80
	sta dli_toggler
	sta NMIEN
	rts

;-----------------

; stop and quit

.proc ReturnToDOS
	jsr stop_pause_reset
	jsr setpokeyfull
	ldx ZPLZS.StackPointer
	txs
	mva #$8D ZPLZS.TMP0
	mwa #PORTB ZPLZS.TMP1
	mva #$60 ZPLZS.TMP3
	lda #%11111111
	jmp ZPLZS.TMP0
.endp

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
;	lda button_selection_flag	; load the button flag value previously set in memory
	lda ZPLZS.PlayerMenuIndex
	asl @				; multiply it by 2 for the index 
	tay				; transfer to Y, use it to index the character directly
	lda b_handler,y 		; load the character in memory 
	eor #$80 			; invert the character, this will now define it as "highlighted"
	sta b_handler,y 		; write the character in memory, it is now selected, and will be processed again later 
	rts

;-----------------

;* TODO: Add Frames Calculations? Maybe Time?

PrintSongInfos:
	mwa #line_0 ZPLZS.TMP2 ; DISPLAY	; initialise the Display List indirect memory address for later
	ldy #4			; 4 characters buffer 
	ldx ZPLZS.SongSpeed
	inx
	txa
	jsr printhex_direct
	lda #0
	dey			; Y = 4 here, no need to reload it
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y 
	mva:rne txt_VBI-1,y line_0+5,y-
	ldy #4			; 4 characters buffer
	lda ZPLZS.MachineRegion
	asl @
	asl @
	adc #4
	tax
	mva:rne txt_REGION-1,x- line_0-1,y-
	ldy #8			; 8 characters buffer
	lda ZPLZS.SongStereo
	asl @
	asl @
	asl @
	adc #8
	tax
	mva:rne txt_STEREO-1,x- line_0+9,y-
	rts
	
;-----------------

;* print most infos on screen
	
print_player_infos
	mwa #line_0a ZPLZS.TMP2 ; DISPLAY 	; get the right screen position
	
print_minutes
	ldy #8
	lda ZPLZS.Minutes
	jsr hex2dec_convert
	jsr printhex_direct
print_seconds
	iny
	lda ZPLZS.Seconds
	and #1
	beq no_blink 
	lda #0
	beq blink
no_blink 
	lda #":" 
blink
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y 
	iny 
	lda ZPLZS.Seconds
	jsr hex2dec_convert
	jsr printhex_direct
	iny
	iny
	lda ZPLZS.Frames
	asl @
	jsr hex2dec_convert
	jsr printhex_direct
	
print_loop
	ldy #174
	lda ZPLZS.LoopCount	; verify if the loop flag is set to update the graphics accordingly
	bmi yes_loop		; it *should* be 0 if not looping, it will be overwritten anyway
	lda #0
	beq no_loop
yes_loop
	lda #"*" 
no_loop
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y
	
Print_pointers
	ldy #28
	lda ZPLZS.BufferPointer+1
	jsr printhex_direct
	iny
	lda ZPLZS.BufferPointer+0
	jsr printhex_direct	
	ldy #34
	lda ZPLZS.BufferEnd+1
	jsr printhex_direct
	iny
	lda ZPLZS.BufferEnd+0
	jsr printhex_direct
	
	ldy #57
	lda ZPLZS.SongSequence
	jsr printhex_direct
	ldy #62
	lda ZPLZS.SongSection
	jsr printhex_direct
	ldy #67
	lda ZPLZS.LoopCount
	jsr printhex_direct
	ldy #72
	lda ZPLZS.FadingOut
	jsr printhex_direct
	ldy #77
	lda ZPLZS.StopOnFadeout
	jsr printhex_direct
	
	ldy #122
	lda ZPLZS.VolumeLevel+0
	jsr printhex_direct
	:2 iny
	lda ZPLZS.VolumeLevel+1
	jsr printhex_direct
	:2 iny
	lda ZPLZS.VolumeLevel+2
	jsr printhex_direct
	:2 iny
	lda ZPLZS.VolumeLevel+3
	jsr printhex_direct
	:4 iny
	lda ZPLZS.VolumeLevel+4
	jsr printhex_direct
	:2 iny
	lda ZPLZS.VolumeLevel+5
	jsr printhex_direct
	:2 iny
	lda ZPLZS.VolumeLevel+6
	jsr printhex_direct
	:2 iny
	lda ZPLZS.VolumeLevel+7
	jsr printhex_direct
	
	lda ZPLZS.VolumeMask
	sta printvolumemask
	ldy #46
	ldx #3
	
printvolumemaskloop1
	lda (ZPLZS.TMP2),y ; lda (DISPLAY),y
	asl @
	asl printvolumemask
	ror @
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y
	dey
	dex
	bpl printvolumemaskloop1
	ldy #53
	ldx #3
	
printvolumemaskloop2
	lda (ZPLZS.TMP2),y ; lda (DISPLAY),y
	asl @
	asl printvolumemask
	ror @
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y
	dey
	dex
	bpl printvolumemaskloop2
	rts
	
printvolumemask
	.byte $00	; temporary workaround, variable in zeropage was already used...
	
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
	mwa #POKE2 ZPLZS.TMP2 ; DISPLAY	; set the position on screen
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
	lda SDWPOK0.POKCTL
	ldy #95
	jsr printhex_direct
;	lda SDWPOK0.POKSKC
	lda POKSKC+0
	ldy #99
	jsr printhex_direct
	ldx #0
	ldy #25
draw_right_pokey
	lda SDWPOK1,x
	stx reload_x_right
	jsr printhex_direct
	:3 iny
	ldx #0
reload_x_right equ *-1 
	:2 inx
	cpx #8
	bcc draw_right_pokey
	cpy #79
	bcs draw_right_pokey_next
	ldx #1
	ldy #65
	bpl draw_right_pokey
draw_right_pokey_next
	lda SDWPOK1.POKCTL
	ldy #113
	jsr printhex_direct
;	lda SDWPOK1.POKSKC
	lda POKSKC+1
	ldy #117
	jsr printhex_direct
draw_registers_done	
	rts

;-----------------

;* Draw the VUMeter display and process all the variables related to it

begindraw
	bit ZPLZS.PlayerStatus
	bvs drawloop_done
;	bvc begindraw_a
;	rts
	
begindraw_a
	ldx #7
	
begindraw_b
	lda SDWPOK0-0,x
	and #$0F
	beq begindraw_c
	pha
	lda SDWPOK0-1,x
	eor #$FF
	:3 lsr @
	tay
	pla
	asl @
;	adc #1
	cmp ZPVOL.Buffer,y
	smi:sta ZPVOL.Buffer,y
	
begindraw_c
	lda SDWPOK1-0,x
	and #$0F
	beq begindraw_d
	pha
	lda SDWPOK1-1,x
	eor #$FF
	:3 lsr @
	tay
	pla
	asl @
;	adc #1
	cmp ZPVOL.Buffer,y
	smi:sta ZPVOL.Buffer,y
	
begindraw_d
	:2 dex
	bpl begindraw_b
	
drawloop
;	lda ZPLZS.GlobalTimer
;	and #%00000001
;	beq drawloop_done

drawloop_a
	ldx #31

drawloop_b
	ldy ZPVOL.Buffer,x
	bmi drawloop_d
	dec ZPVOL.Buffer,x
	
drawloop_c
	lda vol_tbl_0,y
	sta mode_6+4,x
	lda vol_tbl_1,y
	sta mode_6a+4,x
	lda vol_tbl_2,y
	sta mode_6b+4,x
	lda vol_tbl_3,y
	sta mode_6c+4,x
	
drawloop_d
	dex
	bpl drawloop_b
	
drawloop_done
	rts
	
vol_0	equ $46	;+$80
vol_1	equ $47	;+$80
vol_2	equ $48	;+$80
vol_3	equ $49	;+$80
vol_4	equ $4A	;+$80
vol_5	equ $4B	;+$80
vol_6	equ $4C	;+$80
vol_7	equ $4D	;+$80
vol_8	equ $4E	;+$80


vol_tbl_0
	.byte vol_0, vol_0, vol_0, vol_0, vol_0, vol_0, vol_0, vol_0
vol_tbl_1
	.byte vol_0, vol_0, vol_0, vol_0, vol_0, vol_0, vol_0, vol_0
vol_tbl_2
	.byte vol_0, vol_0, vol_0, vol_0, vol_0, vol_0, vol_0, vol_0
vol_tbl_3
	.byte vol_0, vol_1, vol_2, vol_3, vol_4, vol_5, vol_6, vol_7
	.byte vol_8, vol_8, vol_8, vol_8, vol_8, vol_8, vol_8, vol_8
	.byte vol_8, vol_8, vol_8, vol_8, vol_8, vol_8, vol_8, vol_8
	.byte vol_8, vol_8, vol_8, vol_8, vol_8, vol_8, vol_8, vol_8

;-----------------

;* An attempt to display the subtune progression on screen with a progress bar and a cursor to nearest point in time
;* There are 32 sections, and 8 subsections within each ones of them, for a total of 256 pixels that could be used with this
;* Roughly, I need to divide a target value by 32 for the coarse movements, then by 8 for the fine movements, I think?
;* The result should then be the value number of bytes per coarse/fine movements, which can then be used to draw the progress bar

bar_cur	equ $54
bar_lne	equ $5C

/*
bar_counter
	dta $00,$00,$00
bar_increment
	dta $00,$00,$00
bar_loop
	dta $00
*/
	
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
	scc:lda #$FF				; bar was maxed out, it won't be updated further
	sta bar_counter+0
	
set_progress_bar_done
	rts
	
;-----------------

draw_progress_bar
	mwa #line_0c+4 ZPLZS.TMP2 ; DISPLAY 
	lda bar_counter+0
	tax
	lsr @
	lsr @
	lsr @
	tay 
	sta draw_empty_bar_count
	txa
	and #$07
	beq draw_progress_bar_a
	clc 
	adc #bar_cur
draw_progress_bar_a
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y
	dey 
	bmi draw_progress_bar_below_8
	lda #bar_lne 
draw_progress_bar_loop1
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y
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
	sta (ZPLZS.TMP2),y ; sta (DISPLAY),y
	dey 
	dex
	bpl draw_progress_bar_loop2 
draw_progress_bar_done
	rts

;-----------------

;------------------------------------------------------------------------------------------------------------------------------------;

;* And that's all :D


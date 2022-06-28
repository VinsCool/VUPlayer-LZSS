;// code by dmsc, unrolled by rensoupp
;
; LZSS Compressed SAP player for 16 match bits
; --------------------------------------------
;
; This player uses:
;  Match length: 8 bits  (2 to 257)
;  Match offset: 8 bits  (1 to 256)
;  Min length: 2
;  Total match bits: 16 bits
;

.ifndef POKEY
POKEY = $D200
.endif

.ifndef LZSS_PLAYER_FIXEDBUF
	.ALIGN $100
LZSSBuffers
    .ds 256 * 9
.else
LZSSBuffers = LZSS_PLAYER_FIXEDBUF
.endif

//--- macros to grab bytes from compressed stream
.MACRO GetByteIncY
    lda     (ZPLZS.SongPtr),y
    iny
.ENDM

.MACRO AddByteIncY
    adc     (ZPLZS.SongPtr),y     ;// make sure C is clear
    iny
.ENDM

;//##########################################################################
.LOCAL LZS
SongStartPtr        .ds     2
SongEndPtr          .ds     2
DstBufOffset        .ds     1
chn_bitsInit        .ds     1
chn_bits            .ds     1
Initialized         .byte   0
DLIDstBufOffset     .byte   0
.ENDL

;//##########################################################################
DecodeBufferBytes
    ; We are decoding a new match/literal
    lsr     ZPLZS.bit_data    ; Get next bit
    bne     @got_bit
    GetByteIncY         ; Not enough bits, refill!
    ror                 ; Extract a new bit and add a 1 at the high bit (from C set above)
    sta     ZPLZS.bit_data
@got_bit:
    GetByteIncY         ; Always read a byte, it could mean "match size/offset" or "literal byte"
    rts


.MACRO DecodeChannel CH_IDX
    lsr     LZS.chn_bits        ; TODO: use SM code to set a branch ?
    bcs     skip_chn            ; C=1 : skip this channel

    lda     SMSet_CHRLo+1
SMSet_CMP    
    cmp     #$ff                ; (must be reset on init!)
SMSet_Branch:    
    bne     CopyStoreCH

    jsr     DecodeBufferBytes
    bcs     store               ; Bit = 1 is "literal", bit = 0 is "match"

    sta     SMSet_CHRLo+1       ; Store in "copy pos"

    AddByteIncY
    sta     SMSet_CMP+1  ; Store in "copy length"

CopyStoreCH:
    inc     SMSet_CHRLo+1
SMSet_CHRLo    
    lda     LZSSBuffers+:CH_IDX*256 ; Now, read old data, jump to data store ; (low byte must be reset on init !)

store:
;    sta     POKEY+:CH_IDX      ; Store to output and buffer
    sta     LZSSBuffers+:CH_IDX*256,x
skip_chn    
.ENDM

;.print (LblDecodeChannel7-LblDecodeChannel8)
;.error ((LblDecodeChannel7-LblDecodeChannel8)>32)

;//##########################################################################
//--- update song pointer each frame (we can never move more than 255 bytes per frame even at 200hz, max is 3 bytes * 9 channels * 4 updates = 108 bytes )

// IN Y: ZPLZS.SrcBufOffset
UpdateLZSPtr	
    tya
	clc
	adc	ZPLZS.SongPtr
	sta	ZPLZS.SongPtr
	bcc @NoI
	inc	ZPLZS.SongPtr+1
@NoI	
	rts

;//##########################################################################

LZSSReset
	lda		#1
	sta		ZPLZS.bit_data            ;// bits to decide when to grab new data from the compressed stream
    sta     LZS.Initialized           ;// flag decoder as initialized
	
    //--- set song ptr
    lda     LZS.SongStartPtr+1
    sta     ZPLZS.SongPtr+1
    lda     LZS.SongStartPtr
    sta     ZPLZS.SongPtr

    //--- set dest offset in decompressed streams
	ldy		#0
    sty     LZS.DstBufOffset   

    ;//--- 1st frame of data is at offset 255 (1st frame is always stored uncompressed)
    lda     #255
    sta     LZS.DLIDstBufOffset     

    ;// get first byte which contains channels mask
    GetByteIncY
    sta     LZS.chn_bitsInit
    sta     LZS.chn_bits

    //--- reset initial value in arrays/decoder code (force CMP test to equal to take the path for decoding new bytes)    
    lda     DecodeChannel0.SMSet_CHRLo+1
    sta     DecodeChannel0.SMSet_CMP+1
    lda     DecodeChannel1.SMSet_CHRLo+1
    sta     DecodeChannel1.SMSet_CMP+1
    lda     DecodeChannel2.SMSet_CHRLo+1
    sta     DecodeChannel2.SMSet_CMP+1
    lda     DecodeChannel3.SMSet_CHRLo+1
    sta     DecodeChannel3.SMSet_CMP+1
    lda     DecodeChannel4.SMSet_CHRLo+1
    sta     DecodeChannel4.SMSet_CMP+1
    lda     DecodeChannel5.SMSet_CHRLo+1
    sta     DecodeChannel5.SMSet_CMP+1
    lda     DecodeChannel6.SMSet_CHRLo+1
    sta     DecodeChannel6.SMSet_CMP+1
    lda     DecodeChannel7.SMSet_CHRLo+1
    sta     DecodeChannel7.SMSet_CMP+1
    lda     DecodeChannel8.SMSet_CHRLo+1
    sta     DecodeChannel8.SMSet_CMP+1

    lda     #.HI(LZSSBuffers+$100*8)
    sta     @SMSet_LZSSBuf+2

    ldx #9-1
    
@SetFirstFrame 
    GetByteIncY   

    lsr     LZS.chn_bits
    bcc     @DontSetPokey
    
;	sta     POKEY,x                 ;// channel was not compressed, write to Pokey just once
    sta SDWPOK0,x			;// edit by VinsCool: write to POKEY buffer for VUPlayer's timing and VUMeter display
    
    bcs     @DontSetBuffer
@DontSetPokey    
@SMSet_LZSSBuf    
    sta     LZSSBuffers+$100*8+255    ;// channel was compressed, write first value at offset 255
@DontSetBuffer    
    dec     @SMSet_LZSSBuf+2        ;// next buffer
    dex 
    bpl     @SetFirstFrame
    
    //--- update src stream ptr
	jsr     UpdateLZSPtr
    //---
;    jmp     CreateChannelSkipCode       

;//-------------------------------------------------------------------------
;//--- called during song reset to modify NMI code that sends data to pokey
;//--- this changes writes to pokey (STA) to reads (LDA) when channels are skipped - could be a problem when reading POT stuff ????


CreateChannelSkipCode
.LOCAL
    lda     LZS.chn_bitsInit

SMSet_chn_bitsInit
    cmp     #0
    beq     NoNeedToReinit          ;// same mask as previous song
    sta     SMSet_chn_bitsInit+1
    sta     LZS.chn_bits

    ldx     #9-1-1
    ldy     #0

NextChannel
    lda     #$8D    ;// STA ABS
    asl     LZS.chn_bits
    bcc     @WriteChannel
    lda     #$AD    ;// LDA ABS     ;// change the write to pokey to a read 
    clc
@WriteChannel
    sta     SMSet_WritePokey0,y

    tya
    adc     #SMSet_WritePokey1-SMSet_WritePokey0
    tay

    dex
    bpl     NextChannel
NoNeedToReinit
    rts
.ENDL

;//##########################################################################
;//--- Method 1: play a single update for the current frame 
;//--- when CPU usage isn't important and it's ok to poll VCOUNT to wait for the next update

LZSSPlayFrame:    
    lda     LZS.DstBufOffset
    sta     LZS.DLIDstBufOffset

    ldx     #1
    lda     LZS.Initialized
    bne     LZSSPlay1Frame
    //--- (re)init song 
    jsr     LZSSReset
    rts


;//##########################################################################
;//--- Method 2: play all updates for the current frame (depending on song speed)
;//--- should be called at during VBI, so that only Pokey register updates are done during DLis

LZSSPlayFrames:    
    lda     LZS.DstBufOffset
    sta     LZS.DLIDstBufOffset

    ldx     SongSpeed

	lda		LZS.Initialized
	bne		@Initialized
    //--- (re)init song 
    jsr     LZSSReset
    //--- have multiple pokey frames to play ?
    ldx     SongSpeed
    dex
    bne     @Initialized
    rts
@Initialized


LZSSPlay1Frame
    stx     SMSet_PlayCounter+1

    ldx     LZS.DstBufOffset

    lda     LZS.chn_bitsInit
    sta     LZS.chn_bits
    
	ldy     #0     ;// source offset in compressed data
    
    ; Loop through all "channels", one for each POKEY register

LblDecodeChannel8
    DecodeChannel 8
LblDecodeChannel7    
    DecodeChannel 7
    DecodeChannel 6
    DecodeChannel 5
    DecodeChannel 4
    DecodeChannel 3
    DecodeChannel 2
    DecodeChannel 1
    DecodeChannel 0
    jsr     UpdateLZSPtr

    inc     LZS.DstBufOffset

SMSet_PlayCounter
    ldx     #$ff
    dex
    beq     @NoMoreFrame
    jmp     LZSSPlay1Frame
@NoMoreFrame
    rts

;//##########################################################################
;//--- out Z flag: clear = end of song

LZSSCheckEndOfSong
    //--- check end of song
    lda     ZPLZS.SongPtr + 1
    cmp     LZS.SongEndPtr+1
    bne     @NotEnd
    lda     ZPLZS.SongPtr
    cmp     LZS.SongEndPtr
    bne     @NotEnd
@NotEnd    
    rts

;//##########################################################################
//--- send decompressed data to pokey

LZSSUpdatePokeyRegisters
    //--- get offset into decoded buffers where lasts bytes were written to
    ldx     LZS.DLIDstBufOffset
    inc     LZS.DLIDstBufOffset

    ;//--- always update first register because always part of the compressed data
    lda    LZSSBuffers+0*256,x   
       
;	sta    POKEY+0
    sta SDWPOK0				;// edit by VinsCool: write to POKEY buffer for VUPlayer's timing and VUMeter display
    
    //---
UpdatePokeyRegisters1
.REPT 8 #
    lda    LZSSBuffers+(#+1)*256,x    
SMSet_WritePokey:1

;	sta    POKEY+(#+1)
    sta SDWPOK0+(#+1) 			;// edit by VinsCool: write to POKEY buffer for VUPlayer's timing and VUMeter display

.ENDR  

    rts  



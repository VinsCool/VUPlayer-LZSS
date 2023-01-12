;
; LZSS Compressed SAP player for 16 match bits
; --------------------------------------------
;
; (c) 2020 DMSC
; Code under MIT license, see LICENSE file.
;
; This player uses:
;  Match length: 8 bits  (1 to 256)
;  Match offset: 8 bits  (1 to 256)
;  Min length: 2
;  Total match bits: 16 bits
;
; Compress using:
;  lzss -b 16 -o 8 -m 1 input.rsap test.lz16
;
; Assemble this file with MADS assembler, the compressed song is expected in
; the `test.lz16` file at assembly time.
;
; The plater needs 256 bytes of buffer for each pokey register stored, for a
; full SAP file this is 2304 bytes.
;

	.ALIGN $100
buffers
	.ds 256 * 9

//////////////////////////////////

.LOCAL LZS
chn_copy	.ds     9
chn_pos		.ds     9
;bptr		.ds     2
SongStartPtr	.ds     2
SongEndPtr	.ds     2
;song_ptr	.ds	2
cur_pos		.ds     1
chn_bitsInit	.ds     1
chn_bits	.ds     1
ptr_offset	.ds	1
;bit_data	.byte   1
Initialized	.byte   0
.ENDL

//////////////////////////////////

;* Check for ending of song and jump to the next frame

LZSSCheckEndOfSong
	lda ZPLZS.SongPtr+1
	cmp LZS.SongEndPtr+1
	bne LZSSCheckEndOfSong_done
	lda ZPLZS.SongPtr
	cmp LZS.SongEndPtr
LZSSCheckEndOfSong_done
	rts

init_song
	mwa LZS.SongStartPtr ZPLZS.SongPtr
	jsr SwapBufferReset
	ldy #0
	sty ZPLZS.bptr			; Initialize buffer pointer
	sty LZS.cur_pos
	lda (ZPLZS.SongPtr),y		; Get the first byte to set the channel bits
	sta LZS.chn_bitsInit
	iny
	sty ZPLZS.bit_data		; always get new bytes
	sty LZS.Initialized
	lda #>buffers			; Set the buffer offset 
	sta cbuf+2
	ldx #8				; Init all channels
clear
	lda (ZPLZS.SongPtr),y		; Read just init value and store into buffer and POKEY
	iny
	sta SDWPOK0,x
cbuf
	sta buffers+255
	inc cbuf+2
	dex
	bpl clear
	tya
	clc
	adc ZPLZS.SongPtr
	sta ZPLZS.SongPtr
	scc:inc ZPLZS.SongPtr+1
	ldx #8
clear2
	lda #0
	sta LZS.chn_copy,x
	dex 
	bpl clear2
	rts

;* Play one frame of the song

LZSSPlayFrame
	lda LZS.Initialized
	beq init_song
	lda #>buffers
	sta ZPLZS.bptr+1
	lda LZS.chn_bitsInit
	sta LZS.chn_bits
	ldx #8				; Loop through all "channels", one for each POKEY register
	ldy #0 
	sty LZS.ptr_offset

chn_loop:
	lsr LZS.chn_bits
	bcs skip_chn			; C=1 : skip this channel
	lda LZS.chn_copy, x		; Get status of this stream
	bne do_copy_byte		; If > 0 we are copying bytes
	ldy LZS.ptr_offset

;* We are decoding a new match/literal

	lsr ZPLZS.bit_data		; Get next bit
	bne got_bit	
	lda (ZPLZS.SongPtr),y		; Not enough bits, refill!
	iny
	ror				; Extract a new bit and add a 1 at the high bit (from C set above)
	sta ZPLZS.bit_data
	
got_bit:
	lda (ZPLZS.SongPtr),y		; Always read a byte, it could mean "match size/offset" or "literal byte"
	iny
	sty LZS.ptr_offset
	bcs store			; Bit = 1 is "literal", bit = 0 is "match"
	sta LZS.chn_pos, x		; Store in "copy pos"
	lda (ZPLZS.SongPtr),y
	iny
	sta LZS.chn_copy, x		; Store in "copy length"
	sty LZS.ptr_offset

;* And start copying first byte

do_copy_byte:
	dec LZS.chn_copy, x		; Decrease match length, increase match position
	inc LZS.chn_pos, x
	ldy LZS.chn_pos, x
	lda (ZPLZS.bptr), y		; Now, read old data, jump to data store
store:
	ldy LZS.cur_pos
	sta SDWPOK0,x			; Store to output and buffer
	buffstore equ *-2
	sta (ZPLZS.bptr), y
skip_chn:
	inc ZPLZS.bptr+1		; Increment channel buffer pointer
	dex
	bpl chn_loop			; Next channel
	inc LZS.cur_pos
	lda ZPLZS.SongPtr
	clc
	adc LZS.ptr_offset
	sta ZPLZS.SongPtr
	scc:inc ZPLZS.SongPtr+1
	rts

;* Et voilà :D


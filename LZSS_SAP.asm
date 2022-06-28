; assemble SAP init here... this will set up the subtune to load

	sta SongIdx 
	ldx #0
	stx is_fadeing_out
	stx stop_on_fade_end
	jmp SetNewSongPtrsLoopsOnly
	
;* end of SAP format...

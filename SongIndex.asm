;* There is plenty of room for 128 subtunes, or 64 if the safer indexing method is used instead
;* This is assuming only 1 memory page or 256 bytes are dedicated to the subtunes index itself, mileage may vary

SongsIndexStart	
		;* BEGIN INDEX HERE, USE HI BYTES FOR THIS PART
SongsSHIPtrs 	
		.byte .HI(S_Id_0) 
		.byte .HI(S_Id_1) 
		.byte .HI(S_Id_2) 
		.byte .HI(S_Id_3) 
SongsIndexEnd
		.byte .HI(S_DUMMY) 
SongsEHIPtrs	
		;* END INDEX HERE, MUST BE ENDED WITH A DUMMY TUNE
SongsSLOPtrs	
		.byte .LO(S_Id_0)
		.byte .LO(S_Id_1)
		.byte .LO(S_Id_2)
		.byte .LO(S_Id_3)
SongsDummyEnd
		.byte .LO(S_DUMMY) 
SongsELOPtrs	
		;* LIKEWISE, MUST BE ENDED WITH A DUMMY TUNE
		
;//---------------------------------------------------------------------------------------------

;* TEST: looped subtunes index
;* Redirect the pointers to these values when the 'loop' flag is set, allowing them to loop seamlessly!
;* This is experimental, and may not work properly
;* BUG(?) double dummy entry will prevent seeking back, but going forward is a-okay
;* BUG2(?) playing with a total of 1 tunes will play/fade/etc exactly like expected, but the timer will never be reset... 
;* I would argue the second point seems to be very much correct but I dunno really :P 

LoopsIndexStart
		;* BEGIN INDEX HERE, USE HI BYTES FOR THIS PART
LoopsSHIPtrs
		.byte .HI(L_Id_0)
		.byte .HI(L_Id_1)
		.byte .HI(L_Id_2)
		.byte .HI(L_Id_3)
LoopsIndexEnd		
		.byte .HI(L_DUMMY) 
LoopsEHIPtrs	
		;* END INDEX HERE, MUST BE ENDED WITH A DUMMY TUNE
LoopsSLOPtrs
		.byte .LO(L_Id_0) 
		.byte .LO(L_Id_1) 
		.byte .LO(L_Id_2) 
		.byte .LO(L_Id_3) 
LoopsDummyEnd		
		.byte .LO(L_DUMMY) 
LoopsELOPtrs	
		;* LIKEWISE, MUST BE ENDED WITH A DUMMY TUNE 		

;//---------------------------------------------------------------------------------------------

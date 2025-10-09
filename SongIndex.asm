;* Songs index always begin with the "Intro" section, followed by the "Loop" section, when applicable
;* Index list must end with the dummy tune address to mark the end of each list properly
;* Make sure to define the total number of tunes that could be indexed in code using it to avoid garbage data being loaded

;-----------------
		
;//---------------------------------------------------------------------------------------------

;* Struct Data, all in a single block

SongIndex:
	.byte TUNE_DEF
SongCount:
	.byte ?SNG_Count
RasterbarToggle:
	.byte RASTERBAR_TOGGLE
RasterbarColour:
	.byte RASTERBAR_COLOUR
SectionTable:
	.word SongSection
SongTable:
	MakeSongTable
SongSection:
	MakeSectionTable

;-----------------
		
;//---------------------------------------------------------------------------------------------

;* Song Data, all in a single block

.ifndef SNG_Count
	.def ?SNG_Count = 0
.endif

;-----------------

SNG_00:
SNG_01:	MakeSong PAL, TRUE, MONO, 1, 0, 0, TRUE
	FindSection LZ_01
	EndSequence
	
SNG_02:	MakeSong PAL, TRUE, MONO, 1, 0, 0, TRUE
	FindSection LZ_02
	EndSequence
	
SNG_03:	MakeSong PAL, TRUE, MONO, 1, 0, 0, TRUE
	FindSection LZ_03
	EndSequence
	
SNG_04:	MakeSong PAL, TRUE, MONO, 1, 0, 0, TRUE
	FindSection LZ_04
	FindSection LZ_04a
	GotoSequence 1
	
SNG_05:	MakeSong PAL, TRUE, MONO, 1, 1920, 0, TRUE
	FindSection LZ_05
	GotoSequence 0
	
SNG_06:	MakeSong PAL, TRUE, MONO, 1, 0, 0, TRUE
	FindSection LZ_06
	FindSection LZ_06a
	GotoSequence 1
	
SNG_07:	MakeSong PAL, TRUE, MONO, 1, 1720, 0, TRUE
	FindSection LZ_07
	GotoSequence 0
	
SNG_08:	MakeSong PAL, TRUE, MONO, 1, 38, 0, FALSE
	FindSection LZ_08
	GotoSequence 0
	
SNG_09:	MakeSong PAL, TRUE, MONO, 1, 57, 0, FALSE
	FindSection LZ_09
	GotoSequence 0
	
SNG_10:	MakeSong PAL, TRUE, MONO, 1, 50, 0, FALSE
	FindSection LZ_10
	GotoSequence 0
	
SNG_11:	MakeSong PAL, TRUE, MONO, 1, 54, 0, FALSE
	FindSection LZ_11
	GotoSequence 0
	
SNG_12:	MakeSong PAL, TRUE, MONO, 1, 33, 0, FALSE
	FindSection LZ_12
	GotoSequence 0
	
SNG_13:	MakeSong PAL, TRUE, MONO, 1, 38, 0, FALSE
	FindSection LZ_13
	GotoSequence 0
	
SNG_14:	MakeSong PAL, TRUE, MONO, 1, 33, 0, FALSE
	FindSection LZ_14
	GotoSequence 0
	
SNG_15:	MakeSong PAL, TRUE, MONO, 1, 33, 0, FALSE
	FindSection LZ_15
	GotoSequence 0
	
;-----------------
		
;//---------------------------------------------------------------------------------------------

;* LZSS Data, all in a single block

.ifndef LZ_Count
	.def ?LZ_Count = 0
.endif

;-----------------

LZ_00:
LZ_01:	LoadData '/FireNIce/Coolmint Island (Prologue Pt 1).lzss', TRUE
LZ_02:	LoadData '/FireNIce/Enemy Theme (Prologue Pt 2).lzss', TRUE
LZ_03:	LoadData '/FireNIce/Dana is Chosen (Prologue Pt 3).lzss', TRUE
LZ_04:	LoadData '/FireNIce/The Story of Dana_INTRO.lzss', TRUE
LZ_04a:	LoadData '/FireNIce/The Story of Dana_LOOP.lzss', TRUE
;LZ_05:	LoadData '/FireNIce/Grandmas House (Menu)_LOOP.lzss', TRUE
LZ_05:	LoadData '/FireNIce/test.lzss', TRUE
LZ_06:	LoadData '/FireNIce/Level Select_INTRO.lzss', TRUE
LZ_06a:	LoadData '/FireNIce/Level Select_LOOP.lzss', TRUE
LZ_07:	LoadData '/FireNIce/World 1 (Ice Rock Island)_LOOP.lzss', TRUE
LZ_08:	LoadData '/FireNIce/World 2 (Cobalt Mine)_LOOP.lzss', TRUE
LZ_09:	LoadData '/FireNIce/World 3 (Golden Castle)_LOOP.lzss', TRUE
LZ_10:	LoadData '/FireNIce/World 4 (Big Tree)_LOOP.lzss', TRUE
LZ_11:	LoadData '/FireNIce/World 5 (Star Field)_LOOP.lzss', TRUE
LZ_12:	LoadData '/FireNIce/World 6 (Earth Temple)_LOOP.lzss', TRUE
LZ_13:	LoadData '/FireNIce/World 7 (Farthest Lake)_LOOP.lzss', TRUE
LZ_14:	LoadData '/FireNIce/World 8 (Bone Canyon)_LOOP.lzss', TRUE
LZ_15:	LoadData '/FireNIce/World 9 (Volcano)_LOOP.lzss', TRUE

;-----------------
		
;//---------------------------------------------------------------------------------------------


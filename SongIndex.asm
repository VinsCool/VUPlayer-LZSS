;* Songs index always begin with the "Intro" section, followed by the "Loop" section, when applicable
;* Index list must end with the dummy tune address to mark the end of each list properly
;* Make sure to define the total number of tunes that could be indexed in code using it to avoid garbage data being loaded

;-----------------
		
;//---------------------------------------------------------------------------------------------

.macro LoadData Filename, OldFormat
	.put [(?LZ_Count * 2) + 0] = [* & 255]
	.put [(?LZ_Count * 2) + 1] = [* >> 8]
	.def ?LZ_Count += 1
	.if (:OldFormat == TRUE)
		.byte $00, $00
	.endif
	ins :Filename
.endm

.macro MakeSectionTable
	.rept ?LZ_Count
		.word [.get[(# * 2) + 0] | .get[(# * 2) + 1] << 8]
	.endr
	.word SongDataEnd
.endm

.macro MakeSongTable
	.rept ?SNG_Count
		.word [.get[$1000 + (# * 2) + 0] | .get[$1000 + (# * 2) + 1] << 8]
	.endr
.endm

.macro MakeSongTimer TotalTime, LoopTime
	.if (:TotalTime > 0)
		.def ?TotalTimeFrames = $FFFFFF / (:TotalTime * 50)
	.else
		.def ?TotalTimeFrames = 0
	.endif
	.if (:LoopTime > 0)
		.def ?LoopTimeFrames = ?TotalTimeFrames * (:LoopTime * 50)
	.else
		.def ?LoopTimeFrames = 0
	.endif
	.byte [[?TotalTimeFrames >> 16] & 255]
	.byte [[?TotalTimeFrames >> 8] & 255]
	.byte [[?TotalTimeFrames] & 255]
	.byte [[?LoopTimeFrames >> 16] & 255]
.endm

.macro MakeSong Region, Adjust, Stereo, Speed, Time, Loop
	.if (?SEQ_Done == FALSE)
		.error "Invalid Sequence Start, a GotoSequence or EndSequence command was not used prior!"
	.else
		.put [$1000 + (?SNG_Count * 2) + 0] = [* & 255]
		.put [$1000 + (?SNG_Count * 2) + 1] = [* >> 8]
		.def ?SNG_Count += 1
		.def ?SEQ_Index = 0
		.def ?SEQ_Done = FALSE
		.byte [(((:Speed - 1) & %00000111) << 3) | (:Region << 2) | (:Adjust << 1) | :Stereo]
		MakeSongTimer :Time, :Loop
	.endif
.endm

.macro GotoSequence Offset
	.if (?SEQ_Done == TRUE)
		.error "Invalid Sequence Goto, a GotoSequence or EndSequence command was used already!"
	.else
		.if (:Offset < ?SEQ_Index)
			.byte [:Offset | %10000000]
			.def ?SEQ_Done = TRUE
		.else
			.error "Invalid Sequence Offset, the value of ", :Offset, " was given, but ", ?SEQ_Index - 1, " is the maximum!"
		.endif
	.endif
.endm

.macro EndSequence
	.if (?SEQ_Done == TRUE)
		.error "Invalid Sequence End, a GotoSequence or EndSequence command was used already!"
	.else
		.byte $FF
		.def ?SEQ_Done = TRUE
	.endif
.endm

.macro FindSection SectionAddress
	.if (?SEQ_Done == TRUE)
		.error "Invalid Sequence Order, a GotoSequence or EndSequence command was used already!"
	.else
		.def ?FoundSection = FALSE
		.rept ?LZ_Count
			.def ?LookupIndex = #
			.def ?LookupAddress = [.get[(?LookupIndex * 2) + 0] | .get[(?LookupIndex * 2) + 1] << 8]
			.if ((?FoundSection == FALSE) && (:SectionAddress == ?LookupAddress))
				.def ?FoundSection = TRUE
				.def ?SEQ_Index += 1
				.byte ?LookupIndex
			.endif
		.endr
		.if (?FoundSection == FALSE)
			.error "Could not find Matching Index!"
		.endif
	.endif
.endm

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

SongSequence:
SNG_00	MakeSong 0, 1, 0, 1, 0, 0
	FindSection LZ_00
	EndSequence
	
SNG_01	MakeSong 0, 1, 0, 1, 0, 0
	FindSection LZ_01
	EndSequence
	
SNG_02	MakeSong 0, 1, 0, 1, 0, 0
	FindSection LZ_02
	EndSequence
	
SNG_03	MakeSong 0, 1, 0, 1, 0, 0
	FindSection LZ_03
	FindSection LZ_03a
	GotoSequence 1
	
SNG_04	MakeSong 0, 1, 0, 1, 0, 0
	FindSection LZ_04
	GotoSequence 0
	
SNG_05	MakeSong 0, 1, 0, 1, 0, 0
	FindSection LZ_05
	FindSection LZ_05a
	GotoSequence 1
	
SNG_06	MakeSong 0, 1, 0, 1, 34, 0
	FindSection LZ_06
	GotoSequence 0
	
SNG_07	MakeSong 0, 1, 0, 1, 38, 0
	FindSection LZ_07
	GotoSequence 0
	
SNG_08	MakeSong 0, 1, 0, 1, 57, 0
	FindSection LZ_08
	GotoSequence 0
	
SNG_09	MakeSong 0, 1, 0, 1, 50, 0
	FindSection LZ_09
	GotoSequence 0
	
SNG_10	MakeSong 0, 1, 0, 1, 54, 0
	FindSection LZ_10
	GotoSequence 0
	
SNG_11	MakeSong 0, 1, 0, 1, 33, 0
	FindSection LZ_11
	GotoSequence 0
	
SNG_12	MakeSong 0, 1, 0, 1, 38, 0
	FindSection LZ_12
	GotoSequence 0
	
SNG_13	MakeSong 0, 1, 0, 1, 33, 0
	FindSection LZ_13
	GotoSequence 0
	
SNG_14	MakeSong 0, 1, 0, 1, 33, 0
	FindSection LZ_14
	GotoSequence 0
SongSequenceEnd:

;-----------------
		
;//---------------------------------------------------------------------------------------------

;* LZSS Data, all in a single block

.ifndef LZ_Count
	.def ?LZ_Count = 0
.endif

SongData:
LZ_00	LoadData '/FireNIce/Coolmint Island (Prologue Pt 1).lzss', TRUE
LZ_01	LoadData '/FireNIce/Enemy Theme (Prologue Pt 2).lzss', TRUE
LZ_02	LoadData '/FireNIce/Dana is Chosen (Prologue Pt 3).lzss', TRUE
LZ_03	LoadData '/FireNIce/The Story of Dana_INTRO.lzss', TRUE
LZ_03a	LoadData '/FireNIce/The Story of Dana_LOOP.lzss', TRUE
LZ_04	LoadData '/FireNIce/Grandmas House (Menu)_LOOP.lzss', TRUE
LZ_05	LoadData '/FireNIce/Level Select_INTRO.lzss', TRUE
LZ_05a	LoadData '/FireNIce/Level Select_LOOP.lzss', TRUE
LZ_06	LoadData '/FireNIce/World 1 (Ice Rock Island)_LOOP.lzss', TRUE
LZ_07	LoadData '/FireNIce/World 2 (Cobalt Mine)_LOOP.lzss', TRUE
LZ_08	LoadData '/FireNIce/World 3 (Golden Castle)_LOOP.lzss', TRUE
LZ_09	LoadData '/FireNIce/World 4 (Big Tree)_LOOP.lzss', TRUE
LZ_10	LoadData '/FireNIce/World 5 (Star Field)_LOOP.lzss', TRUE
LZ_11	LoadData '/FireNIce/World 6 (Earth Temple)_LOOP.lzss', TRUE
LZ_12	LoadData '/FireNIce/World 7 (Farthest Lake)_LOOP.lzss', TRUE
LZ_13	LoadData '/FireNIce/World 8 (Bone Canyon)_LOOP.lzss', TRUE
LZ_14	LoadData '/FireNIce/World 9 (Volcano)_LOOP.lzss', TRUE
SongDataEnd:

;-----------------
		
;//---------------------------------------------------------------------------------------------


;* Songs index always begin with the "Intro" section, followed by the "Loop" section, when applicable
;* Index list must end with the dummy tune address to mark the end of each list properly
;* Make sure to define the total number of tunes that could be indexed in code using it to avoid garbage data being loaded

;-----------------
		
;//---------------------------------------------------------------------------------------------

.macro LoadData Filename
	.put [(?LZ_Count * 2) + 0] = [* & 255]
	.put [(?LZ_Count * 2) + 1] = [* >> 8]
	.def ?LZ_Count += 1
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

SNG_00	MakeSong 1, 1, 0, 1, 263, 86
	FindSection LZ_O0
	FindSection LZ_O1
	GotoSequence 1
SNG_01	MakeSong 1, 1, 0, 1, 236, 52
	FindSection LZ_P0
	FindSection LZ_P1
	GotoSequence 1
SNG_02	MakeSong 1, 1, 0, 1, 119, 0
	FindSection LZ_C0
	GotoSequence 0
SNG_03	MakeSong 1, 1, 1, 1, 37, 0
	FindSection LZ_50
	GotoSequence 0
SNG_04	MakeSong 1, 1, 1, 2, 60, 0
	FindSection LZ_SS
	GotoSequence 0
	
;-----------------
		
;//---------------------------------------------------------------------------------------------

;* LZSS Data, all in a single block

.ifndef LZ_Count
	.def ?LZ_Count = 0
.endif

SongData:
LZ_SS	LoadData '/RANDOM4/Test 8.lzss'
LZ_50	LoadData '/RANDOM4/Sketch 57 v5.lzss'
LZ_C0	LoadData '/RANDOM3/SKETCH_24_LOOP.lzss'
LZ_O0	LoadData '/RANDOM4/Table Manuscrite Final_INTRO.lzss'
LZ_O1	LoadData '/RANDOM4/Table Manuscrite Final_LOOP.lzss'
LZ_P0	LoadData '/RANDOM4/Journey_Through_a_Strange_Portal_Final_INTRO.lzss'
LZ_P1	LoadData '/RANDOM4/Journey_Through_a_Strange_Portal_Final_LOOP.lzss'
SongDataEnd:

;-----------------
		
;//---------------------------------------------------------------------------------------------


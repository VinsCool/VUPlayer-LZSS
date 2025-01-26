;* LZSS Driver and VUPlayer variables

.local ZPLZS
TMP
TMP0		.ds 1
TMP1		.ds 1
TMP2		.ds 1
TMP3		.ds 1

BufferStart	.ds 2	;* Start Buffer(s) Address, first byte is always the Channel Bit Byte, and must be fetched from it each frame
BufferEnd	.ds 2	;* End Buffer(s) Address
BufferPointer	.ds 2	;* Current Buffer(s) Address

BufferBitByte	.ds 1	;* Buffer Bit Byte, used for Match or Literal, must be initialised to 1 each time a new File is decompressed

BufferStatus	.ds 1	;* Buffer Status, Negative flag must be set to force Initialisation in the middle of playback
BufferOffset	.ds 1	;* Buffer Offset, used to update the Current Buffer Address and remaining Buffer Size to process

ChannelBitByte	.ds 3*1	;* Channel Bit Byte, used for skipping channels when no data is needed for it

ChannelOffset	.ds 1	;* Channel Offset, common for all Channel Buffers

ChannelBuffer	.ds 2	;* Channel Buffer(s) Address

ByteCount	.ds 2*9	;* Channel Bytes to Copy (Match Length)
LastOffset	.ds 2*9	;* Channel Offset (Match Position)

;SequencePointer	.ds 2
;SectionPointer	.ds 2

SongPointer	.ds 2

SongIndex	.ds 1
SongCount	.ds 1
SongSpeed	.ds 1
SongRegion	.ds 1
SongStereo	.ds 1

SongSequence	.ds 1
SongSection	.ds 1
LoopCount	.ds 1
FadingOut	.ds 1
StopOnFadeout	.ds 1

PlayerStatus	.ds 1
VolumeMask	.ds 1

VolumeLevel	.ds 8

MachineStereo	.ds 1

MachineRegion	.ds 1
AdjustSpeed	.ds 1

GlobalTimer	.ds 1
TimerOffset	.ds 1
Frames		.ds 1
Seconds		.ds 1
Minutes		.ds 1

SyncStatus	.ds 1
LastCount	.ds 1
SyncCount	.ds 1
SyncOffset	.ds 1
SyncDelta	.ds 1
SyncDivision	.ds 1

RasterbarToggle	.ds 1
RasterbarColour	.ds 1

LastKeyPressed	.ds 1
PlayerMenuIndex	.ds 1

DMAToggle	.ds 1
ProgramStatus	.ds 1
StackPointer	.ds 1
MemBank		.ds 1
OrgAddress	.ds 2
.endl

;-----------------

POKSKC		.ds 2
SDWPOK

;* Left POKEY

.local SDWPOK0 
POKF0		.ds 1
POKC0		.ds 1
POKF1		.ds 1
POKC1		.ds 1
POKF2		.ds 1
POKC2		.ds 1
POKF3		.ds 1
POKC3		.ds 1
POKCTL		.ds 1
;POKSKC		.ds 1
.endl

;-----------------

;* Right POKEY

.local SDWPOK1	
POKF0		.ds 1
POKC0		.ds 1
POKF1		.ds 1
POKC1		.ds 1
POKF2		.ds 1
POKC2		.ds 1
POKF3		.ds 1
POKC3		.ds 1
POKCTL		.ds 1
;POKSKC		.ds 1
.endl

;-----------------

bar_counter	.ds 3
bar_increment	.ds 3
bar_loop	.ds 1
;DISPLAY		.ds 2

;-----------------

;* VUMeter Volume Decay Buffer

.local ZPVOL
Buffer		.ds 32
Colour		.ds 4
.endl

;-----------------


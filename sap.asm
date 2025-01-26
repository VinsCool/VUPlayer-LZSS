;***************************************************************************************************************;
;* Simple RMT2SAP Creator                                                                                      *;
;* By VinsCool, 05-10-2021                                                                                     *;
;* Based on the SAP specs listed at http://asap.sourceforge.net/sap-format.html                                *;
;*                                                                                                             *;
;* Include with Simple RMT Player (dasmplayer.asm) to export .sap files instead of Atari executables (.obx)    *;
;* Edit the text with the infos you want, a maximum of 120 characters per argument is supported                *;
;* Use "<?>" for unknown values, although this is entirely optional, it's simply for the SAP format convention *;
;* SPACING is the CR/LF (Carriage Return, Line Feed) word, simply put this between each argument               *;
;***************************************************************************************************************;


.macro MakeHEXChars Byte
	.def ?NybbleHi = (:Byte >> 4)
	.def ?NybbleLo = (:Byte & $0F)
	
	.if (?NybbleHi < 10)
		.byte [$30 + ?NybbleHi]
	.else
		.byte [$37 + ?NybbleHi]
	.endif
	
	.if (?NybbleLo < 10)
		.byte [$30 + ?NybbleLo]
	.else
		.byte [$37 + ?NybbleLo]
	.endif
.endm


.macro MakeDECChars Byte
	.def ?NybbleHi = (:Byte >> 4)
	.def ?NybbleLo = (:Byte & $0F)
	
	.if (?NybbleHi > 0)
		; Kill me
	.endif
	
	.if (?NybbleLo < 10)
		.byte [$30 + ?NybbleLo]
	.else
		.byte '1'
		.byte [$30 + (?NybbleLo - 10)]
	.endif
.endm



.macro MakeSAP Author, Name, Date, Songs, Defsong, Stereo, NTSC, Speed, Init, Player, Time, Loop
	.def ?HEADER = $FFFF
	.def ?SPACING = $0A0D
	
SAP
	.byte 'SAP'
	.word ?SPACING
	
AUTHOR	
	.byte 'AUTHOR ":Author"'
	.word ?SPACING
	
NAME	
	.byte 'NAME ":Name"'
	.word ?SPACING
	
DATE	
	.byte 'DATE ":Date"'
	.word ?SPACING
	
SONGS
	.if (:Songs > 1)
		.byte 'SONGS '
		MakeDECChars :Songs
		.word ?SPACING
	.endif
	
DEFSONG
	.if ((:Songs > 1) && (:Defsong > 0))
		.byte 'DEFSONG '
		MakeDECChars :Defsong
		.word ?SPACING
	.endif
	
STEREO
	.if (:Stereo == TRUE)
		.byte 'STEREO'
		.word ?SPACING
	.endif
/*	
NTSC
	.if (:NTSC == TRUE)
		.byte 'NTSC'
		.word ?SPACING
	.endif
*/	
TYPE
	.byte 'TYPE D'	; 'TYPE B'
	.word ?SPACING
/*	
FASTPLAY
	.byte 'FASTPLAY '
	
	.if (:NTSC == TRUE)
		.if (:Speed == 1)
			.byte '262'
		.elseif (:Speed == 2)
			.byte '131'
		.elseif (:Speed == 3)
			.byte '87'
		.elseif (:Speed == 4)
			.byte '66'
		.elseif (:Speed == 5)
			.byte '52'
		.elseif (:Speed == 6)
			.byte '44'
		.elseif (:Speed == 7)
			.byte '37'
		.elseif (:Speed == 8)
			.byte '33'
		.endif
	.else
		.if (:Speed == 1)
			.byte '312'
		.elseif (:Speed == 2)
			.byte '156'
		.elseif (:Speed == 3)
			.byte '104'
		.elseif (:Speed == 4)
			.byte '78'
		.elseif (:Speed == 5)
			.byte '62'
		.elseif (:Speed == 6)
			.byte '52'
		.elseif (:Speed == 7)
			.byte '45'
		.elseif (:Speed == 8)
			.byte '39'
		.endif
	.endif
	.word ?SPACING
*/	
INIT
	.byte 'INIT '
	MakeHEXChars (:Init >> 8)
	MakeHEXChars (:Init & $FF)
	.word ?SPACING
/*	
PLAYER
	.byte 'PLAYER '
	MakeHEXChars (:Player >> 8)
	MakeHEXChars (:Player & $FF)
	.word ?SPACING
	
TIME
	.byte "TIME "
	.byte "69:42.00 "
	.byte "LOOP"
	.word SPACING
*/	
ENDHEADER
	.word ?SPACING, ?HEADER
.endm

	MakeSAP "VinsCool", "Test SAP Export", "01/01/2025", TUNE_NUM, TUNE_DEF, TRUE, TRUE, 1, InitSAP, PlaySAP, FALSE, FALSE
	

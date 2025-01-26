#ifndef _LZSSP_ASM_H_
#define _LZSSP_ASM_H_

#define LZSSP_SAP_BINARY 0x0000
#define LZSSP_ARGUMENT 0xFFFF0001
#define LZSSP_ZEROPAGE 0x0080
#define LZSSP_STACK 0x0100
#define LZSSP_LZDATA 0x2000
#define LZSSP_RELOCATOR 0x0100
#define LZSSP_DRIVER 0xD800
#define LZSSP_BUFFERS 0xED00
#define LZSSP_VLINE 0x0016
#define LZSSP_VBLANK_SCANLINE 0x007C
#define LZSSP_PAL_SCANLINE 0x009C
#define LZSSP_NTSC_SCANLINE 0x0083
#define LZSSP_RASTERBAR_TOGGLE 0x0080
#define LZSSP_RASTERBAR_COLOUR 0x0069
#define LZSSP_TUNE_DEF 0x0000
#define LZSSP_Build_LZData 0x0000
#define LZSSP_Build_Driver 0x0001
#define LZSSP_Build_Relocator 0x0002
#define LZSSP_Build_MergeXEX 0x0003
#define LZSSP_Build_MergeSAP 0x0004
#define LZSSP_Build_Count 0x0005
#define LZSSP_DOSVEC 0x000A
#define LZSSP_RTCLOK 0x0012
#define LZSSP_VDSLST 0x0200
#define LZSSP_VVBLKI 0x0222
#define LZSSP_SDMCTL 0x022F
#define LZSSP_SDLSTL 0x0230
#define LZSSP_COLOR0 0x02C4
#define LZSSP_COLOR1 0x02C5
#define LZSSP_COLOR2 0x02C6
#define LZSSP_COLOR3 0x02C7
#define LZSSP_COLOR4 0x02C8
#define LZSSP_CH1 0x02F2
#define LZSSP_CHBAS 0x02F4
#define LZSSP_CH 0x02FC
#define LZSSP_HPOSP0 0xD000
#define LZSSP_HPOSP1 0xD001
#define LZSSP_HPOSP2 0xD002
#define LZSSP_HPOSP3 0xD003
#define LZSSP_HPOSM0 0xD004
#define LZSSP_HPOSM1 0xD005
#define LZSSP_HPOSM2 0xD006
#define LZSSP_HPOSM3 0xD007
#define LZSSP_SIZEP0 0xD008
#define LZSSP_SIZEP1 0xD009
#define LZSSP_SIZEP2 0xD00A
#define LZSSP_SIZEP3 0xD00B
#define LZSSP_SIZEM 0xD00C
#define LZSSP_GRAFP0 0xD00D
#define LZSSP_GRAFP1 0xD00E
#define LZSSP_GRAFP2 0xD00F
#define LZSSP_GRAFP3 0xD010
#define LZSSP_TRIG0 0xD010
#define LZSSP_GRAFM 0xD011
#define LZSSP_COLPM0 0xD012
#define LZSSP_COLPM1 0xD013
#define LZSSP_COLPM2 0xD014
#define LZSSP_NTSCPAL 0xD014
#define LZSSP_COLPM3 0xD015
#define LZSSP_COLPF0 0xD016
#define LZSSP_COLPF1 0xD017
#define LZSSP_COLPF2 0xD018
#define LZSSP_COLPF3 0xD019
#define LZSSP_COLBK 0xD01A
#define LZSSP_GPRIOR 0xD01B
#define LZSSP_GRACTL 0xD01D
#define LZSSP_POKEY 0xD200
#define LZSSP_KBCODE 0xD209
#define LZSSP_RANDOM 0xD20A
#define LZSSP_IRQEN 0xD20E
#define LZSSP_IRQST 0xD20E
#define LZSSP_SKCTL 0xD20F
#define LZSSP_SKSTAT 0xD20F
#define LZSSP_PORTA 0xD300
#define LZSSP_PORTB 0xD301
#define LZSSP_DMACTL 0xD400
#define LZSSP_CHACTL 0xD401
#define LZSSP_DLISTL 0xD402
#define LZSSP_DLISTH 0xD403
#define LZSSP_HSCROL 0xD404
#define LZSSP_VSCROL 0xD405
#define LZSSP_PMBASE 0xD407
#define LZSSP_CHBASE 0xD409
#define LZSSP_WSYNC 0xD40A
#define LZSSP_VCOUNT 0xD40B
#define LZSSP_NMIEN 0xD40E
#define LZSSP_NMIST 0xD40F
#define LZSSP_NMIRES 0xD40F
#define LZSSP_NMI 0xFFFA
#define LZSSP_RESET 0xFFFC
#define LZSSP_IRQ 0xFFFE
#define LZSSP_LMS 0x0040
#define LZSSP_HS 0x0010
#define LZSSP_MODE4 0x0004
#define LZSSP_MODED 0x000D
#define LZSSP_MODEE 0x000E
#define LZSSP_MODEF 0x000F
#define LZSSP_BLANK8 0x0070
#define LZSSP_DLI 0x0080
#define LZSSP_DLIJUMP 0x0041
#define LZSSP_DL_JUMP 0x0001
#define LZSSP_PFSIZE_DISABLED 0x0000
#define LZSSP_PFSIZE_NARROW 0x0001
#define LZSSP_PFSIZE_NORMAL 0x0002
#define LZSSP_PFSIZE_WIDE 0x0003
#define LZSSP_GRACTL_PDMA 0x0002
#define LZSSP_GRACTL_MDMA 0x0001
#define LZSSP_ZPLZS 0x0080
#define LZSSP_ZPLZS_TMP 0x0080
#define LZSSP_ZPLZS_TMP0 0x0080
#define LZSSP_ZPLZS_TMP1 0x0081
#define LZSSP_ZPLZS_TMP2 0x0082
#define LZSSP_ZPLZS_TMP3 0x0083
#define LZSSP_ZPLZS_BufferStart 0x0084
#define LZSSP_ZPLZS_BufferEnd 0x0086
#define LZSSP_ZPLZS_BufferPointer 0x0088
#define LZSSP_ZPLZS_BufferBitByte 0x008A
#define LZSSP_ZPLZS_BufferStatus 0x008B
#define LZSSP_ZPLZS_BufferOffset 0x008C
#define LZSSP_ZPLZS_ChannelBitByte 0x008D
#define LZSSP_ZPLZS_ChannelOffset 0x0090
#define LZSSP_ZPLZS_ChannelBuffer 0x0091
#define LZSSP_ZPLZS_ByteCount 0x0093
#define LZSSP_ZPLZS_LastOffset 0x00A5
#define LZSSP_ZPLZS_SequencePointer 0x00B7
#define LZSSP_ZPLZS_SongIndex 0x00B9
#define LZSSP_ZPLZS_SongCount 0x00BA
#define LZSSP_ZPLZS_SongSpeed 0x00BB
#define LZSSP_ZPLZS_SongRegion 0x00BC
#define LZSSP_ZPLZS_SongStereo 0x00BD
#define LZSSP_ZPLZS_SongSequence 0x00BE
#define LZSSP_ZPLZS_SongSection 0x00BF
#define LZSSP_ZPLZS_LoopCount 0x00C0
#define LZSSP_ZPLZS_FadingOut 0x00C1
#define LZSSP_ZPLZS_StopOnFadeout 0x00C2
#define LZSSP_ZPLZS_PlayerStatus 0x00C3
#define LZSSP_ZPLZS_VolumeMask 0x00C4
#define LZSSP_ZPLZS_VolumeLevel 0x00C5
#define LZSSP_ZPLZS_MachineStereo 0x00CD
#define LZSSP_ZPLZS_MachineRegion 0x00CE
#define LZSSP_ZPLZS_AdjustSpeed 0x00CF
#define LZSSP_ZPLZS_GlobalTimer 0x00D0
#define LZSSP_ZPLZS_TimerOffset 0x00D1
#define LZSSP_ZPLZS_Frames 0x00D2
#define LZSSP_ZPLZS_Seconds 0x00D3
#define LZSSP_ZPLZS_Minutes 0x00D4
#define LZSSP_ZPLZS_SyncStatus 0x00D5
#define LZSSP_ZPLZS_LastCount 0x00D6
#define LZSSP_ZPLZS_SyncCount 0x00D7
#define LZSSP_ZPLZS_SyncOffset 0x00D8
#define LZSSP_ZPLZS_SyncDelta 0x00D9
#define LZSSP_ZPLZS_SyncDivision 0x00DA
#define LZSSP_ZPLZS_RasterbarToggle 0x00DB
#define LZSSP_ZPLZS_RasterbarColour 0x00DC
#define LZSSP_ZPLZS_LastKeyPressed 0x00DD
#define LZSSP_ZPLZS_PlayerMenuIndex 0x00DE
#define LZSSP_ZPLZS_DMAToggle 0x00DF
#define LZSSP_ZPLZS_ProgramStatus 0x00E0
#define LZSSP_ZPLZS_StackPointer 0x00E1
#define LZSSP_ZPLZS_MemBank 0x00E2
#define LZSSP_POKSKC 0x00E3
#define LZSSP_SDWPOK 0x00E5
#define LZSSP_SDWPOK0 0x00E5
#define LZSSP_SDWPOK0_POKF0 0x00E5
#define LZSSP_SDWPOK0_POKC0 0x00E6
#define LZSSP_SDWPOK0_POKF1 0x00E7
#define LZSSP_SDWPOK0_POKC1 0x00E8
#define LZSSP_SDWPOK0_POKF2 0x00E9
#define LZSSP_SDWPOK0_POKC2 0x00EA
#define LZSSP_SDWPOK0_POKF3 0x00EB
#define LZSSP_SDWPOK0_POKC3 0x00EC
#define LZSSP_SDWPOK0_POKCTL 0x00ED
#define LZSSP_SDWPOK1 0x00EE
#define LZSSP_SDWPOK1_POKF0 0x00EE
#define LZSSP_SDWPOK1_POKC0 0x00EF
#define LZSSP_SDWPOK1_POKF1 0x00F0
#define LZSSP_SDWPOK1_POKC1 0x00F1
#define LZSSP_SDWPOK1_POKF2 0x00F2
#define LZSSP_SDWPOK1_POKC2 0x00F3
#define LZSSP_SDWPOK1_POKF3 0x00F4
#define LZSSP_SDWPOK1_POKC3 0x00F5
#define LZSSP_SDWPOK1_POKCTL 0x00F6
#define LZSSP_bar_counter 0x00F7
#define LZSSP_bar_increment 0x00FA
#define LZSSP_bar_loop 0x00FD
#define LZSSP_DISPLAY 0x00FE
#define LZSSP_ZPVOL 0x0100
#define LZSSP_ZPVOL_Buffer 0x0100
#define LZSSP_ZPVOL_Colour 0x0120
#define LZSSP_VUFONT 0x0400
#define LZSSP_VUDATA 0x0800
#define LZSSP_line_0 0x0800
#define LZSSP_line_1 0x0828
#define LZSSP_line_2 0x0850
#define LZSSP_line_3 0x0878
#define LZSSP_line_4 0x08A0
#define LZSSP_line_5 0x08C8
#define LZSSP_line_6 0x08F0
#define LZSSP_mode_6 0x0918
#define LZSSP_mode_6a 0x0940
#define LZSSP_mode_6b 0x0968
#define LZSSP_mode_6c 0x0990
#define LZSSP_POKE1 0x09B8
#define LZSSP_POKE2 0x09E0
#define LZSSP_POKE3 0x0A08
#define LZSSP_POKE4 0x0A30
#define LZSSP_mode_2d 0x0A58
#define LZSSP_line_0a 0x0A80
#define LZSSP_line_0b 0x0AA8
#define LZSSP_line_0c 0x0AD0
#define LZSSP_line_0d 0x0AF8
#define LZSSP_line_0e 0x0B20
#define LZSSP_subtpos 0x0B28
#define LZSSP_subtall 0x0B2B
#define LZSSP_line_0e1 0x0B30
#define LZSSP_b_handler 0x0B39
#define LZSSP_b_seekr 0x0B39
#define LZSSP_b_fastr 0x0B3B
#define LZSSP_b_play 0x0B3D
#define LZSSP_b_fastf 0x0B3F
#define LZSSP_b_seekf 0x0B41
#define LZSSP_b_stop 0x0B43
#define LZSSP_b_eject 0x0B45
#define LZSSP_line_0f 0x0B48
#define LZSSP_dlist 0x0B70
#define LZSSP_mode6_toggle 0x0B7B
#define LZSSP_mode2_0 0x0B84
#define LZSSP_mode2_toggle 0x0B85
#define LZSSP_mode2_1 0x0B87
#define LZSSP_txt_toggle 0x0B95
#define LZSSP_VUMeterColours 0x0BA0
#define LZSSP_txt_REGION 0x0BA8
#define LZSSP_txt_PAL 0x0BA8
#define LZSSP_txt_NTSC 0x0BAC
#define LZSSP_txt_VBI 0x0BB0
#define LZSSP_txt_STEREO 0x0BB4
#define LZSSP_txt_PLAY 0x0BC4
#define LZSSP_txt_PAUSE 0x0BCC
#define LZSSP_txt_STOP 0x0BD4
#define LZSSP_VUPLAYER 0x0BDC
#define LZSSP_Start 0x0BDC
#define LZSSP_ResetLoop 0x0C97
#define LZSSP_ResetLoop_a 0x0CA0
#define LZSSP_MainLoop 0x0CAF
#define LZSSP_dlicoltbl 0x0CDA
#define LZSSP_enemi 0x0CE9
#define LZSSP_deli 0x0CF6
#define LZSSP_deli_a 0x0D22
#define LZSSP_deli_b 0x0D40
#define LZSSP_deli_c 0x0D5E
#define LZSSP_deli_d 0x0D7A
#define LZSSP_vbi 0x0D93
#define LZSSP_vbi_a 0x0D9C
#define LZSSP_vbi_b 0x0DA8
#define LZSSP_vbi_c 0x0DB6
#define LZSSP_vbi_d 0x0DBC
#define LZSSP_vbi_e 0x0DC7
#define LZSSP_vbi_f 0x0DCD
#define LZSSP_vbi_g 0x0DD1
#define LZSSP_vbi_h 0x0DE3
#define LZSSP_vbi_i 0x0DF1
#define LZSSP_endnmi 0x0DF6
#define LZSSP_WaitForVBlank 0x0DFC
#define LZSSP_WaitForSomeTime 0x0E04
#define LZSSP_WaitForSync 0x0E11
#define LZSSP_WaitForScanline 0x0E19
#define LZSSP_SetPlaybackSpeed 0x0E48
#define LZSSP_printinfo 0x0EB1
#define LZSSP_do_printinfo 0x0EB6
#define LZSSP_infosrc 0x0EB7
#define LZSSP_charbuffer 0x0EBE
#define LZSSP_printhex 0x0EC2
#define LZSSP_printhex_direct 0x0EC4
#define LZSSP_ph1 0x0ECD
#define LZSSP_hexchars 0x0EDA
#define LZSSP_hex2dec_convert 0x0EEA
#define LZSSP_hex2dec_convert_a 0x0EF2
#define LZSSP_hex2dec_loop 0x0F00
#define LZSSP_hex2dec_convert_b 0x0F1C
#define LZSSP_dec_num 0x0F1D
#define LZSSP_hex_num 0x0F1F
#define LZSSP_set_play_pause_stop_button 0x0F20
#define LZSSP_stop_button_toggle 0x0F2A
#define LZSSP_pause_button_toggle 0x0F2E
#define LZSSP_play_button_toggle 0x0F30
#define LZSSP_play_button_toggle_a 0x0F4F
#define LZSSP_set_subtune_count 0x0F53
#define LZSSP_current_subtune 0x0F57
#define LZSSP_set_subtune_count_done 0x0F78
#define LZSSP_do_button_selection 0x0F79
#define LZSSP_HandleKeyboard 0x0F7A
#define LZSSP_UpdateVolumeLevel 0x10F0
#define LZSSP_CheckForShiftAndCtrlPressed 0x1116
#define LZSSP_TableJump 0x1121
#define LZSSP_DoNothing 0x1133
#define LZSSP_FrameAdvance 0x1134
#define LZSSP_seek_reverse 0x1180
#define LZSSP_seek_wraparound 0x1185
#define LZSSP_seek_forward 0x118A
#define LZSSP_seek_done 0x1193
#define LZSSP_dec_index_selection 0x1198
#define LZSSP_inc_index_selection 0x1198
#define LZSSP_fast_reverse 0x1199
#define LZSSP_fast_forward 0x11A0
#define LZSSP_fast_reverse2 0x11A7
#define LZSSP_fast_forward2 0x11AE
#define LZSSP_fast_reverse3 0x11B5
#define LZSSP_fast_forward3 0x11B8
#define LZSSP_set_speed_up 0x11BB
#define LZSSP_set_speed_down 0x11C6
#define LZSSP_set_speed_next 0x11CD
#define LZSSP_toggle_vumeter 0x11D2
#define LZSSP_vumeter_toggle 0x11D3
#define LZSSP_set_vumeter_view 0x11DB
#define LZSSP_set_register_view 0x11E9
#define LZSSP_set_view_addresses 0x11F5
#define LZSSP_set_view_addresses_loop 0x11FC
#define LZSSP_toggle_rasterbar 0x1203
#define LZSSP_toggle_loop 0x120A
#define LZSSP_toggle_pokey_mode 0x1211
#define LZSSP_toggle_dli 0x121B
#define LZSSP_dli_toggler 0x121C
#define LZSSP_ReturnToDOS 0x1226
#define LZSSP_set_highlight 0x1241
#define LZSSP_set_highlight_a 0x1243
#define LZSSP_set_highlight_b 0x1250
#define LZSSP_set_highlight_c 0x1253
#define LZSSP_PrintSongInfos 0x1260
#define LZSSP_print_player_infos 0x12A7
#define LZSSP_print_minutes 0x12AF
#define LZSSP_print_seconds 0x12B9
#define LZSSP_no_blink 0x12C4
#define LZSSP_blink 0x12C6
#define LZSSP_print_loop 0x12DC
#define LZSSP_yes_loop 0x12E6
#define LZSSP_no_loop 0x12E8
#define LZSSP_Print_pointers 0x12EA
#define LZSSP_printvolumemaskloop1 0x1369
#define LZSSP_printvolumemaskloop2 0x1379
#define LZSSP_test_vumeter_toggle 0x1386
#define LZSSP_do_draw_registers 0x138B
#define LZSSP_do_begindraw 0x138E
#define LZSSP_draw_registers 0x1391
#define LZSSP_draw_left_pokey 0x139D
#define LZSSP_reload_x_left 0x13A9
#define LZSSP_draw_left_pokey_next 0x13BA
#define LZSSP_draw_right_pokey 0x13CC
#define LZSSP_reload_x_right 0x13D8
#define LZSSP_draw_right_pokey_next 0x13E9
#define LZSSP_draw_registers_done 0x13F7
#define LZSSP_begindraw 0x13F8
#define LZSSP_begindraw_a 0x13FC
#define LZSSP_begindraw_b 0x13FE
#define LZSSP_begindraw_c 0x1417
#define LZSSP_begindraw_d 0x1430
#define LZSSP_drawloop 0x1434
#define LZSSP_drawloop_a 0x1434
#define LZSSP_drawloop_b 0x1436
#define LZSSP_drawloop_c 0x143E
#define LZSSP_drawloop_d 0x1456
#define LZSSP_drawloop_done 0x1459
#define LZSSP_vol_0 0x0046
#define LZSSP_vol_1 0x0047
#define LZSSP_vol_2 0x0048
#define LZSSP_vol_3 0x0049
#define LZSSP_vol_4 0x004A
#define LZSSP_vol_5 0x004B
#define LZSSP_vol_6 0x004C
#define LZSSP_vol_7 0x004D
#define LZSSP_vol_8 0x004E
#define LZSSP_vol_tbl_0 0x145A
#define LZSSP_vol_tbl_1 0x1462
#define LZSSP_vol_tbl_2 0x146A
#define LZSSP_vol_tbl_3 0x1472
#define LZSSP_bar_cur 0x0054
#define LZSSP_bar_lne 0x005C
#define LZSSP_set_progress_bar 0x1492
#define LZSSP_set_progress_bar_done 0x14A9
#define LZSSP_draw_progress_bar 0x14AA
#define LZSSP_draw_progress_bar_a 0x14C4
#define LZSSP_draw_progress_bar_loop1 0x14CB
#define LZSSP_draw_progress_bar_below_8 0x14D0
#define LZSSP_draw_empty_bar_count 0x14D5
#define LZSSP_draw_progress_bar_loop2 0x14DC
#define LZSSP_draw_progress_bar_done 0x14E2
#define LZSSP_PLAYLZ16 0x14E3
#define LZSSP_LZSSPlayFrame 0x14E3
#define LZSSP_SetNewSongPtrsFull 0x158B
#define LZSSP_SetNewSongPtrs 0x15DD
#define LZSSP_SetNewSongPtrs_a 0x15F1
#define LZSSP_SetNewSongPtrs_b 0x15F7
#define LZSSP_SetNewSongPtrs_c 0x160F
#define LZSSP_SetNewSongPtrs_d 0x1620
#define LZSSP_SetNewSongPtrsDone 0x162C
#define LZSSP_UpdateVolumeFadeout 0x162D
#define LZSSP_stop_toggle 0x1641
#define LZSSP_set_stop 0x1646
#define LZSSP_stop_pause_reset 0x164D
#define LZSSP_stop_pause_reset_a 0x1657
#define LZSSP_setpokeyfull 0x165F
#define LZSSP_setpokeyfullstereo 0x1695
#define LZSSP_setpokeyfulldone 0x16C7
#define LZSSP_play_pause_toggle 0x16C8
#define LZSSP_set_pause 0x16CE
#define LZSSP_set_play_from_a_stop 0x16D3
#define LZSSP_set_play_from_a_stop_a 0x16D5
#define LZSSP_set_play_from_a_stop_b 0x1704
#define LZSSP_set_play 0x1706
#define LZSSP_trigger_fade_immediate 0x170B
#define LZSSP_trigger_fade_done 0x1711
#define LZSSP_CalculateTime 0x1712
#define LZSSP_ResetTimer 0x172D
#define LZSSP_CheckForTwoToneBit 0x1738
#define LZSSP_SwapBufferCopy 0x1769
#define LZSSP_SetVolumeLevel 0x177F
#define LZSSP_DetectMachineRegion 0x17EA
#define LZSSP_DetectStereoMode 0x17FB
#define LZSSP_SetStereoMode 0x1822
#define LZSSP_INVALID 0xFFFFFFFF
#define LZSSP_TRUE 0x0001
#define LZSSP_FALSE 0x0000
#define LZSSP_NULL 0x0000
#define LZSSP_SongIndex 0x2000
#define LZSSP_SongCount 0x2001
#define LZSSP_RasterbarToggle 0x2002
#define LZSSP_RasterbarColour 0x2003
#define LZSSP_SectionTable 0x2004
#define LZSSP_SongTable 0x2006
#define LZSSP_SongTableEnd 0x2036
#define LZSSP_SongSequence 0x2036
#define LZSSP_SEQ_02 0x2036
#define LZSSP_SEQ_05 0x2039
#define LZSSP_SEQ_0A 0x203B
#define LZSSP_SEQ_15 0x203D
#define LZSSP_SEQ_21 0x2040
#define LZSSP_SEQ_22 0x2043
#define LZSSP_SongSequenceEnd 0x2045
#define LZSSP_SongSection 0x2045
#define LZSSP_SongSectionEnd 0x2059
#define LZSSP_SongData 0x2059
#define LZSSP_LZ_30 0x2059
#define LZSSP_LZ_31 0x22A9
#define LZSSP_LZ_60 0x3C5C
#define LZSSP_LZ_B0 0x4967
#define LZSSP_LZ_M0 0x522A
#define LZSSP_LZ_M1 0x59A8
#define LZSSP_LZ_X0 0x668A
#define LZSSP_LZ_X1 0x70CD
#define LZSSP_LZ_Y0 0x8B0B
#define LZSSP_SongDataEnd 0xA98D

#endif

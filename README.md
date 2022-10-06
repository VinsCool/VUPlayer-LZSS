# VUPlayer-LZSS
A crappy music player for the Atari 8-bit, powered by rensoupp's unrolled LZSS driver

# How to embed the player into RMT
## tl;dr;
Run the `build_VUPlayer (LZSS Export)_obx.cmd` script and it will produce output in the `out` folder.

## Details
```
1 @echo off
2 if not exist out\ (mkdir out)
3 mads -hc:out/lzssp.h lzssp.asm -o:out/temp.out.obx 
4 .\bin\splitxex.exe out/temp.out.obx #1 #2 #3 "out/VUPlayer (LZSS Export).obx"
5 if exist "out\temp.out.obx" (del "out\temp.out.obx")
```

- Line 1 tells the script runner not to show the commands that it is executing
- Line 2 makes sure that the `out` folder is created
- Line 3 calls the MADS tool to assemble the VUPlayer and create a C header file and the program code in the `out` folder.
- Line 4 uses the SplitXex tool to extract the first three code sections of the assembled program and creates the `VUPlayer (LZSS Export).obx` file to be used my RMT.
- Line 5 removed the assembler output again

## Tools used
SplitXex - https://github.com/CycoPH/SplitXex
Mads - https://github.com/tebe6502/Mad-Assembler


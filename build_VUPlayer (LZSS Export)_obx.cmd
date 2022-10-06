@echo off
if not exist out\ (mkdir out)
.\bin\mads.exe -hc:out/lzssp.h lzssp.asm -o:out/temp.out.obx 
.\bin\splitxex.exe out/temp.out.obx #1 #2 #3 "out/VUPlayer (LZSS Export).obx"
if exist "out\temp.out.obx" (del "out\temp.out.obx")
pause
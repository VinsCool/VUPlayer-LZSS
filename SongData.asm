;* Intro subtunes index, this is the first part of a tune that will play before a loop
;* If the intro and loop are identical, or close enough to sound seamless, the intro could be replaced by a dummy to save space
;* IMPORTANT: due to technical reasons, every indexes MUST end with a dummy subtune! Otherwise the entire thing will break apart!

S_Id_0
	ins     '/RANDOM3/01 - SKETCH_71_TUNE_1.lzss'

S_Id_1
	ins     'DUMMY.lzss'

S_Id_2
	ins     'DUMMY.lzss'

S_Id_3
	ins 	'/RANDOM3/04 - SKETCH_73.lzss'

;----------------------	

S_DUMMY
	ins	'DUMMY.lzss' 

;----------------------

;* Looped subtunes index, if a dummy is inserted, the tune has a definite end and won't loop and/or fadeout!

L_Id_0
	ins	'/RANDOM3/01 - SKETCH_71_TUNE_1_LOOP.lzss'	

L_Id_1
	ins     '/RANDOM3/02 - SKETCH_71_TUNE_2_LOOP.lzss'

L_Id_2
	ins     '/RANDOM3/03 - SKETCH_72_LOOP.lzss'

L_Id_3
	ins 	'/RANDOM3/04 - SKETCH_73_LOOP.lzss'
	
;----------------------	

L_DUMMY
	ins	'DUMMY.lzss' 

;----------------------

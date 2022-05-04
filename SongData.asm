;* Intro subtunes index, this is the first part of a tune that will play before a loop
;* If the intro and loop are identical, or close enough to sound seamless, the intro could be replaced by a dummy to save space
;* IMPORTANT: due to technical reasons, every indexes MUST end with a dummy subtune! Otherwise the entire thing will break apart!

S_Id_0
;	ins     '/RANDOM/BOUNCY_BOUNCER.lzss'
	
S_Id_1
;	ins     'DUMMY.lzss'
	
S_Id_2
;	ins     'DUMMY.lzss'	; MUSICIO
	
S_Id_3
	ins     '/RANDOM/SHORELINE.lzss'

S_Id_4
	ins     '/RANDOM/SIEUR_GOUPIL.lzss'
	
S_Id_5
	ins     'DUMMY.lzss'	; SKETCH_24
	
S_Id_6
	ins     '/RANDOM/SKETCH_53.lzss'
	
S_Id_7
	ins     'DUMMY.lzss'	; SKETCH_58
	
S_Id_8
;	ins     '/RANDOM/SKETCH_66.lzss'
	
S_Id_9
	ins     'DUMMY.lzss'	; SKETCH_69  

;----------------------	

S_DUMMY
	ins	'DUMMY.lzss' 

;----------------------

;* Looped subtunes index, if a dummy is inserted, the tune has a definite end and won't loop and/or fadeout!

L_Id_0
;	ins     '/RANDOM/BOUNCY_BOUNCER_LOOP.lzss'
	
L_Id_1
;	ins     '/RANDOM/DUMB3_LOOP.lzss'
	
L_Id_2
;	ins     '/RANDOM/MUSICIO_LOOP.lzss'	; MUSICIO
	
L_Id_3
	ins     '/RANDOM/SHORELINE_LOOP.lzss'

L_Id_4
	ins     '/RANDOM/SIEUR_GOUPIL_LOOP.lzss'
	
L_Id_5
	ins     '/RANDOM/SKETCH_24_LOOP.lzss'	; SKETCH_24
	
L_Id_6
	ins     '/RANDOM/SKETCH_53_LOOP.lzss'
	
L_Id_7
	ins     '/RANDOM/SKETCH_58_LOOP.lzss'	; SKETCH_58
	
L_Id_8
;	ins     '/RANDOM/SKETCH_66_LOOP.lzss'
	
L_Id_9
	ins     '/RANDOM/SKETCH_69_LOOP.lzss'	; SKETCH_69
	
;----------------------	

L_DUMMY
	ins	'DUMMY.lzss' 

;----------------------

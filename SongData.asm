;* Intro subtunes index, this is the first part of a tune that will play before a loop
;* If the intro and loop are identical, or close enough to sound seamless, the intro could be replaced by a dummy to save space
;* IMPORTANT: due to technical reasons, every indexes MUST end with a dummy subtune! Otherwise the entire thing will break apart!

S_Id_0
	ins	'DUMMY.lzss'

;----------------------	

S_DUMMY
	ins	'DUMMY.lzss' 

;----------------------

;* Looped subtunes index, if a dummy is inserted, the tune has a definite end and won't loop and/or fadeout!

L_Id_0
	;ins	'/RetroCoder/lzss.new.lzss' 
	ins 'DUMMY.lzss'
	
;----------------------	

L_DUMMY
	ins	'DUMMY.lzss' 

;----------------------

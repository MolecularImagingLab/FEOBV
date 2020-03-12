#! /bin/bash

parentdir="$(dirname "$SUBJECTS_DIR")"
adir=${parentdir}/mkanalysis/
analyses='wm.lh wm.rh wm.mni' 
for space in $analyses; 
do 
	
	mkcontrast-sess -an ${adir}${space} -co zeroone -c 1 -a 2 &
	mkcontrast-sess -an ${adir}${space} -co zerotwo -c 1 -a 3 &
	mkcontrast-sess -an ${adir}${space} -co onetwo -c 2 -a 3 &

done


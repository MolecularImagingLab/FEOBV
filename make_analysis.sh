#! /bin/bash

parentdir="$(dirname "$SUBJECTS_DIR")"

mkanalysis-sess -a ${parentdir}/mkanalysis/wm.lh -fsd bold -surface fsaverage lh -fwhm 5 -event-related -TR 2.3 -nc 3 -polyfit 2 -spmhrf 0 -refeventdur 48 -per-run -nskip 0 -p wm.par -force 

mkanalysis-sess -a ${parentdir}/mkanalysis/wm.rh -fsd bold -surface fsaverage rh -fwhm 5 -event-related -TR 2.3 -nc 3 -polyfit 2 -spmhrf 0 -refeventdur 48 -per-run -nskip 0 -p wm.par -force 

mkanalysis-sess -a ${parentdir}/mkanalysis/wm.mni -fsd bold -mni305 -fwhm 5 -event-related -TR 2.3 -nc 3 -polyfit 2 -spmhrf 0 -refeventdur 48 -per-run -nskip 0 -p wm.par -force 


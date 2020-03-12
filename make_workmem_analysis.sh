#! /bin/bash

## define variables 
subj=$1
parentdir="$(dirname "$SUBJECTS_DIR")"
bdir=${parentdir}/subjects/${subj}/bold/

	## verify if $SUBJECTS_DIR is set
if [ -z "$SUBJECTS_DIR" ]
	then
	echo "---------------------------------------------------------------------------------------------------------
ERROR:
\$SUBJECTS_DIR is not set. Please set \$SUBJECTS_DIR before proceeding.
---------------------------------------------------------------------------------------------------------"
	exit 1

	## verify if subject ID was supplied as argument
elif [ -z ${subj} ] 
then 
	echo "---------------------------------------------------------------------------------------------------------
ERROR: No argument was supplied. The subject ID (e.g., 'FEOBV000') should be supplied as the first argument.
Example:  './make_workmem_analysis FEOBV000'
---------------------------------------------------------------------------------------------------------"
	exit 2

elif [ -z $(ls -d ${parentdir}/subjects/*/ | grep /subjects/${subj}/) ] ; then 
	echo "----------------------------------------------------------------------------------------------------------------
ERROR:  
The subject '${subj}' does not exist (or \$SUBJECTS_DIR was not properly defined). 
Please enter a valid subject ID as the first argument, e.g., 'FEOBV000'. 
Subject must have data in /group/tuominen/FEOBV/subjects/{subject-ID}/
Valid subjects include:
$(basename -a ls -d ${parentdir}/subjects/*/ | grep FEOBV*)

\$SUBJECTS_DIR is currently defined as   ${SUBJECTS_DIR}
If it is incorrectly set, please re-define it before proceeding.
----------------------------------------------------------------------------------------------------------------"
	exit 3

elif [ ! -f ${bdir}/001/f.nii ] || [ ! -f ${bdir}/002/f.nii ] || [ ! -f ${bdir}/003/f.nii ]
	then echo "---------------------------------------------------------------------------------------------------------
ERROR:
One or more of the fMRI Working Memory Task Data files are missing from the subject's '/bold/' sub-folder(s). 
Please ensure that the following file have been converted/saved before proceeding:

/group/tuominen/FEOBV/subjects/${subj}/pet/001/f.nii
/group/tuominen/FEOBV/subjects/${subj}/pet/002/f.nii
/group/tuominen/FEOBV/subjects/${subj}/pet/003/f.nii
---------------------------------------------------------------------------------------------------------"
	exit 4

else 
	echo "----------------------------------------------------------------------------------------------------------------
Project:    $(basename ${parentdir})
Subject:    ${subj}
Data type:  fMRI Working Memory Task 

	Analyses now running for ${subj}...
" 
fi

####### preproc #############
## recon
if [ -z "$(cat ${SUBJECTS_DIR}/${subj}_fmri/scripts/recon-all-status.log | grep 'finished without error')" ] ; then
	if [ -e ${SUBJECTS_DIR}/${subj}_fmri/mri/orig.mgz ]; then
		echo "RECON-ALL of fMRI data was previously started for ${subj} but did not complete without error. Proceeding with RECON-ALL."
		recon-all -s ${subj}_fmri -all -parallel -no-isrunning
		else 
		echo "RECON-ALL of fMRI data was never done for ${subj}. Proceeding with RECON-ALL."
		recon-all -i ${parentdir}/subjects/${subj}/anat/fmri_T1/T1.nii -s ${subj}_pet -all -parallel
	fi
else 
	echo "
RECON-ALL of fMRI data is complete for ${subj}.
"
fi

echo ${subj}_fmri > ${parentdir}/subjects/${subj}/subjectname

preproc-sess -s ${subj} -per-run -nostc -fwhm 5 -surface fsaverage lhrh -mni305-2mm -fsd bold -d ${parentdir}/subjects/ -force

## do motion qc for fMRI 
runs=$(ls -d $bdir/*/ | grep /0)
for r in $runs; do
d=$(basename ${r}) 
	fsl_motion_outliers -i ${r}/f.nii -o ${r}/fd -s ${r}/fd_metric -p ${parentdir}/subjects/${subj}/qc/fd_plot.wmfMRI.$d --fd &
done

## 1st level analysis 
analyses='wm.lh wm.rh wm.mni' 
cd ${parentdir}/mkanalysis

for space in $analyses; do 
	selxavg3-sess -s $subj -d ${parentdir}/subjects -analysis $space -force &
done
cd ${parentdir}/scripts



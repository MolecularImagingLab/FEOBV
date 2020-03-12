#! /bin/bash

## define variables 
subj=$1
parentdir="$(dirname "$SUBJECTS_DIR")"
pdir=${parentdir}/subjects/${subj}/pet/001/

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
Example:  './make_bpet_analysis FEOBV000'
---------------------------------------------------------------------------------------------------------"
	exit 2

elif [ -z $(ls -d ${parentdir}/subjects/*/ | grep /subjects/${subj}/) ] ; then 
	echo "----------------------------------------------------------------------------------------------------------------
ERROR:  
The subject '${subj}' does not exist (or \$SUBJECTS_DIR was not properly defined). 
Please enter a valid subject ID as the first argument, e.g., 'FEOBV000'. Subject must have data in /group/tuominen/FEOBV/subjects/{subject-ID}/
Valid subjects include:
$(basename -a ls -d ${parentdir}/subjects/*/ | grep FEOBV*)

\$SUBJECTS_DIR is currently defined as   ${SUBJECTS_DIR}
If it is incorrectly set, please re-define it before proceeding.
----------------------------------------------------------------------------------------------------------------"
	exit 3

elif [ ! -f ${pdir}p.nii ]
	then echo "---------------------------------------------------------------------------------------------------------
Error:
The Brain Pet Data is missing from the subject's '/pet/001/' folder. Please convert and save the following file before proceeding:
/group/tuominen/FEOBV/subjects/${subj}/pet/001/p.nii
---------------------------------------------------------------------------------------------------------"
	exit 4

## make sure the data is dynamic
elif [ $(mri_info ${pdir}p.nii --nframes) != 6 ]; then
	echo "---------------------------------------------------------------------------------------------------------"
	echo ""
	echo "Error: The file for ${subj} does not contain 6 frames (time points). Please use dynamic data."
	echo ""
	echo "*NON-ZERO EXIT*"	
	echo "---------------------------------------------------------------------------------------------------------"	

	echo "Error: The ${pdir}p.nii for ${subj} does not contain 6 frames (time points). Please download and use dynamic data." >> ${pdir}${subj}.bpet.roi.suv.calc.error.log
		exit 5
else 
	echo "----------------------------------------------------------------------------------------------------------------
Project:    $(basename ${parentdir})
Subject:    ${subj}
Data type:  Brain PET 

	Analyses now running for ${subj}...
" 
fi

####### preproc #############
## recon
if [ -z "$(cat ${SUBJECTS_DIR}/${subj}_pet/scripts/recon-all-status.log | grep 'finished without error')" ] ; then
	if [ -e ${SUBJECTS_DIR}/${subj}_pet/mri/orig.mgz ]; then
		echo "RECON-ALL of PET data was previously started for ${subj} but did not complete without error. Proceeding with RECON-ALL."
		recon-all -s ${subj}_pet -all -parallel -no-isrunning
		else 
		echo "RECON-ALL of PET data was never done for ${subj}. Proceeding with RECON-ALL."
		recon-all -i ${parentdir}/subjects/${subj}/anat/pet_T1/T1.nii -s ${subj}_pet -all -parallel
	fi
else echo "RECON-ALL of PET data was already done for ${subj}."
fi

## motion correction
echo "---------------------------------------------------------------------------------------------------------------- 
Proceeding with Motion Correction of Brain PET data for ${subj}.
----------------------------------------------------------------------------------------------------------------"
mcflirt -in ${pdir}p.nii -meanvol -out ${pdir}mc_p.nii

## motion outliers for qc
fsl_motion_outliers -i ${pdir}/p.nii -o ${pdir}/fd -s ${pdir}/fd_metric -p ${parentdir}/subjects/${subj}/qc/${subj}_fd_plot.bpet.png --fd

## sum all pet frames 
mri_concat ${pdir}mc_p.nii.gz --sum --o ${pdir}sum_mc_p.nii.gz

## calculate coregister reg with MRI 
mri_coreg --s ${subj}_pet --mov ${pdir}sum_mc_p.nii.gz --reg ${pdir}template.reg.lta

####### calculate SUVR #############
## move to anatomical to get mean white matter values 
mri_vol2vol --reg ${pdir}template.reg.lta --mov ${pdir}sum_mc_p.nii.gz --fstarg --o ${pdir}p-in-anat.nii.gz

## create white matter mask
mri_convert ${SUBJECTS_DIR}/${subj}_pet/mri/wm.mgz ${pdir}wm.nii.gz
fslmaths ${pdir}wm.nii.gz -thr 110 -uthr 110 -bin ${pdir}wm_bin.nii.gz 

## threshold PET by median activity value in the brain
mri_convert ${SUBJECTS_DIR}/${subj}_pet/mri/brainmask.mgz ${pdir}brainmask.nii.gz
fslmaths ${pdir}brainmask.nii.gz -bin ${pdir}brainmask_bin.nii.gz
fslmaths ${pdir}p-in-anat.nii.gz -mul ${pdir}brainmask_bin.nii.gz ${pdir}p-in-anat_brain.nii.gz
fslstats ${pdir}p-in-anat_brain.nii.gz -P 50 > ${pdir}cutoff 

## create a PET mask
C="$(cat ${pdir}cutoff)"  
fslmaths ${pdir}p-in-anat.nii.gz -uthr $C -bin ${pdir}p-in-anat.median_mask_bin.nii.gz 

## create a white matter mask that excludes regions where PET uptake is above the median
fslmaths ${pdir}p-in-anat.median_mask_bin.nii.gz -mul ${pdir}wm_bin.nii.gz ${pdir}wm_low_uptake.nii.gz

## get the mean activity from the white matter 
fslstats ${pdir}p-in-anat.nii.gz -k ${pdir}wm_low_uptake.nii.gz -M > ${pdir}wm_mean_activity

## divide p-in-anat (for ROIs) sum_mc_p (for surf % vol based analyses) by mean white matter activity
R="$(cat ${pdir}wm_mean_activity)" 
fslmaths ${pdir}p-in-anat.nii.gz -div $R ${pdir}SUVR_anat.nii.gz
fslmaths ${pdir}sum_mc_p.nii.gz -div $R ${pdir}SUVR.nii.gz

####### calculate ROI values, normalize and smooth #############

## get ROI values 
mri_segstats --i ${pdir}SUVR_anat.nii.gz --seg $SUBJECTS_DIR/${subj}_pet/mri/aparc+aseg.mgz --sum ${pdir}${subj}.PET.summary.ROI.stats.dat --excludeid 0

## normalize to surface  
mri_vol2surf --mov ${pdir}SUVR.nii.gz --reg ${pdir}template.reg.lta --hemi lh --projfrac 0.5 --o ${pdir}lh.SUVR.fsaverage.sm00.nii.gz --cortex --trgsubject fsaverage
mri_vol2surf --mov ${pdir}SUVR.nii.gz --reg ${pdir}template.reg.lta --hemi rh --projfrac 0.5 --o ${pdir}rh.SUVR.fsaverage.sm00.nii.gz --cortex --trgsubject fsaverage 

## smooth surface 
mris_fwhm --smooth-only --i ${pdir}lh.SUVR.fsaverage.sm00.nii.gz --fwhm 5 --o ${pdir}lh.SUVR.fsaverage.sm05.nii.gz --cortex --s fsaverage --hemi lh
mris_fwhm --smooth-only --i ${pdir}rh.SUVR.fsaverage.sm00.nii.gz --fwhm 5 --o ${pdir}rh.SUVR.fsaverage.sm05.nii.gz --cortex --s fsaverage --hemi rh

## normalize to MNI152
mni152reg --s ${subj}_pet #--o ${pdir}mni152reg.log
mri_vol2vol --mov ${pdir}/SUVR.nii.gz --reg ${pdir}template.reg.lta --mni152reg --talres 2  --o ${pdir}mni152.SUVR.2mm.sm00.nii.gz

## normalize to mni305
#mri_vol2vol --mov ${pdir}/SUVR.nii.gz --reg ${pdir}template.reg.lta --talreg --talres 2 --o ${pdir}mni305.SUVR.2mm.sm00.nii.gz


#################### QC: SUVs from each frame graph #######################
## move to anatomical to get mean white matter values 
mri_vol2vol --reg ${pdir}template.reg.lta --mov ${pdir}/mc_p.nii.gz --fstarg --o ${pdir}mc_4d_p-in-anat.nii.gz
## verification
if [ ! -f ${pdir}mc_4d_p-in-anat.nii.gz ] ; then
	echo "Error: ${pdir}mc_4d_p-in-anat.nii.gz could not be created. Kindly review the output above."
	echo "Error: ${pdir}mc_4d_p-in-anat.nii.gz could not be created. 
	"`date`"" >> ${pdir}${subj}.bpet.roi.suv.calc.error.log
	exit 5
elif [ -z $(find ${pdir}mc_4d_p-in-anat.nii.gz -mmin -1) ]; then 
	echo "Error: ${pdir}mc_4d_p-in-anat.nii.gz was previously created, and it seems it was not overwritten by the current process. It was created on $(stat -c %y ${pdir}mc_4d_p-in-anat.nii.gz). Please review the output above as there may have been an error."
	echo "Error: ${pdir}mc_4d_p-in-anat.nii.gz was previously created, and it seems it was not overwritten by the current process. It was created on $(stat -c %y ${pdir}mc_4d_p-in-anat.nii.gz). Please review the output above as there may have been an error.
	"`date`"" >> ${pdir}${subj}.bpet.roi.suv.calc.error.log
	exit 5
else 
	echo "The motion corrected 4D Brain PET data was successfully moved to anatomical space and saved here:
	${pdir}mc_4d_p-in-anat.nii.gz
	"
fi

## get ROI values 
mri_segstats --i ${pdir}mc_4d_p-in-anat.nii.gz --seg $SUBJECTS_DIR/${subj}_pet/mri/aparc+aseg.mgz --avgwf ${pdir}${subj}.summary_mc_4d_ROI.stats.dat --excludeid 0
## verification
if [ ! -f ${pdir}${subj}.summary_mc_4d_ROI.stats.dat ] ; then
	echo "Error: ${pdir}${subj}.summary_mc_4d_ROI.stats.dat could not be created. Kindly review the output above."
	echo "Error: ${pdir}${subj}.summary_mc_4d_ROI.stats.dat could not be created. 
	"`date`"" >> ${pdir}${subj}.bpet.roi.suv.calc.error.log
	exit 6
elif [ -z $(find ${pdir}${subj}.summary_mc_4d_ROI.stats.dat -mmin -1) ]; then 
	echo "Error: ${pdir}${subj}.summary_mc_4d_ROI.stats.dat was previously created, and it seems it was not overwritten by the current process. It was created on $(stat -c %y ${pdir}mc_4d_p-in-anat.nii.gz). Please review the output above as there may have been an error."
	echo "Error: ${pdir}${subj}.summary_mc_4d_ROI.stats.dat was previously created, and it seems it was not overwritten by the current process. It was created on $(stat -c %y ${pdir}mc_4d_p-in-anat.nii.gz). Please review the output above as there may have been an error.
	"`date`"" >> ${pdir}${subj}.bpet.roi.suv.calc.error.log
	exit 6
else 
	echo "The motion corrected 4D SUVs were calculated and saved here:
	${pdir}${subj}.summary_mc_4d_ROI.stats.dat
	"
fi

## get the mean activity from the white matter 
fslstats -t ${pdir}mc_4d_p-in-anat.nii.gz -k ${pdir}wm_low_uptake.nii.gz -M > ${pdir}mc_4d_wm_mean_activity
## verification
if [ ! -f ${pdir}mc_4d_wm_mean_activity ] ; then
	echo "Error: ${pdir}mc_4d_wm_mean_activity could not be created. Kindly review the output above."
	echo "Error: ${pdir}mc_4d_wm_mean_activity could not be created. 
	"`date`"" >> ${pdir}${subj}.bpet.roi.suv.calc.error.log
	exit 7
elif [ -z $(find ${pdir}mc_4d_wm_mean_activity -mmin -1) ]; then 
	echo "Error: ${pdir}mc_4d_wm_mean_activity was previously created, and it seems it was not overwritten by the current process. It was created on $(stat -c %y ${pdir}mc_4d_p-in-anat.nii.gz). Please review the output above as there may have been an error."
	echo "Error: ${pdir}mc_4d_wm_mean_activity was previously created, and it seems it was not overwritten by the current process. It was created on $(stat -c %y ${pdir}mc_4d_p-in-anat.nii.gz). Please review the output above as there may have been an error.
	"`date`"" >> ${pdir}${subj}.bpet.roi.suv.calc.error.log
	exit 7
else 
	echo "The motion corrected 4D SUVs were calculated and saved here:
	${pdir}mc_4d_wm_mean_activity

	----------------------------------------------------------------------------------------------------------------"
fi

################################################### fix the R script below, something is changed*

##  Rscript that makes the graph
${parentdir}/scripts/combined_plot_bpet-ROI-SUV_and_motion.R ${subj}

echo ""



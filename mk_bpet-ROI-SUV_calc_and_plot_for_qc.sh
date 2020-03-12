#! /bin/bash

## define variables 
subj=$1
parentdir="$(dirname "$SUBJECTS_DIR")"
pdir=${parentdir}/subjects/${subj}/pet/001/

## Ensure that a subject ID was provided as first argument
if [ -z ${subj} ] ; then 
	echo "----------------------------------------------------------------------------------------------------------------
Error:  
No subject ID was provided. 
Please enter a valid subject ID as the first argument, e.g., 'FEOBV000'.
----------------------------------------------------------------------------------------------------------------"
	exit 1 
elif [ -z $(ls -d ${parentdir}/subjects/*/ | grep ${subj}) ] ; then 
	echo "----------------------------------------------------------------------------------------------------------------
Error:  
The subject ${1} does not exist. Please enter a valid subject ID as the first argument, e.g., 'FEOBV000'.

Valid subjects with data in /group/tuominen/FEOBV/subjects/FEOBV***/ are:
$(basename -a ${parentdir}/subjects/FEOBV*/)
----------------------------------------------------------------------------------------------------------------"
	exit 2
else 
	echo "----------------------------------------------------------------------------------------------------------------
	Proceeding with analyses for ${subj}.
	" 
fi

## make sure the data is dynamic
if [ $(mri_info ${pdir}p.nii --nframes) != 6 ]; then
	echo "Error: The file for ${subj} does not contain 6 frames (time points). Please use dynamic data."
	echo "Error: The ${pdir}p.nii for ${subj} does not contain 6 frames (time points). Please download and use dynamic data." >> ${pdir}${subj}.bpet.roi.suv.calc.error.log
	exit 4
fi

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

##  Rscript that makes the graph
${parentdir}/scripts/combined_plot_bpet-ROI-SUV_and_motion.R ${subj}






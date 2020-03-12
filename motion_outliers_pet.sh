## MOTION OUTLIERS PROCESSING HAS BEEN ADDED TO "make_bpet_analysis.sh"


## define variables 
subj=$1
parentdir="$(dirname "$SUBJECTS_DIR")"
pdir=${parentdir}/subjects/${subj}/pet/001/

## Ensure that a subject ID was provided as first argument
if [ -z $subj ] ; then 
	echo "----------------------------------------------------------------------------------------------------------------
	Error:  No subject ID was provided. 
	Please enter a valid subject ID as the first argument, e.g., 'FEOBV000'.
----------------------------------------------------------------------------------------------------------------"
	exit 1 
elif [ -z $(ls -d ${parentdir}/subjects/*/ | grep ${subj}) ] ; then 
	echo "----------------------------------------------------------------------------------------------------------------
	Error:  The subject ${subj} does not exist. 
	Please enter a valid subject ID as the first argument, e.g., 'FEOBV000'.
	Subject must have data in /group/FEOBV/subjects/{subject-id}
----------------------------------------------------------------------------------------------------------------"
	exit 2
else 
	echo "Motion Outliers Analysis is now running for ${subj}." 
fi



## motion outliers
fsl_motion_outliers -i ${pdir}/p.nii -o ${pdir}/fd -s ${pdir}/fd_metric -p ${parentdir}/subjects/${subj}/qc/${subj}_fd_plot.bpet.png --fd



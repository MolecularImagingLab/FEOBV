subj=$1
parentdir="$(dirname "$SUBJECTS_DIR")"
recon-all -i ${parentdir}/subjects/${subj}/anat/pet_T1/T1.nii -s ${subj}_pet -all -parallel &
recon-all -i ${parentdir}/subjects/${subj}/anat/fmri_T1/T1.nii -s ${subj}_fmri -all -parallel


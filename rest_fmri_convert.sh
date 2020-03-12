#! /bin/bash

############# This script is valid for RESTING STATE FMRI DATA ONLY ################
##
##	$SUBJECTS_DIR must be defined.
##	Exact subject ID and run ID must be supplied as arguments. Subject ID must match the ID used for new directories' creation.
##
##  This script converts reconstructed dicom images into a nifti file (.nii):
##  It also verifies that $SUBJECTS_DIR is set; that an argument was supplied for subject ID and run ID, 
## 	that the subject ID and run ID are valid; that the present working directory contains the first image of a serie; 
## 	that the destination file doesn't already exist (prompts user before overwriting the existing data);
##	that the destination file exists; and that the destination file was created/modified recently.

	## define variables 
subj=$1
run=$2
parentdir="$(dirname "$SUBJECTS_DIR")"
restdir=${parentdir}/subjects/${subj}/rest/${run}/

## verify that $SUBJECTS_DIR is set
if [ -z "$SUBJECTS_DIR" ] ; then
	echo "---------------------------------------------------------------------------------------------------------"
	echo ""
	echo "ERROR:"
	echo ""
	echo "	\$SUBJECTS_DIR is not defined. Please set \$SUBJECTS_DIR before proceeding."
	echo ""
	echo "*NON-ZERO EXIT*"
	echo "---------------------------------------------------------------------------------------------------------"
		exit 1

## verify that both subject ID and run ID were supplied as arguments
elif [ -z ${subj} ] || [ -z ${run} ] ; then 
	echo "---------------------------------------------------------------------------------------------------------"
	echo ""
	echo "ERROR:  The command requires 2 arguments."
	echo ""
	echo "	The subject ID (e.g., 'FEOBV000') should be supplied as the first argument and the run ID (e.g. '001') as the second argument."
	echo "		Example:  'restconvert FEOBV000 001'"
	echo ""
	echo "This would ensure that 'f.nii' will be saved in the correct folder."
	echo "Be very careful to use the correct subject ID and run ID, so not to overwrite existing data from other subjects."
	echo ""
	echo "*NON-ZERO EXIT*"
	echo "---------------------------------------------------------------------------------------------------------"
		exit 2

## verify that subject ID is valid
elif [ -z $(ls -d ${parentdir}/subjects/*/ | grep /subjects/${subj}/) ] ; then 
	echo "----------------------------------------------------------------------------------------------------------------"
	echo ""
	echo "ERROR:"
	echo ""
	echo "	The subject '${subj}' does not exist  (or \$SUBJECTS_DIR was not properly defined)."
	echo "	Please enter a valid subject ID as the first argument, e.g., 'FEOBV000'." 
	echo "	Subject must have data in /group/tuominen/FEOBV/subjects/{subject-ID}/"
	echo ""
	echo "Valid subjects include:"
	echo "$(basename -a ls -d ${parentdir}/subjects/*/ | grep FEOBV*)"
	echo ""
	echo "\$SUBJECTS_DIR is currently defined as   ${SUBJECTS_DIR}"
	echo "If it is incorrectly set, please re-define it before proceeding."
	echo ""
	echo "*NON-ZERO EXIT*"
	echo "----------------------------------------------------------------------------------------------------------------"
		exit 3

## verify that run ID is valid
elif [ -z $(ls -d ${parentdir}/subjects/${subj}/rest/*/ | grep ${run}) ] ; then 
	echo "----------------------------------------------------------------------------------------------------------------"
	echo ""
	echo "ERROR:"
	echo ""
	echo "	The run ID '${run}' does not exist  (or \$SUBJECTS_DIR was not properly defined)."
	echo "	Please enter a valid run ID as the second argument, e.g., '001'." 
	echo ""
	echo "Valid run IDs are:"
	echo "$(basename -a ls -d ${parentdir}/subjects/${subj}/rest/)"
	echo ""
	echo "\$SUBJECTS_DIR is currently defined as   ${SUBJECTS_DIR}"
	echo "If it is incorrectly set, please re-define it before proceeding."
	echo ""
	echo "*NON-ZERO EXIT*"
	echo "----------------------------------------------------------------------------------------------------------------"
		exit 4

## verify that the first image of a serie is found in the present working directory
elif [ ! -f *0001.dcm ] ; then
	echo "----------------------------------------------------------------------------------------------------------------"
	echo ""
	echo "ERROR:"
	echo ""
	echo "	There is no [*]0001.dcm file in the present working directory:	${PWD}"
	echo ""
	echo "	Kindly ensure to 'cd' to the folder that contains the downloaded and extracted dicom images. "
	echo "	Please note that only '.dcm' file extension is compatible with this script."
	echo ""
	echo "*NON-ZERO EXIT*"
	echo "----------------------------------------------------------------------------------------------------------------"
		exit 5

## verify that destination file does not already exists; prompts before overwriting
elif [ -e ${restdir}f.nii ] ; then 
	echo "---------------------------------------------------------------------------------------------------------"
	echo ""
	echo "ATTENTION:"
	echo ""
	echo "	The Resting State fMRI Data have already been converted for subject ${subj} on $(stat -c %y ${restdir}f.nii):	"
	echo "${restdir}f.nii"
	echo ""
	echo "		***Make sure to carefully read statements above before proceeding.***"
	echo ""
	while true; do
		read -p "Are you sure you want to proceed and overwrite the existing 'f.nii' in the subjects' /rest/${run}/ folder?  [y/n]:   " yn
			case $yn in
				[Yy]* ) echo ""
					echo "You answered 'Yes'."
					echo "The file will be overwritten."
					echo "******************************* "
						break ;;
				[Nn]* ) echo ""
					echo "You answered: 'No'. Exiting process..."
					echo ""
					echo "*NON-ZERO EXIT*"
					echo "---------------------------------------------------------------------------------------------------------"
						exit 6 ;;
			esac
	done
fi

## Data details
echo "----------------------------------------------------------------------------------------------------------------"
echo "Project:      $(basename ${parentdir})"
echo "Subject:      ${subj}"
echo "Run ID:       ${run}"
echo "Images from:  Resting State fMRI" 
echo ""
echo "	Now converting data for ${subj}..."

## convert and save in relevant folder
mri_convert -i *0001.dcm -o ${restdir}f.nii

## check if destination file does NOT exist
if [ ! -e ${restdir}f.nii ] ; then 
	echo ""
	echo "ERROR:"
	echo ""
	echo "	The Resting State fMRI data file for ${subj} was not saved. Please review the output above before re-trying command."
	echo ""
	echo "*NON-ZERO EXIT*"
	echo "----------------------------------------------------------------------------------------------------------------"
		exit 7

## verify that destination was created recently (i.e. modified within the last 6 seconds)
elif [ -z $(find ${restdir}f.nii -mmin -0.1) ] ; then 
	echo ""
	echo "ERROR:"
	echo ""
	echo "	The data file does not appear to have been renewed. "
	echo "	The 'f.nii' data file of ${subj} was created/modified on $(stat -c %y ${restdir}f.nii)"
	echo "	Exact location:  ${restdir}f.nii"
	echo ""
	echo "		Kindly review the output above and try re-running the script if necessary."
	echo ""
	echo "*NON-ZERO EXIT*"
	echo "----------------------------------------------------------------------------------------------------------------"
		exit 8

## Success confirmation
else	
	echo ""
	echo "The Resting State fMRI data of ${subj} were successfully converted and saved in the file below:"
	echo "	${restdir}f.nii"
	echo ""
	echo "----------------------------------------------------------------------------------------------------------------"
fi

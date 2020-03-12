#! /bin/bash

## define variables 
subj=$1
parentdir="$(dirname "$SUBJECTS_DIR")"

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
fi

## make directories
cd ${parentdir}/subjects/
mkdir ${subj}
cd ${subj}
mkdir anat  bold  hMRI  hpet  nm  par  pet  physio  qc  rest
mkdir anat/fmri_T1 anat/pet_T1
mkdir bold/001 bold/002 bold/003
mkdir pet/001
mkdir rest/001 rest/002
mkdir hpet/001
mkdir nm/001

## show tree of dirs created
cd ..
tree ${subj}

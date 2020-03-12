#!/usr/bin/env Rscript

## setting paths and working directory: $SUBJECTS_DIR must have been defined
project.dir <- dirname(Sys.getenv("SUBJECTS_DIR"))
if(exists('project.dir') == FALSE || nchar(project.dir[1]) == 0){
  stop("-------------------------------------------------------------------------------------------
       $SUBJECTS_DIR is empty or not defined.
       Please define $SUBJECTS_DIR as the SUBJECTS_DIR directory in the relevant project folder.
       *NON-ZERO EXIT*
-------------------------------------------------------------------------------------------", call. = TRUE)
}
master.dir <- file.path(project.dir, 'master/')
setwd(master.dir)
redcap.dir <- file.path(project.dir, 'redcap/')
subjects.folder <- file.path(project.dir, 'subjects/')

cat(paste0('\n---------------------------------------------------------------------------------------\n',
           '\nThe predefined $SUBJECTS_DIR is: \t',  Sys.getenv("SUBJECTS_DIR"),
           '\nThe working directory was set to: \t', getwd(), '/  \n\n'))


## list participants
subjects <- list.dirs(path = subjects.folder, recursive = FALSE, full.names = FALSE)
subjects <- subjects[subjects != "FEOBV503"]
subjects <- subjects[subjects != "FEOBV507"]

## echo in terminal the list of the participants that should be included       ## could add a comparison check between summary files available and dirs in /subjects/ (and even redcap data)
cat('\nThe subjects included in the master.csv file will be: \n')
cat(paste0(subjects, collapse = ", "), '\n\n')
cat(paste0('---------------------------------------------------------------------------------------\n'))

## redcap data
redcap.dat <- read.table(file.path(redcap.dir, "redcap-parsed.csv"), header = TRUE, sep = ",")

## loop to get ROI data and link to redcap data of each active participant

for(subj in subjects){
  ROI <- read.table(file.path(paste0(subjects.folder, subj, "/pet/001/", subj, ".PET.summary.ROI.stats.dat")))
  row.names(ROI) <- ROI[,5]
  ROI <- subset(ROI, select = c(V6))
  ROI <- ROI[c('Seg0050', 'Seg0011', 'Seg0051', 'Seg0012', 'Seg0053', 'Seg0017', 'Seg0054', 'Seg0018', 'Seg0049', 'Seg0010', 
             'Seg2003', 'Seg1003', 'Seg2027', 'Seg1027'),]
  ROI <- as.data.frame(t(ROI))
  colnames(ROI) <- c('Right_Caudate_PET','Left_Caudate_PET','Right_Putamen_PET','Left_Putamen_PET',
                   'Right_Hippocampus_PET','Left_Hippocampus_PET','Right_Amygdala_PET','Left_Amygdala_PET',
                   'Right_Thalamus_PET','Left_Thalamus_PET','Right_caudal_middle_frontal_PET','Left_caudal_middle_frontal_PET',
                   'Right_rostral_middle_frontal_PET','Left_rostral_middle_frontal_PET')
  redcap <- subset(redcap.dat, ID == subj)
  temp <- cbind(redcap, ROI)
  
  if(exists('MASTER') == FALSE){
    MASTER <- temp
  } else {
    MASTER <- rbind(MASTER, temp)
  }
}
rownames(MASTER) <- NULL
print(MASTER)
cat('------------------------------------------------------------------------------------------------------------------\n\n')

# rename old master file
previousdate <- gsub(":", "-", gsub(" ", "_at_", file.info("master.csv")[[4]]))
file.rename("master.csv", paste0(master.dir, "previous_versions/master_created_on_", previousdate, ".csv"))
if(file.exists(paste0(master.dir, "previous_versions/master_created_on_", previousdate, ".csv")) == TRUE) {
  cat(paste0('The previous master.csv file was archived here: \n \t',
             master.dir, 'previous_versions/master_created_on_', previousdate, '.csv \n'))
} else {
  cat(paste0('\t\tThe previous master.csv file was not archived.',
             '\n\t\tPlease review the output above for errors.',
             '\n\t\t*NON-ZERO EXIT BELOW*',
             '\n-------------------------------------------------------------------------\n'))
}

# Write new master.csv file
write.csv(MASTER, file = "master.csv", row.names = FALSE)
# check if created (recently)...
if (file.exists("master.csv") == FALSE) {
  stop("
      The master.csv file could not be created. Please review the output above.
      *NON-ZERO EXIT*
-------------------------------------------------------------------------------------------", call. = TRUE)
} else if(Sys.time() - 5 > file.info("master.csv")[[4]]){
  stop("
      The master.csv file does not appear to have been renewed. 
      Please review its modification date and the output above for errors.
      *NON-ZERO EXIT*
-------------------------------------------------------------------------------------------", call. = TRUE)
} else {
  cat(paste0('\nThe new master.csv file was saved here: \n \t',
             master.dir, 'master.csv',
             '\n\n------------------------------------------------------------------------------------------------------------------\n'))
}





#!/usr/bin/env Rscript

## setting paths and working directory: $SUBJECTS_DIR must have been defined
fp0 <- dirname(Sys.getenv("SUBJECTS_DIR"))
if(exists('fp0') == FALSE || nchar(fp0[1]) == 0){
  stop("-------------------------------------------------------------------------------------------
       $SUBJECTS_DIR is empty or not defined.
       Please define $SUBJECTS_DIR as the SUBJECTS_DIR directory in the relevant project folder.
       *NON-ZERO EXIT*
-------------------------------------------------------------------------------------------", call. = TRUE)
}
fp1 <- file.path(fp0, 'redcap/')
setwd(file.path(fp0, "redcap/"))
cat(paste0('---------------------------------------------------------------------------------------------------------\n',
    '\nThe predefined $SUBJECTS_DIR is: \t\t',  Sys.getenv("SUBJECTS_DIR"),
    '\nThe working directory was set to: \t\t', getwd(), '\n\n'))

source(file.path(fp0, "scripts/dependencies/age_calc.R"))     # age_calc function from package 'eeptools'

## redcap data processing
if(file.exists("redcap-raw.csv") == FALSE) {
  stop("The redcap-raw.csv file is not accessible. Kindly copy it to the /redcap/ folder before proceeding.
       Please also ensure that the $SUBJECTS_DIR above is correctly defined (to the relevant project).
       *NON-ZERO EXIT*
-------------------------------------------------------------------------------------------", call. = TRUE)
}
dat <- read.csv("redcap-raw.csv", header=TRUE)
dat[15,'injected_dose'] <- '1'         ##this has to be removed once data is entered for 508*
dat <- subset(dat, injected_dose > 0, select=c(record_id, dem_dob, date, dem_sex, #participant_type, ## field was removed from redcap
                                                audit_total_score, ftnd_score, teps_score, bis_total_score, bai_total_score, 
                                                pcl_score, positive_frequency_score, positive_distress_score, negative_frequency_score,
                                                negative_distress_score, depressive_frequency_score, depressive_distress_score, 
                                                ehi_result, most_trauma_event_distress, number_trauma_events, events_causing_fear, 
                                                trauma_events_occurences, participant_weight, participant_height,
                                                injected_dose, injected_mass, specific_activity))
dat[8,'injected_dose'] <- NA           ##this has to be removed once data is entered for 508*
dat[1,'record_id'] <- 'FEOBV-001'
dat <- dat[!(dat$record_id=="FEOBV-503"),]   ## this participant did not finish scan
dat$Group <- dat$record_id
dat$Group <- gsub("FEOBV-", "", dat$Group)
dat$Group <- gsub(".{2}$", "", dat$Group)
dat$Group <- ifelse(dat$Group==0, 'Control', 'Schizophrenia')
dat$record_id <- gsub("-", "", dat$record_id)
names(dat)[names(dat)=="record_id"] <- "ID"
names(dat)[names(dat)=="date"] <- "scan_date"
dat['scan_date'] <- as.Date(dat[,'scan_date'])
dat['dem_dob'] <- as.Date(dat[,'dem_dob'])
dat[,'Age'] <- as.numeric(floor(age_calc(dat[,'dem_dob'], enddate = dat[,'scan_date'], units = "years")))
dat$dem_dob <- NULL
dat$scan_date <- NULL
dat <- dat[, c(1, ncol(dat), 2:(ncol(dat)-1))]
names(dat)[names(dat)=="dem_sex"] <- "Sex"
dat$Sex <- ifelse(dat$Sex==1, 'Male', 'Female')
names(dat)[names(dat)=="positive_distress_score"] <- "CAPE_positive_distress"
names(dat)[names(dat)=="negative_distress_score"] <- "CAPE_negative_distress"
names(dat)[names(dat)=="positive_frequency_score"] <- "CAPE_positive_frequency"
names(dat)[names(dat)=="negative_frequency_score"] <- "CAP_negative_frequency"
names(dat)[names(dat)=="depressive_frequency_score"] <- "CAPE_depressive_frequency"
names(dat)[names(dat)=="depressive_distress_score"] <- "CAPE_depressive_distress"
names(dat)[names(dat)=="most_trauma_event_distress"] <- "TLEQ_most_trauma_event_distress"
names(dat)[names(dat)=="number_trauma_events"] <- "TLEQ_number_trauma_events"
names(dat)[names(dat)=="trauma_events_occurences"] <- "TLEQ_trauma_events_occurences"
names(dat)[names(dat)=="events_causing_fear"] <- "TLEQ_events_causing_fear"
names(dat)[names(dat)=="audit_total_score"] <- "AUDIT"
names(dat)[names(dat)=="ftnd_score"] <- "FTND"
names(dat)[names(dat)=="teps_score"] <- "TEPS"
names(dat)[names(dat)=="bis_total_score"] <- "BIS"
names(dat)[names(dat)=="bai_total_score"] <- "BAI"
names(dat)[names(dat)=="pcl_score"] <- "SPC"
names(dat)[names(dat)=="ehi_result"] <- "EHI"
dat$EHI <- round(dat$EHI)
names(dat)[names(dat)=="participant_height"] <- "height"
names(dat)[names(dat)=="participant_weight"] <- "weight"
rownames(dat) <- NULL

# list participant included
included <- dat['ID']
cat('The subjects included are: \n')
for(subj in included){
  cat(paste0(subj), "  ")
}
cat('\n \n')

# rename old redcap file
previousdate <- gsub(":", "-", gsub(" ", "_at_", file.info("redcap-parsed.csv")[[4]]))
file.rename("redcap-parsed.csv", paste0(fp1, "previous_versions/redcap-parsed_created_on_", previousdate, ".csv"))
if(file.exists(paste0(fp1, "previous_versions/redcap-parsed_created_on_", previousdate, ".csv")) == TRUE) {
  cat(paste0('The previous redcap-parsed.csv file was archived here: \n \t',
             fp1, 'previous_versions/redcap-parsed_created_on_', previousdate, '.csv \n \n'))
} else {
  cat(paste0("\t\tThe previous redcap-parsed.csv file was not archived for some reason",
             "\n\t\tPlease review the output above for errors.",
             "\n\t\t*NON-ZERO EXIT BELOW*",
             "\n-------------------------------------------------------------------------\n"))
}

# Write new redcap-parsed.csv
write.csv(dat, file = "redcap-parsed.csv", row.names = FALSE)
# check if created (recently)...
if (file.exists("redcap-parsed.csv") == FALSE) {
  stop("
      The redcap-parsed.csv file could not be created. Please review the output above.
      *NON-ZERO EXIT*
-------------------------------------------------------------------------------------------", call. = TRUE)
} else if(Sys.time() - 5 > file.info("redcap-parsed.csv")[[4]]){
  stop("
      The redcap-parsed.csv file does not appear to have been renewed. 
      Please review its modification date and the output above for errors.
      *NON-ZERO EXIT*
-------------------------------------------------------------------------------------------", call. = TRUE)
} else {
  file.remove("redcap-raw.csv")
  cat(paste0('The new redcap-parsed.csv file was saved here: \n \t',
             fp1, 'redcap-parsed.csv',
             '\n\n-------------------------------------------------------------------------------------------\n'))
}

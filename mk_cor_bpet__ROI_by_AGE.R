#!/usr/bin/env Rscript

## setting paths and working directory: $SUBJECTS_DIR must have been defined
fp0 <- dirname(Sys.getenv("SUBJECTS_DIR"))
if(exists('fp0') == FALSE || nchar(fp0[1]) == 0){
  stop("Error: $SUBJECTS_DIR is empty or not defined. Please define $SUBJECTS_DIR as the SUBJECTS_DIR directory in the relevant project folder.", call. = TRUE)
}
setwd(fp0)
fp1 <- file.path(fp0, 'redcap/')
fp2 <- file.path(fp0, 'subjects/')

library(ggplot2)

## redcap
dat <- read.csv(file.path(fp1, "redcap-parsed.csv"), header=TRUE)
rownames(dat) <- dat$ID

## list participants
subjects <- list.dirs(path = fp2, recursive = FALSE, full.names = FALSE)

## echo in terminal the list of the participants that should be included
cat(paste0("---------------------------------------------------------------------",
           "\nThe participants included in the statistics will be: "))
cat(paste0(subjects, collapse = ", "))
cat(paste0("---------------------------------------------------------------------"))


## loop to get ROI data and link to redcap data of each active participant

for(subj in subjects){
  ROI <- read.table(file.path(paste0(fp2, subj, "/pet/001/", subj, ".PET.summary.ROI.stats.dat")))
  row.names(ROI) <- ROI[,5]
  ROI <- subset(ROI, select = c(V6))
  ROI <- ROI[c('Seg0050', 'Seg0011', 'Seg0051', 'Seg0012', 'Seg0053', 'Seg0017', 'Seg0054', 'Seg0018', 'Seg0049', 'Seg0010', 
             'Seg2003', 'Seg1003', 'Seg2027', 'Seg1027'),]
  ROI <- as.data.frame(t(ROI))
  colnames(ROI) <- c('Right_Caudate_PET','Left_Caudate_PET','Right_Putamen_PET','Left_Putamen_PET',
                   'Right_Hippocampus_PET','Left_Hippocampus_PET','Right_Amygdala_PET','Left_Amygdala_PET',
                   'Right_Thalamus_PET','Left_Thalamus_PET','Right_caudal_middle_frontal_PET','Left_caudal_middle_frontal_PET',
                   'Right_rostral_middle_frontal_PET','Left_rostral_middle_frontal_PET')
  temp <- cbind(dat[subj, c("ID", "Age")], ROI)
  
  if(exists('MASTER') == FALSE){
    MASTER <-temp
  } else {
    MASTER <- rbind(MASTER, temp)
  }
}
rownames(MASTER) <- NULL
MASTER$ID <- NULL

correlations <- cor(MASTER)

## Creates a Plot for each ROI

list_ROI <- c("Right_Caudate_PET", "Left_Caudate_PET", "Right_Putamen_PET", "Left_Putamen_PET",
         "Right_Hippocampus_PET", "Left_Hippocampus_PET", "Right_Amygdala_PET", "Left_Amygdala_PET",
         "Right_Thalamus_PET", "Left_Thalamus_PET", "Right_caudal_middle_frontal_PET",
         "Left_caudal_middle_frontal_PET", "Right_rostral_middle_frontal_PET", "Left_rostral_middle_frontal_PET")

for(roi in list_ROI){
  #grob1 = grobTree(textGrob(paste("Pearson Correlation : ", round(cor(MASTER[, "Age"], MASTER[, roi]), 4)), hjust = 1, gp = gpar(col = "red", fontsize = 11, fontface = "bold")))

  a <- ggplot(MASTER, aes(x=MASTER[, 'Age'], y=MASTER[, roi])) +
  geom_point(size=7) +
  scale_x_continuous(name="Age (years)") +
  scale_y_continuous(name="SUVR") + 
  ggtitle(paste(roi, " by  Age \n Pearson Correlation:  ", round(cor(MASTER[, "Age"], MASTER[, roi]), 4))) +
  theme(title = element_text(colour = "red", size = 15)) +
  geom_smooth(method=lm, se=TRUE)
  #annotation_custom(grob1)

ggsave(paste0(fp0, "/correlations/", roi, "_correlation_with_Age.jpg"), plot = a, width = 7, height = 7, dpi = 300)
print(paste0("Saving plot to ", fp0, "/correlations/", roi, "_correlation_with_Age.jpg"))
paste0("---------------------------------------------------------------------")

print(cor.test(MASTER$Age, MASTER[,roi]))

}

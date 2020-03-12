#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

## setting paths and working directory: $SUBJECTS_DIR must have been defined
project.dir <- dirname(Sys.getenv("SUBJECTS_DIR"))
if(exists('project.dir') == FALSE || nchar(project.dir[1]) == 0){
  stop("Error: $SUBJECTS_DIR is empty or not defined. Please define $SUBJECTS_DIR as the SUBJECTS_DIR directory in the relevant project folder.", call. = TRUE)
}
subjects.folder <- file.path(project.dir, 'subjects/')

## Requires the participant ID as an argument
listpotentialsubjects <- list.dirs(subjects.folder, recursive = FALSE, full.names = FALSE)
if (length(args)==0) {
  stop('\n', '\n', "The participant ID must be supplied as an argument.", '\n',
       paste('----------------------------------------------------------------'),
       call. = TRUE)
} else if (length(args)>=2) {
  stop('\n', '\n', "Please only supply one argument: the participant ID, e.g. FEOBV000.", '\n',
       paste('---------------------------------------------------------------------------------------------------------'), 
       call. = TRUE)
} else if (is.element(args[1], listpotentialsubjects) == FALSE) {
  stop('\n', '\n', "The subject ID entered does not match an existing subject.

       Valid subjects found in the database are: ", '\n', '\n',
       paste(listpotentialsubjects, Collapse = "  "), '\n',
       paste('---------------------------------------------------------------------------------------------------------'),
       call. = TRUE)
}

subj <- args[1]

setwd(project.dir)

library(ggplot2)
library(gridExtra)
#library(ggplotify)
source(file.path(project.dir, "scripts/dependencies/as-grob.R"))
  
pet.dir <- paste0(project.dir, "/subjects/", subj, "/pet/001/")
  
roi.dat <- read.table(paste0(pet.dir, subj, ".summary_mc_4d_ROI.stats.dat"))
white_matter <- read.table(paste0(pet.dir, "mc_4d_wm_mean_activity"))
  
ROI <- data.frame(row.names = c("caudate", "hippocampus", "putamen", "amygdala", "thalamus", 
                                "caudal_mid_frontal", "rostral_mid_frontal"))
ROI['caudate', 1] <- 7
ROI['caudate', 2] <- 27
ROI['putamen', 1] <- 8
ROI['putamen', 2] <- 28
ROI['hippocampus', 1] <- 13
ROI['hippocampus', 2] <- 30
ROI['amygdala', 1] <- 14
ROI['amygdala', 2] <- 31
ROI['thalamus', 1] <- 6
ROI['thalamus', 2] <- 26
ROI['caudal_mid_frontal', 1] <- 46
ROI['caudal_mid_frontal', 2] <- 81
ROI['rostral_mid_frontal', 1] <- 104
ROI['rostral_mid_frontal', 2] <- 69
colnames(ROI) <- c('left', 'right')
  
list.roi <- rownames(ROI)
ROI$graph.names <- paste0(rownames(ROI), ".graph")
  
for(roi in list.roi){
  
  SUVRR.dat <- data.frame(row.names = 1:5)
    
  dat <- roi.dat[, c(ROI[roi, 'left'], ROI[roi, 'right'])]
  dat <- as.data.frame(rowMeans(dat))
  pet.data <- cbind(dat, white_matter)
  names(pet.data) <- c(roi, 'white_matter')
  
  SUVR <- sum(pet.data[[roi]]) / sum(pet.data[['white_matter']])
  
  for(x in c(1:5)){
    suvr <- vector()
    combinations <- combn(1:6, x)
    
    for(i in 1:ncol(combinations)){
      remov <- combinations[,i]
      temp <- pet.data[-c(remov),]
      suvr[i] <- sum(temp[[roi]]) / sum(temp[['white_matter']])
    }
    
    SUVRR.dat[x, 1] <- mean(suvr / SUVR)
    SUVRR.dat[x, 2] <- sd(suvr / SUVR)
    colnames(SUVRR.dat) <- c("mean_diff", "sd_diff")
  }
    
  name.graph <- ROI[roi, 3]
    
  a <- ggplot(SUVRR.dat, aes(x=1:5, y=SUVRR.dat[, 1])) + 
    geom_point(size=2.5) + 
    scale_x_continuous(name="# of Frames Removed", breaks=seq(1:5)) + 
    scale_y_continuous(name="SUVR ratios") + 
    geom_errorbar(aes(ymin=(SUVRR.dat[, 1]) - (SUVRR.dat[, 2]), ymax= (SUVRR.dat[, 1]) + (SUVRR.dat[, 2])), width=.2) +
    ggtitle(paste0(subj, ":  ", roi)) + 
    theme(axis.text = element_text(size=12))
  assign(name.graph, a)
}
 
 g <- arrangeGrob(caudate.graph, hippocampus.graph, putamen.graph, amygdala.graph, thalamus.graph, caudal_mid_frontal.graph, 
                  rostral_mid_frontal.graph, nrow=3)
ggsave(file = paste0(project.dir, "/results/incremental_frame_removal_qc_control_graphs/", subj, "_SUVR-diff-ratios_after_incremental_frame_removal.jpg"), 
       plot = g, width = 10, height = 10, dpi = 500)
  
if(file.exists(paste0(project.dir, "/results/incremental_frame_removal_qc_control_graphs/", subj, "_SUVR-diff-ratios_after_incremental_frame_removal.jpg")) == FALSE){
  cat(paste0("\n ERROR: \n", project.dir, "/results/incremental_frame_removal_qc_control_graphs/", subj, "_SUVR-diff-ratios_after_incremental_frame_removals.jpg    was not saved...\n")) 
}

#!/usr/bin/env Rscript

args = commandArgs(trailingOnly=TRUE)

## setting paths: Requires a defined $SUBJECTS_DIR
project.dir <- dirname(Sys.getenv("SUBJECTS_DIR"))
## Verification
if(exists('project.dir') == FALSE || nchar(project.dir[1]) == 0){
  stop("Error: $SUBJECTS_DIR is empty or not defined. 
       Please define $SUBJECTS_DIR as the SUBJECTS_DIR directory in the relevant project folder."
       , call. = TRUE)
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

id <- args[1]
par.dir <- file.path(subjects.folder, args[1], "par/")
setwd(par.dir)

cat(paste0('---------------------------------------------------------------------------------------------------------', '\n',
           'Making the paradigm files for ', id, '...', '\n', '\n')
)

# loop to create wm.par and wm_run.csv for each run
list.runs <- c("001", "002", "003")
for (run in list.runs) {

runX <- substr(run, start = 3, stop = 3)
nback <- read.delim(file.path(paste0(par.dir, id, '_run', runX,'.txt')), stringsAsFactors=FALSE) #modify the path of your saved .txt output file 

nback <- tail(nback, -2) #remove first two rows 

colnames(nback) <- as.character(unlist(nback[1,])) #rename columns using the first row of data 

nback <- tail(nback, -1) #remove first row 

attach(nback) 
wm_nback <- data.frame(GetReady.OnsetTime, ListType, Slide3.OnsetTime, stringsAsFactors=FALSE) #create a new dataset with relavant variables
detach(nback)

wm_nback$ListType <- gsub("0-Back", "1", wm_nback$ListType)
wm_nback$ListType <- gsub("1-Back", "2", wm_nback$ListType)
wm_nback$ListType <- gsub("2-Back", "3", wm_nback$ListType) #change 0-back to 1, 1-back to 2, 2-back to 3

wm_nback$GetReady <- rep(wm_nback[1,1],nrow(wm_nback)) #create a column with the onset of start of experiment 

ind <- seq(1, nrow(wm_nback), by=12) # make an index every 12th row
wm_nback <- wm_nback[ind,] #leave only the indexed rows (for block design)

wm_nback$GetReady.OnsetTime <- as.numeric(wm_nback$GetReady.OnsetTime)
wm_nback$ListType <- as.numeric(wm_nback$ListType)
wm_nback$GetReady <- as.numeric(wm_nback$GetReady)
wm_nback$Slide3.OnsetTime <- as.numeric(wm_nback$Slide3.OnsetTime )

wm_nback$onset <- ((wm_nback$Slide3.OnsetTime - wm_nback$GetReady)/1000)

wm_nback$Duration <- rep(48, nrow(wm_nback)) #create a column of value 48 for duration

wm_nback$Weight <- rep(1, nrow(wm_nback)) #create a column of value 1 for weight

wm_nback <- data.frame(wm_nback$onset, wm_nback$ListType, wm_nback$Duration, wm_nback$Weight) #only keep the relavant columns

write.table(wm_nback, paste0('wm_run', run, '.csv'), row.names=FALSE, col.names = FALSE, sep = "\t") #export as .csv to the par folder
write.table(wm_nback, paste0(subjects.folder, id, '/bold/', run, '/wm.par'), row.names=FALSE, col.names = FALSE, sep = "\t") #export as .par to the relevant bold run folder

cat(paste('The paradigm file for run', run, 'was saved here:      ',
          paste0(subjects.folder, id, '/bold/', run, '/wm.par'), '\n'
          )
    )

}

cat('---------------------------------------------------------------------------------------------------------\n')

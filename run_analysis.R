# load libraries
library(data.table)
library(dplyr)

# load subject, action and measurements for test data set
testdt <- data.table(fread("UCI HAR Dataset/test/subject_test.txt"),fread("UCI HAR Dataset/test/y_test.txt",colClasses = "character"), fread("UCI HAR Dataset/test/X_test.txt"))

# load subject, action and measurements for train data set
traindt <- data.table(fread("UCI HAR Dataset/train//subject_train.txt"),fread("UCI HAR Dataset/train/y_train.txt",colClasses = "character"), fread("UCI HAR Dataset/train/X_train.txt"))

# combine all rows from test and train into one data table
dtall <- rbind (testdt,traindt)

# Read features file that will be used to identify all the measurements of the data set
header <- read.table("UCI HAR Dataset/features.txt", sep = "" , header = F , na.strings ="", stringsAsFactors= F)

# set data table column names from features data
colnames(dtall) <-  c("subject","action",header[,2])

# subset data table with subject, action and columns that contain either std() or mean() 
dtcols <- dtall[,c(1,2,grep("*(std|mean)([[:punct:]]).*",colnames(dtall))),with=FALSE]

# tidying column names, removing punctuation and converting to lowercase
colnames(dtcols) <- colnames(dtcols) %>%gsub("[[:punct:]]","",.) %>% tolower()

# translating action values to be more descriptive
# values could have been loaded from 'activities_labels.txt' file, but I just noticed that too late
# in any case the mapping below did the trick
dtcols[action=="1",action:="WALKING"]
dtcols[action=="2",action:="WALKING_UPSTAIRS"]
dtcols[action=="3",action:="WALKING_DOWNSTAIRS"]
dtcols[action=="4",action:="SITTING"]
dtcols[action=="5",action:="STANDING"]
dtcols[action=="6",action:="LAYING"]

# formatting subjects to be more descriptive, adding the word subject and a 2 digit identification number (ie 02)
dtcols$subject <- paste0("subject",sprintf("%02.f",dtcols[,subject]) )

# create tidy data table, calculating the mean of all the measurements grouped by subject and action 
tidy <- dtcols[, lapply(.SD, mean), key=c("subject","action")]

# remove attribute sorted, to make all.equal() comparison successful
attr(tidy,"sorted") <- NULL

# create the tidy output file 
write.table(tidy,file="tidy.txt",row.names = FALSE)

# View tidy data table
View(tidy)


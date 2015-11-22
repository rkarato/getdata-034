---
title: "[Getting and Cleaning Data Project 034](https://www.coursera.org/course/getdata)"
author: "Rafael Karato"
date: "2015-11-22"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Vignette Title}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8} 
---

"The purpose of this project is to demonstrate your ability to collect, work with, and clean a data set. The goal is to prepare tidy data that can be used for later analysis. You will be graded by your peers on a series of yes/no questions related to the project. You will be required to submit: 1) a tidy data set as described below, 2) a link to a Github repository with your script for performing the analysis, and 3) a code book that describes the variables, the data, and any transformations or work that you performed to clean up the data called CodeBook.md. You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.  

One of the most exciting areas in all of data science right now is wearable computing - see for example this article . Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained: 

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 

Here are the data for the project: 

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 
" ^[Extract from the course project assignment page]

## The Files
Files included in this repository

File                  | Description  
----------------------|----------------------  
README.md             |Project Information and Instructions   
run_analysis.R        |Script to create a tidy data set from the project Data  
CodeBook.md           |variable descriptions for the output file tidy.txt  

## Instructions
The goal of the project is to use a base data set and apply the concepts seen in the lectures and produce a tidy set of data that could be used for further analysis. 

The base data should be available in your working directory, in a folder called "UCI HAR Dataset". This folder is the unzipped content of the project data link provided

The analysis script requires the unzipped folder "UCI HAR Dataset" to be present in your working directory

If you don't have the folder in your working directory you may create it using:

```r
download.file(
  "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip",
  "Dataset.zip", mode = "wb")
unzip("Dataset.zip")
```
Note it's a 60MB file


## The Base Data
More information about the base data set can be found in the following files inside the "UCI HAR Dataset" folder  
- 'README.txt'  
- 'features_info.txt'  
- 'features.txt'  

The following files were used as input for the project  
- 'activity_labels.txt': Links the class labels with their activity name.  
- 'train/X_train.txt': Training set.  
- 'train/y_train.txt': Training labels.  
- 'test/X_test.txt': Test set.  
- 'test/y_test.txt': Test labels.  
- 'train/subject_train.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30.   
- 'test/subject_test.txt': Each row identifies the subject who performed the activity for each window sample. Its range is from 1 to 30.   

## Putting the base data together
To begin working with the base data, we have to put all the pieces together.
The base data is separated in different files with different contents.
The first step is to combine in a data table, the subject information ( subject_.txt ), action information ( y_.txt ) and the feature measurements ( x_.txt ) for both train and test groups

Imagine each of the files as a block and we would have a structure like this:

```r
   ---------------------------------------------
   subject_test.txt  | y_test.txt  | x_test.txt  
   subject_train.txt | y_train.txt | x_train.txt
   ---------------------------------------------
```

The code below will create the data table

```r
# load libraries
library(data.table)
library(dplyr)

# load subject, action and measurements for test data set
testdt <- data.table(fread("UCI HAR Dataset/test/subject_test.txt"),
                     fread("UCI HAR Dataset/test/y_test.txt",
                           colClasses = "character"), 
                     fread("UCI HAR Dataset/test/X_test.txt"))

# load subject, action and measurements for train data set
traindt <- data.table(fread("UCI HAR Dataset/train//subject_train.txt"),
                      fread("UCI HAR Dataset/train/y_train.txt",
                            colClasses = "character"), 
                      fread("UCI HAR Dataset/train/X_train.txt"))

# combine all rows from test and train into one data table
dtall <- rbind (testdt,traindt)
```

The data table will have:  
- subject information in the first column  
- action information in the second column    
- feature measurements from the third column onwards  


```r
dtall[1:4,1:5,with=FALSE]
       V1 V1        V1           V2          V3 
    1:  2  5 0.2571778 -0.023285230 -0.01465376
    2:  2  5 0.2860267 -0.013163359 -0.11908252
    3:  2  5 0.2754848 -0.026050420 -0.11815167
    4:  2  5 0.2702982 -0.032613869 -0.11752018
```

## Variable names
As you noticed our data table does not have descriptive variable names.
We are going to use the names from the features.txt file in the base data set for the feature variable names and call the first and second variables, subject and action respectively.

This is the code:

```r
# Read features file that will be used to identify 
#    all the measurements of the data set
header <- read.table("UCI HAR Dataset/features.txt", 
                     sep = "" , header = F , na.strings ="", stringsAsFactors= F)

# set data table column names from features data
colnames(dtall) <-  c("subject","action",header[,2])
```

And this is how our data table is looking now.

```r
dtall[1:4,1:5,with=FALSE]
   subject action tBodyAcc-mean()-X tBodyAcc-mean()-Y tBodyAcc-mean()-Z
1:       2      5         0.2571778       -0.02328523       -0.01465376
2:       2      5         0.2860267       -0.01316336       -0.11908252
3:       2      5         0.2754848       -0.02605042       -0.11815167
4:       2      5         0.2702982       -0.03261387       -0.11752018
```



## Subsetting and tidying
We currently have 561 feature measurements for each observation. What we require is only the measurements that refer to mean() and std() calculations, so we are going to subset our data table, to contain only feature measurements which name include either mean or std strings, followed by a punctuation sign. This will bring down the number of measurements to 66.

Following more tidy data principles, we are also going to remove the punctuations from the variable names and convert them to lower case. 

The subject and action values are also going to be changed to be more descriptive. A descriptive name is a human readable string that a peer will immediately understand what the variable value means. The action will be decoded from the values in file activity_labels.txt ( Walking, Laying, etc ) and the subject will have the string 'subject' added before the current numeric value, which will also be formated to include a leading 0 if the value is less then 10. 

This is the code:

```r
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
```

And this is our subset data table:

```r
dtcols[1:4,1:5,with=FALSE]
     subject   action tbodyaccmeanx tbodyaccmeany tbodyaccmeanz
1: subject02 STANDING     0.2571778   -0.02328523   -0.01465376
2: subject02 STANDING     0.2860267   -0.01316336   -0.11908252
3: subject02 STANDING     0.2754848   -0.02605042   -0.11815167
4: subject02 STANDING     0.2702982   -0.03261387   -0.11752018
```

## Calculating the means
Our next step is to aggregate the measurements, calculating the mean value of all the observations that share the same subject and action. 
The mean calculation grouped by subject and action, will result in our target data frame, which will be written to a file and uploaded in the project assignment page.

View the code:

```r
# create tidy data table, calculating the mean of all the measurements grouped by subject and action 
tidy <- dtcols[, lapply(.SD, mean), key=c("subject","action")]

# this step removes the data table attribute "index" 
# this will make the resulting data table identical
# when comparing to a new data table read from the resulting output file using 
# data <- fread("tidy.txt", header = TRUE,stringsAsFactors = FALSE) 
attr(tidy,"index") <- NULL

# create the tidy output file 
write.table(tidy,file="tidy.txt",row.names = FALSE)
```

To be consistent, this is ( part of ) our final tidy data table:

```r
tidy[1:4,1:5,with=FALSE]
     subject   action tbodyaccmeanx tbodyaccmeany tbodyaccmeanz
1: subject01   LAYING     0.2215982  -0.040513953    -0.1132036
2: subject01  SITTING     0.2612376  -0.001308288    -0.1045442
3: subject01 STANDING     0.2789176  -0.016137590    -0.1106018
4: subject01  WALKING     0.2773308  -0.017383819    -0.1111481
```

## Output file
The final output of the analysis script is the tidy.txt file. I believe you will be able to download that file upon commencement of the Evaluation phase.

You will be able to see the uploaded file contents, downloading it to your work directory and running:

```r
data <- fread("tidy.txt", header = TRUE,stringsAsFactors = FALSE) 

View(data)
```

You may also compare it with the tidy data frame

```r
all.equal(tidy,data)
```

##License:
Acknowledment for the use of the project dataset: 

[1] Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and Jorge L. Reyes-Ortiz. Human Activity Recognition on Smartphones using a Multiclass Hardware-Friendly Support Vector Machine. International Workshop of Ambient Assisted Living (IWAAL 2012). Vitoria-Gasteiz, Spain. Dec 2012

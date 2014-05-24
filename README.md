Getting and Cleaning Data: Course Project
========================================================

Introduction
--------------------------------------
The purpose of this project is to demonstrate your ability to collect, work with, and clean a data set. The goal is to prepare tidy data that can be used for later analysis. You will be graded by your peers on a series of yes/no questions related to the project. You will be required to submit: 1) a tidy data set as described below, 2) a link to a Github repository with your script for performing the analysis, and 3) a code book that describes the variables, the data, and any transformations or work that you performed to clean up the data called CodeBook.md. You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.  

You should create one R script called run_analysis.R that does the following. 
1. Merges the training and the test sets to create one data set.
2. Extracts only the measurements on the mean and standard deviation for each measurement. 
3. Uses descriptive activity names to name the activities in the data set
4. Appropriately labels the data set with descriptive activity names. 
5. Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 

### Files in the repository

* README.md: The introductory read me file, that you are currently viewing.
* README.Rmd: The knitter file that crerates README.md.

* CodeBook.md: The codebook for the project.
* CodeBook.Rmd: The knitter file that creates CodeBook.md.

* run_analysis.R: The R script that accomplishes the analysis required.
* tidydata.txt; The output dataset from run_analysis.R

### Data
Citation 

[1] Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and Jorge L. Reyes-Ortiz. Human Activity Recognition on Smartphones using a Multiclass Hardware-Friendly Support Vector Machine. International Workshop of Ambient Assisted Living (IWAAL 2012). Vitoria-Gasteiz, Spain. Dec 2012

One of the most exciting areas in all of data science right now is wearable computing - see for example this article . Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained: 

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 

The data for the project can be obtained here: 

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 

### Data Input
Files were loaded using the read.table command. The paramater stringsAsFactors was set to FALSE when loading the character based data for features and activities to facilitate later processing. Column names are declared when reading in the activity labels file to be used when merging the activities labels.



```r
## get training data
fileTrainX <- read.table("X_train.txt")
fileTrainY <- read.table("y_train.txt")
fileTrainS <- read.table("subject_train.txt")

## get test data
fileTestX <- read.table("X_test.txt")
fileTestY <- read.table("y_test.txt")
fileTestS <- read.table("subject_test.txt")

## Get activities and features
fileActivity <- read.table("activity_labels.txt", stringsAsFactors = FALSE, 
    col.names = c("activityCode", "activityLabel"))
fileFeatures <- read.table("features.txt", stringsAsFactors = FALSE)
```


### Combining Datasets

This section completes the 1st function of the project:
* 1. Merges the training and the test sets to create one data set.


This step adds the activity column to both the test and training datasets, using the cbind function. 


```r
## add activity to test and train data
fileTestXY <- cbind(fileTestX, fileTestY)
fileTrainXY <- cbind(fileTrainX, fileTrainY)
```


This step adds the subject column to both the test and training datasets, using the cbind function. 


```r
## add subject to test and train data
fileTestXYS <- cbind(fileTestXY, fileTestS)
fileTrainXYS <- cbind(fileTrainXY, fileTrainS)
```


This step combines the test and training datasets usinf rbind function.


```r
## ## merge test and train
fileData <- rbind(fileTrainXYS, fileTestXYS)
```



### Transform Features and subset
This section accomplishes the 2nd and 3rd functions of the project:
* 2. Extracts only the measurements on the mean and standard deviation for each measurement. 
* 3. Uses descriptive activity names to name the activities in the data set

The step adds lables for the new columns in the data set to the features.


```r
## add activity and subject code to features
fileFeatures <- rbind(fileFeatures, c(nrow(fileFeatures) + 1, "activityCode"))
fileFeatures <- rbind(fileFeatures, c(nrow(fileFeatures) + 1, "subjectCode"))
```


This step sets the names of the columns equal to the feature names


```r
## set column names equal to 2nd column of the fileFeatures data frame
colnames(fileData) <- fileFeatures[[2]]
```


This step subsets the data, taking only those columns with the mean() and std() in their names. There were other features that contained Mean in their name but were not calculated averages and not included in the output. It also includes the new columns that have Code in their name.


```r
## subset dataset for features with mean or stdev or code in name
selectFeature <- (grepl("mean()", fileFeatures$V2)) | (grepl("std()", fileFeatures$V2) | 
    (grepl("Code", fileFeatures$V2)))
fileData <- subset(fileData, select = selectFeature)
```


This step cleans up column names by removing the parenthesis. Because the column names consisted of concatenated words we kept the camel case of the original data set as opposed to converting the names to alllower case. A personal preference that I think results in more readable columnnames.



```r
## remove parenthesis in colunnames
fileDataCols <- colnames(fileData)
## escape a metacharacter in a regular expression, you precede it with a
## backslash. If your expression is in double quotes, then the backslash
## itself must be escaped by using double backslashes.
fileDataCols <- gsub(pattern = "\\(|\\)", x = fileDataCols, replacement = "")
## Assign cleaned up names to columns
colnames(fileData) <- fileDataCols
```


### Create new dataset
This section accomplishes the 5th function of the project.
* 5. Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 
* 4. Appropriately labels the data set with descriptive activity names.

Th accomploish this goal the library reshape2 was loaded The functions metl and cast were used to reshape the data and aggregate over the activity and subject codes. The merge function was used to Appropriately labels the data set with descriptive activity names. Merge was performed by joining on  activity code which is common column to both datasets.

The resulting dataset has a row for each combination of activity and subject in the data. This means that this data frame will have 180 rows (30 subjects * 6 activities). It has 82 columns. 3 were added, activityCode, subjectCode and activityLabel. 79 came from the test and train datasets, those with mean() and std(), in their name.



```r
## laod library
library(reshape2)
## First melt or unpivot the dataset since we want to aggregate by
## subjectCode and activityCode they are the ids, default allother columns
## are variables
fileDataMelt <- melt(fileData, id = c("subjectCode", "activityCode"))

## Now cast or pivot the columns and get the mean
fileDataCast <- dcast(fileDataMelt, activityCode + subjectCode ~ variable, mean)

## mere or join the dataset to get activity labels join by activity code
## which is common column to both datasets
fileDataMerge <- merge(fileDataCast, fileActivity, by = "activityCode")

## write data to tab delimited text file
write.table(fileDataMerge, "tidydata.txt", sep = "\t")
```


The structure of the output data is written to the screen/


```r
## print structure to screen
str(fileDataMerge)
```

```
## 'data.frame':	180 obs. of  82 variables:
##  $ activityCode                 : int  1 1 1 1 1 1 1 1 1 1 ...
##  $ subjectCode                  : int  1 2 3 4 5 6 7 8 9 10 ...
##  $ tBodyAcc-mean-X              : num  0.277 0.276 0.276 0.279 0.278 ...
##  $ tBodyAcc-mean-Y              : num  -0.0174 -0.0186 -0.0172 -0.0148 -0.0173 ...
##  $ tBodyAcc-mean-Z              : num  -0.111 -0.106 -0.113 -0.111 -0.108 ...
##  $ tBodyAcc-std-X               : num  -0.284 -0.424 -0.36 -0.441 -0.294 ...
##  $ tBodyAcc-std-Y               : num  0.1145 -0.0781 -0.0699 -0.0788 0.0767 ...
##  $ tBodyAcc-std-Z               : num  -0.26 -0.425 -0.387 -0.586 -0.457 ...
##  $ tGravityAcc-mean-X           : num  0.935 0.913 0.937 0.964 0.973 ...
##  $ tGravityAcc-mean-Y           : num  -0.2822 -0.3466 -0.262 -0.0859 -0.1004 ...
##  $ tGravityAcc-mean-Z           : num  -0.0681 0.08473 -0.13811 0.12776 0.00248 ...
##  $ tGravityAcc-std-X            : num  -0.977 -0.973 -0.978 -0.984 -0.979 ...
##  $ tGravityAcc-std-Y            : num  -0.971 -0.972 -0.962 -0.968 -0.962 ...
##  $ tGravityAcc-std-Z            : num  -0.948 -0.972 -0.952 -0.963 -0.965 ...
##  $ tBodyAccJerk-mean-X          : num  0.074 0.0618 0.0815 0.0784 0.0846 ...
##  $ tBodyAccJerk-mean-Y          : num  0.02827 0.01825 0.01006 0.00296 -0.01632 ...
##  $ tBodyAccJerk-mean-Z          : num  -4.17e-03 7.90e-03 -5.62e-03 -7.68e-04 8.32e-05 ...
##  $ tBodyAccJerk-std-X           : num  -0.114 -0.278 -0.269 -0.297 -0.303 ...
##  $ tBodyAccJerk-std-Y           : num  0.067 -0.0166 -0.045 -0.2212 -0.091 ...
##  $ tBodyAccJerk-std-Z           : num  -0.503 -0.586 -0.529 -0.751 -0.613 ...
##  $ tBodyGyro-mean-X             : num  -0.0418 -0.053 -0.0256 -0.0318 -0.0489 ...
##  $ tBodyGyro-mean-Y             : num  -0.0695 -0.0482 -0.0779 -0.0727 -0.069 ...
##  $ tBodyGyro-mean-Z             : num  0.0849 0.0828 0.0813 0.0806 0.0815 ...
##  $ tBodyGyro-std-X              : num  -0.474 -0.562 -0.572 -0.501 -0.491 ...
##  $ tBodyGyro-std-Y              : num  -0.0546 -0.5385 -0.5638 -0.6654 -0.5046 ...
##  $ tBodyGyro-std-Z              : num  -0.344 -0.481 -0.477 -0.663 -0.319 ...
##  $ tBodyGyroJerk-mean-X         : num  -0.09 -0.0819 -0.0952 -0.1153 -0.0888 ...
##  $ tBodyGyroJerk-mean-Y         : num  -0.0398 -0.0538 -0.0388 -0.0393 -0.045 ...
##  $ tBodyGyroJerk-mean-Z         : num  -0.0461 -0.0515 -0.0504 -0.0551 -0.0483 ...
##  $ tBodyGyroJerk-std-X          : num  -0.207 -0.39 -0.386 -0.492 -0.358 ...
##  $ tBodyGyroJerk-std-Y          : num  -0.304 -0.634 -0.639 -0.807 -0.571 ...
##  $ tBodyGyroJerk-std-Z          : num  -0.404 -0.435 -0.537 -0.64 -0.158 ...
##  $ tBodyAccMag-mean             : num  -0.137 -0.29 -0.255 -0.312 -0.158 ...
##  $ tBodyAccMag-std              : num  -0.22 -0.423 -0.328 -0.528 -0.377 ...
##  $ tGravityAccMag-mean          : num  -0.137 -0.29 -0.255 -0.312 -0.158 ...
##  $ tGravityAccMag-std           : num  -0.22 -0.423 -0.328 -0.528 -0.377 ...
##  $ tBodyAccJerkMag-mean         : num  -0.141 -0.281 -0.28 -0.367 -0.288 ...
##  $ tBodyAccJerkMag-std          : num  -0.0745 -0.1642 -0.1399 -0.3169 -0.2822 ...
##  $ tBodyGyroMag-mean            : num  -0.161 -0.447 -0.466 -0.498 -0.356 ...
##  $ tBodyGyroMag-std             : num  -0.187 -0.553 -0.562 -0.553 -0.492 ...
##  $ tBodyGyroJerkMag-mean        : num  -0.299 -0.548 -0.566 -0.681 -0.445 ...
##  $ tBodyGyroJerkMag-std         : num  -0.325 -0.558 -0.567 -0.73 -0.489 ...
##  $ fBodyAcc-mean-X              : num  -0.203 -0.346 -0.317 -0.427 -0.288 ...
##  $ fBodyAcc-mean-Y              : num  0.08971 -0.0219 -0.0813 -0.1494 0.00946 ...
##  $ fBodyAcc-mean-Z              : num  -0.332 -0.454 -0.412 -0.631 -0.49 ...
##  $ fBodyAcc-std-X               : num  -0.319 -0.458 -0.379 -0.447 -0.298 ...
##  $ fBodyAcc-std-Y               : num  0.056 -0.1692 -0.124 -0.1018 0.0426 ...
##  $ fBodyAcc-std-Z               : num  -0.28 -0.455 -0.423 -0.594 -0.483 ...
##  $ fBodyAcc-meanFreq-X          : num  -0.208 -0.146 -0.247 -0.139 -0.322 ...
##  $ fBodyAcc-meanFreq-Y          : num  0.11309 0.19859 0.17174 0.01235 -0.00204 ...
##  $ fBodyAcc-meanFreq-Z          : num  0.0497 0.0689 0.0749 -0.0788 0.0247 ...
##  $ fBodyAccJerk-mean-X          : num  -0.171 -0.305 -0.305 -0.359 -0.345 ...
##  $ fBodyAccJerk-mean-Y          : num  -0.0352 -0.0788 -0.1405 -0.2796 -0.1811 ...
##  $ fBodyAccJerk-mean-Z          : num  -0.469 -0.555 -0.514 -0.729 -0.59 ...
##  $ fBodyAccJerk-std-X           : num  -0.134 -0.314 -0.297 -0.297 -0.321 ...
##  $ fBodyAccJerk-std-Y           : num  0.10674 -0.01533 -0.00561 -0.2099 -0.05452 ...
##  $ fBodyAccJerk-std-Z           : num  -0.535 -0.616 -0.544 -0.772 -0.633 ...
##  $ fBodyAccJerk-meanFreq-X      : num  -0.2093 -0.0727 -0.216 -0.1353 -0.3594 ...
##  $ fBodyAccJerk-meanFreq-Y      : num  -0.386 -0.264 -0.259 -0.386 -0.534 ...
##  $ fBodyAccJerk-meanFreq-Z      : num  -0.186 -0.255 -0.347 -0.326 -0.344 ...
##  $ fBodyGyro-mean-X             : num  -0.339 -0.43 -0.438 -0.373 -0.373 ...
##  $ fBodyGyro-mean-Y             : num  -0.103 -0.555 -0.562 -0.688 -0.514 ...
##  $ fBodyGyro-mean-Z             : num  -0.256 -0.397 -0.418 -0.601 -0.213 ...
##  $ fBodyGyro-std-X              : num  -0.517 -0.604 -0.615 -0.543 -0.529 ...
##  $ fBodyGyro-std-Y              : num  -0.0335 -0.533 -0.5689 -0.6547 -0.5027 ...
##  $ fBodyGyro-std-Z              : num  -0.437 -0.56 -0.546 -0.716 -0.42 ...
##  $ fBodyGyro-meanFreq-X         : num  0.01478 0.00728 0.03376 -0.12715 -0.04586 ...
##  $ fBodyGyro-meanFreq-Y         : num  -0.0658 -0.0427 -0.038 -0.2747 -0.0192 ...
##  $ fBodyGyro-meanFreq-Z         : num  0.000773 0.139752 -0.044508 0.149852 0.167458 ...
##  $ fBodyAccMag-mean             : num  -0.129 -0.324 -0.29 -0.451 -0.305 ...
##  $ fBodyAccMag-std              : num  -0.398 -0.577 -0.456 -0.651 -0.52 ...
##  $ fBodyAccMag-meanFreq         : num  0.191 0.393 0.113 0.382 0.15 ...
##  $ fBodyBodyAccJerkMag-mean     : num  -0.0571 -0.1691 -0.1868 -0.3186 -0.2695 ...
##  $ fBodyBodyAccJerkMag-std      : num  -0.1035 -0.1641 -0.0899 -0.3205 -0.3057 ...
##  $ fBodyBodyAccJerkMag-meanFreq : num  0.09382 0.2075 -0.11716 0.11149 -0.00497 ...
##  $ fBodyBodyGyroMag-mean        : num  -0.199 -0.531 -0.57 -0.609 -0.484 ...
##  $ fBodyBodyGyroMag-std         : num  -0.321 -0.652 -0.633 -0.594 -0.59 ...
##  $ fBodyBodyGyroMag-meanFreq    : num  0.2688 0.3053 0.1809 0.0697 0.2506 ...
##  $ fBodyBodyGyroJerkMag-mean    : num  -0.319 -0.583 -0.608 -0.724 -0.548 ...
##  $ fBodyBodyGyroJerkMag-std     : num  -0.382 -0.558 -0.549 -0.758 -0.456 ...
##  $ fBodyBodyGyroJerkMag-meanFreq: num  0.1907 0.1263 0.0458 0.2654 0.0527 ...
##  $ activityLabel                : chr  "WALKING" "WALKING" "WALKING" "WALKING" ...
```



Getting and Cleaning Data: Course Project Codebook
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
## load library
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



### Data Exploration

The tidydata consists of 180 observations of 82 variables. A case is an observation of a subject and specific activites.


```r
dim(fileDataMerge)
```

```
## [1] 180  82
```


The structure of the tidydatset is detailed below.


```r
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



Example rows from the tidydatset are shown below


```r
head(fileDataMerge)
```

```
##   activityCode subjectCode tBodyAcc-mean-X tBodyAcc-mean-Y tBodyAcc-mean-Z
## 1            1           1          0.2773        -0.01738         -0.1111
## 2            1           2          0.2764        -0.01859         -0.1055
## 3            1           3          0.2756        -0.01718         -0.1127
## 4            1           4          0.2786        -0.01484         -0.1114
## 5            1           5          0.2778        -0.01729         -0.1077
## 6            1           6          0.2837        -0.01690         -0.1103
##   tBodyAcc-std-X tBodyAcc-std-Y tBodyAcc-std-Z tGravityAcc-mean-X
## 1        -0.2837        0.11446        -0.2600             0.9352
## 2        -0.4236       -0.07809        -0.4253             0.9130
## 3        -0.3604       -0.06991        -0.3874             0.9365
## 4        -0.4408       -0.07883        -0.5863             0.9640
## 5        -0.2941        0.07675        -0.4570             0.9726
## 6        -0.2965        0.16421        -0.5043             0.9581
##   tGravityAcc-mean-Y tGravityAcc-mean-Z tGravityAcc-std-X
## 1           -0.28217          -0.068103           -0.9766
## 2           -0.34661           0.084727           -0.9727
## 3           -0.26199          -0.138108           -0.9778
## 4           -0.08585           0.127764           -0.9838
## 5           -0.10044           0.002476           -0.9793
## 6           -0.21469           0.033189           -0.9778
##   tGravityAcc-std-Y tGravityAcc-std-Z tBodyAccJerk-mean-X
## 1           -0.9713           -0.9477             0.07404
## 2           -0.9721           -0.9721             0.06181
## 3           -0.9624           -0.9521             0.08147
## 4           -0.9680           -0.9630             0.07835
## 5           -0.9616           -0.9646             0.08459
## 6           -0.9642           -0.9572             0.06996
##   tBodyAccJerk-mean-Y tBodyAccJerk-mean-Z tBodyAccJerk-std-X
## 1            0.028272          -4.168e-03            -0.1136
## 2            0.018249           7.895e-03            -0.2775
## 3            0.010059          -5.623e-03            -0.2687
## 4            0.002956          -7.677e-04            -0.2970
## 5           -0.016319           8.322e-05            -0.3029
## 6           -0.016483          -7.389e-03            -0.1328
##   tBodyAccJerk-std-Y tBodyAccJerk-std-Z tBodyGyro-mean-X tBodyGyro-mean-Y
## 1           0.067003            -0.5027         -0.04183         -0.06953
## 2          -0.016602            -0.5861         -0.05303         -0.04824
## 3          -0.044962            -0.5295         -0.02564         -0.07792
## 4          -0.221165            -0.7514         -0.03180         -0.07269
## 5          -0.091040            -0.6129         -0.04889         -0.06901
## 6           0.008089            -0.5758         -0.02551         -0.07445
##   tBodyGyro-mean-Z tBodyGyro-std-X tBodyGyro-std-Y tBodyGyro-std-Z
## 1          0.08494         -0.4735        -0.05461         -0.3443
## 2          0.08283         -0.5616        -0.53845         -0.4811
## 3          0.08135         -0.5719        -0.56379         -0.4767
## 4          0.08057         -0.5009        -0.66539         -0.6626
## 5          0.08154         -0.4909        -0.50462         -0.3187
## 6          0.08388         -0.4460        -0.33170         -0.3831
##   tBodyGyroJerk-mean-X tBodyGyroJerk-mean-Y tBodyGyroJerk-mean-Z
## 1             -0.09000             -0.03984             -0.04613
## 2             -0.08188             -0.05383             -0.05149
## 3             -0.09524             -0.03879             -0.05036
## 4             -0.11532             -0.03935             -0.05512
## 5             -0.08884             -0.04496             -0.04827
## 6             -0.08789             -0.03623             -0.05396
##   tBodyGyroJerk-std-X tBodyGyroJerk-std-Y tBodyGyroJerk-std-Z
## 1             -0.2074             -0.3045             -0.4043
## 2             -0.3895             -0.6341             -0.4355
## 3             -0.3859             -0.6391             -0.5367
## 4             -0.4923             -0.8074             -0.6405
## 5             -0.3577             -0.5714             -0.1577
## 6             -0.1826             -0.4164             -0.1667
##   tBodyAccMag-mean tBodyAccMag-std tGravityAccMag-mean tGravityAccMag-std
## 1          -0.1370         -0.2197             -0.1370            -0.2197
## 2          -0.2904         -0.4225             -0.2904            -0.4225
## 3          -0.2547         -0.3284             -0.2547            -0.3284
## 4          -0.3121         -0.5277             -0.3121            -0.5277
## 5          -0.1583         -0.3772             -0.1583            -0.3772
## 6          -0.1668         -0.2667             -0.1668            -0.2667
##   tBodyAccJerkMag-mean tBodyAccJerkMag-std tBodyGyroMag-mean
## 1              -0.1414            -0.07447           -0.1610
## 2              -0.2814            -0.16415           -0.4465
## 3              -0.2800            -0.13992           -0.4664
## 4              -0.3667            -0.31692           -0.4978
## 5              -0.2883            -0.28224           -0.3559
## 6              -0.1951            -0.07060           -0.2812
##   tBodyGyroMag-std tBodyGyroJerkMag-mean tBodyGyroJerkMag-std
## 1          -0.1870               -0.2987              -0.3253
## 2          -0.5530               -0.5479              -0.5578
## 3          -0.5615               -0.5661              -0.5674
## 4          -0.5531               -0.6813              -0.7301
## 5          -0.4922               -0.4445              -0.4892
## 6          -0.3656               -0.3213              -0.3647
##   fBodyAcc-mean-X fBodyAcc-mean-Y fBodyAcc-mean-Z fBodyAcc-std-X
## 1         -0.2028         0.08971         -0.3316        -0.3191
## 2         -0.3460        -0.02190         -0.4538        -0.4577
## 3         -0.3166        -0.08130         -0.4124        -0.3793
## 4         -0.4267        -0.14940         -0.6310        -0.4472
## 5         -0.2878         0.00946         -0.4903        -0.2975
## 6         -0.1879         0.14078         -0.4985        -0.3452
##   fBodyAcc-std-Y fBodyAcc-std-Z fBodyAcc-meanFreq-X fBodyAcc-meanFreq-Y
## 1        0.05604        -0.2797             -0.2075            0.113094
## 2       -0.16922        -0.4552             -0.1458            0.198586
## 3       -0.12403        -0.4230             -0.2466            0.171743
## 4       -0.10180        -0.5942             -0.1386            0.012348
## 5        0.04260        -0.4831             -0.3224           -0.002041
## 6        0.10170        -0.5505             -0.1968            0.022073
##   fBodyAcc-meanFreq-Z fBodyAccJerk-mean-X fBodyAccJerk-mean-Y
## 1             0.04973             -0.1705            -0.03523
## 2             0.06890             -0.3046            -0.07876
## 3             0.07485             -0.3047            -0.14051
## 4            -0.07879             -0.3589            -0.27955
## 5             0.02474             -0.3450            -0.18106
## 6             0.18511             -0.1509            -0.07537
##   fBodyAccJerk-mean-Z fBodyAccJerk-std-X fBodyAccJerk-std-Y
## 1             -0.4690            -0.1336           0.106740
## 2             -0.5550            -0.3143          -0.015333
## 3             -0.5141            -0.2966          -0.005615
## 4             -0.7290            -0.2973          -0.209900
## 5             -0.5905            -0.3214          -0.054521
## 6             -0.5414            -0.1927           0.031445
##   fBodyAccJerk-std-Z fBodyAccJerk-meanFreq-X fBodyAccJerk-meanFreq-Y
## 1            -0.5347                -0.20926                 -0.3862
## 2            -0.6159                -0.07271                 -0.2636
## 3            -0.5435                -0.21604                 -0.2587
## 4            -0.7724                -0.13528                 -0.3859
## 5            -0.6334                -0.35937                 -0.5340
## 6            -0.6086                -0.17830                 -0.4663
##   fBodyAccJerk-meanFreq-Z fBodyGyro-mean-X fBodyGyro-mean-Y
## 1                 -0.1855          -0.3390          -0.1031
## 2                 -0.2548          -0.4297          -0.5548
## 3                 -0.3469          -0.4378          -0.5615
## 4                 -0.3257          -0.3734          -0.6885
## 5                 -0.3442          -0.3727          -0.5140
## 6                 -0.1041          -0.2397          -0.3414
##   fBodyGyro-mean-Z fBodyGyro-std-X fBodyGyro-std-Y fBodyGyro-std-Z
## 1          -0.2559         -0.5167        -0.03351         -0.4366
## 2          -0.3967         -0.6041        -0.53305         -0.5599
## 3          -0.4181         -0.6151        -0.56889         -0.5459
## 4          -0.6014         -0.5426        -0.65466         -0.7165
## 5          -0.2131         -0.5294        -0.50268         -0.4204
## 6          -0.2036         -0.5153        -0.33201         -0.5122
##   fBodyGyro-meanFreq-X fBodyGyro-meanFreq-Y fBodyGyro-meanFreq-Z
## 1              0.01478             -0.06577            0.0007733
## 2              0.00728             -0.04270            0.1397521
## 3              0.03376             -0.03799           -0.0445080
## 4             -0.12715             -0.27467            0.1498515
## 5             -0.04586             -0.01919            0.1674578
## 6              0.09124              0.04163            0.3028749
##   fBodyAccMag-mean fBodyAccMag-std fBodyAccMag-meanFreq
## 1          -0.1286         -0.3980               0.1906
## 2          -0.3243         -0.5771               0.3932
## 3          -0.2900         -0.4564               0.1135
## 4          -0.4508         -0.6512               0.3821
## 5          -0.3050         -0.5196               0.1499
## 6          -0.2014         -0.4217               0.2001
##   fBodyBodyAccJerkMag-mean fBodyBodyAccJerkMag-std
## 1                 -0.05712                -0.10349
## 2                 -0.16906                -0.16409
## 3                 -0.18676                -0.08985
## 4                 -0.31859                -0.32046
## 5                 -0.26948                -0.30569
## 6                 -0.05540                -0.09650
##   fBodyBodyAccJerkMag-meanFreq fBodyBodyGyroMag-mean fBodyBodyGyroMag-std
## 1                     0.093822               -0.1993              -0.3210
## 2                     0.207501               -0.5307              -0.6518
## 3                    -0.117164               -0.5698              -0.6326
## 4                     0.111486               -0.6093              -0.5939
## 5                    -0.004973               -0.4843              -0.5897
## 6                    -0.009229               -0.3297              -0.5106
##   fBodyBodyGyroMag-meanFreq fBodyBodyGyroJerkMag-mean
## 1                   0.26884                   -0.3193
## 2                   0.30528                   -0.5832
## 3                   0.18095                   -0.6078
## 4                   0.06973                   -0.7243
## 5                   0.25062                   -0.5481
## 6                   0.29311                   -0.3665
##   fBodyBodyGyroJerkMag-std fBodyBodyGyroJerkMag-meanFreq activityLabel
## 1                  -0.3816                       0.19066       WALKING
## 2                  -0.5581                       0.12634       WALKING
## 3                  -0.5491                       0.04576       WALKING
## 4                  -0.7578                       0.26536       WALKING
## 5                  -0.4557                       0.05273       WALKING
## 6                  -0.4081                       0.10092       WALKING
```


There are 30 unique subjects.

```r
unique(fileDataMerge$subjectCode)
```

```
##  [1]  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23
## [24] 24 25 26 27 28 29 30
```


There are 6 unique activities.

```r
unique(fileDataMerge$activityLabel)
```

```
## [1] "WALKING"            "WALKING_UPSTAIRS"   "WALKING_DOWNSTAIRS"
## [4] "SITTING"            "STANDING"           "LAYING"
```


There are 79 numeric factors. This is a subset of the original 561 varibales. These varibales were chosen as per instrunctions, to extracts only the measurements on the mean and standard deviation for each measurement. Summary satistics are below.


```r
summary(subset(fileDataMerge, select = 3:81))
```

```
##  tBodyAcc-mean-X tBodyAcc-mean-Y    tBodyAcc-mean-Z   tBodyAcc-std-X  
##  Min.   :0.222   Min.   :-0.04051   Min.   :-0.1525   Min.   :-0.996  
##  1st Qu.:0.271   1st Qu.:-0.02002   1st Qu.:-0.1121   1st Qu.:-0.980  
##  Median :0.277   Median :-0.01726   Median :-0.1082   Median :-0.753  
##  Mean   :0.274   Mean   :-0.01788   Mean   :-0.1092   Mean   :-0.558  
##  3rd Qu.:0.280   3rd Qu.:-0.01494   3rd Qu.:-0.1044   3rd Qu.:-0.198  
##  Max.   :0.301   Max.   :-0.00131   Max.   :-0.0754   Max.   : 0.627  
##  tBodyAcc-std-Y    tBodyAcc-std-Z   tGravityAcc-mean-X tGravityAcc-mean-Y
##  Min.   :-0.9902   Min.   :-0.988   Min.   :-0.680     Min.   :-0.4799   
##  1st Qu.:-0.9421   1st Qu.:-0.950   1st Qu.: 0.838     1st Qu.:-0.2332   
##  Median :-0.5090   Median :-0.652   Median : 0.921     Median :-0.1278   
##  Mean   :-0.4605   Mean   :-0.576   Mean   : 0.698     Mean   :-0.0162   
##  3rd Qu.:-0.0308   3rd Qu.:-0.231   3rd Qu.: 0.942     3rd Qu.: 0.0877   
##  Max.   : 0.6169   Max.   : 0.609   Max.   : 0.975     Max.   : 0.9566   
##  tGravityAcc-mean-Z tGravityAcc-std-X tGravityAcc-std-Y tGravityAcc-std-Z
##  Min.   :-0.4951    Min.   :-0.997    Min.   :-0.994    Min.   :-0.991   
##  1st Qu.:-0.1173    1st Qu.:-0.983    1st Qu.:-0.971    1st Qu.:-0.961   
##  Median : 0.0238    Median :-0.970    Median :-0.959    Median :-0.945   
##  Mean   : 0.0741    Mean   :-0.964    Mean   :-0.952    Mean   :-0.936   
##  3rd Qu.: 0.1495    3rd Qu.:-0.951    3rd Qu.:-0.937    3rd Qu.:-0.918   
##  Max.   : 0.9579    Max.   :-0.830    Max.   :-0.644    Max.   :-0.610   
##  tBodyAccJerk-mean-X tBodyAccJerk-mean-Y tBodyAccJerk-mean-Z
##  Min.   :0.0427      Min.   :-0.03869    Min.   :-0.06746   
##  1st Qu.:0.0740      1st Qu.: 0.00047    1st Qu.:-0.01060   
##  Median :0.0764      Median : 0.00947    Median :-0.00386   
##  Mean   :0.0795      Mean   : 0.00757    Mean   :-0.00495   
##  3rd Qu.:0.0833      3rd Qu.: 0.01340    3rd Qu.: 0.00196   
##  Max.   :0.1302      Max.   : 0.05682    Max.   : 0.03805   
##  tBodyAccJerk-std-X tBodyAccJerk-std-Y tBodyAccJerk-std-Z
##  Min.   :-0.995     Min.   :-0.990     Min.   :-0.993    
##  1st Qu.:-0.983     1st Qu.:-0.972     1st Qu.:-0.983    
##  Median :-0.810     Median :-0.776     Median :-0.884    
##  Mean   :-0.595     Mean   :-0.565     Mean   :-0.736    
##  3rd Qu.:-0.223     3rd Qu.:-0.148     3rd Qu.:-0.512    
##  Max.   : 0.544     Max.   : 0.355     Max.   : 0.031    
##  tBodyGyro-mean-X  tBodyGyro-mean-Y  tBodyGyro-mean-Z  tBodyGyro-std-X 
##  Min.   :-0.2058   Min.   :-0.2042   Min.   :-0.0724   Min.   :-0.994  
##  1st Qu.:-0.0471   1st Qu.:-0.0896   1st Qu.: 0.0747   1st Qu.:-0.974  
##  Median :-0.0287   Median :-0.0732   Median : 0.0851   Median :-0.789  
##  Mean   :-0.0324   Mean   :-0.0743   Mean   : 0.0874   Mean   :-0.692  
##  3rd Qu.:-0.0168   3rd Qu.:-0.0611   3rd Qu.: 0.1018   3rd Qu.:-0.441  
##  Max.   : 0.1927   Max.   : 0.0275   Max.   : 0.1791   Max.   : 0.268  
##  tBodyGyro-std-Y  tBodyGyro-std-Z  tBodyGyroJerk-mean-X
##  Min.   :-0.994   Min.   :-0.986   Min.   :-0.1572     
##  1st Qu.:-0.963   1st Qu.:-0.961   1st Qu.:-0.1032     
##  Median :-0.802   Median :-0.801   Median :-0.0987     
##  Mean   :-0.653   Mean   :-0.616   Mean   :-0.0961     
##  3rd Qu.:-0.420   3rd Qu.:-0.311   3rd Qu.:-0.0911     
##  Max.   : 0.476   Max.   : 0.565   Max.   :-0.0221     
##  tBodyGyroJerk-mean-Y tBodyGyroJerk-mean-Z tBodyGyroJerk-std-X
##  Min.   :-0.0768      Min.   :-0.09250     Min.   :-0.997     
##  1st Qu.:-0.0455      1st Qu.:-0.06172     1st Qu.:-0.980     
##  Median :-0.0411      Median :-0.05343     Median :-0.840     
##  Mean   :-0.0427      Mean   :-0.05480     Mean   :-0.704     
##  3rd Qu.:-0.0384      3rd Qu.:-0.04898     3rd Qu.:-0.463     
##  Max.   :-0.0132      Max.   :-0.00694     Max.   : 0.179     
##  tBodyGyroJerk-std-Y tBodyGyroJerk-std-Z tBodyAccMag-mean 
##  Min.   :-0.997      Min.   :-0.995      Min.   :-0.9865  
##  1st Qu.:-0.983      1st Qu.:-0.985      1st Qu.:-0.9573  
##  Median :-0.894      Median :-0.861      Median :-0.4829  
##  Mean   :-0.764      Mean   :-0.710      Mean   :-0.4973  
##  3rd Qu.:-0.586      3rd Qu.:-0.474      3rd Qu.:-0.0919  
##  Max.   : 0.296      Max.   : 0.193      Max.   : 0.6446  
##  tBodyAccMag-std  tGravityAccMag-mean tGravityAccMag-std
##  Min.   :-0.987   Min.   :-0.9865     Min.   :-0.987    
##  1st Qu.:-0.943   1st Qu.:-0.9573     1st Qu.:-0.943    
##  Median :-0.607   Median :-0.4829     Median :-0.607    
##  Mean   :-0.544   Mean   :-0.4973     Mean   :-0.544    
##  3rd Qu.:-0.209   3rd Qu.:-0.0919     3rd Qu.:-0.209    
##  Max.   : 0.428   Max.   : 0.6446     Max.   : 0.428    
##  tBodyAccJerkMag-mean tBodyAccJerkMag-std tBodyGyroMag-mean
##  Min.   :-0.993       Min.   :-0.995      Min.   :-0.981   
##  1st Qu.:-0.981       1st Qu.:-0.977      1st Qu.:-0.946   
##  Median :-0.817       Median :-0.801      Median :-0.655   
##  Mean   :-0.608       Mean   :-0.584      Mean   :-0.565   
##  3rd Qu.:-0.246       3rd Qu.:-0.217      3rd Qu.:-0.216   
##  Max.   : 0.434       Max.   : 0.451      Max.   : 0.418   
##  tBodyGyroMag-std tBodyGyroJerkMag-mean tBodyGyroJerkMag-std
##  Min.   :-0.981   Min.   :-0.9973       Min.   :-0.998      
##  1st Qu.:-0.948   1st Qu.:-0.9852       1st Qu.:-0.981      
##  Median :-0.742   Median :-0.8648       Median :-0.881      
##  Mean   :-0.630   Mean   :-0.7364       Mean   :-0.755      
##  3rd Qu.:-0.360   3rd Qu.:-0.5119       3rd Qu.:-0.577      
##  Max.   : 0.300   Max.   : 0.0876       Max.   : 0.250      
##  fBodyAcc-mean-X  fBodyAcc-mean-Y   fBodyAcc-mean-Z  fBodyAcc-std-X  
##  Min.   :-0.995   Min.   :-0.9890   Min.   :-0.990   Min.   :-0.997  
##  1st Qu.:-0.979   1st Qu.:-0.9536   1st Qu.:-0.962   1st Qu.:-0.982  
##  Median :-0.769   Median :-0.5950   Median :-0.724   Median :-0.747  
##  Mean   :-0.576   Mean   :-0.4887   Mean   :-0.630   Mean   :-0.552  
##  3rd Qu.:-0.217   3rd Qu.:-0.0634   3rd Qu.:-0.318   3rd Qu.:-0.197  
##  Max.   : 0.537   Max.   : 0.5242   Max.   : 0.281   Max.   : 0.658  
##  fBodyAcc-std-Y    fBodyAcc-std-Z   fBodyAcc-meanFreq-X
##  Min.   :-0.9907   Min.   :-0.987   Min.   :-0.636     
##  1st Qu.:-0.9404   1st Qu.:-0.946   1st Qu.:-0.392     
##  Median :-0.5134   Median :-0.644   Median :-0.257     
##  Mean   :-0.4815   Mean   :-0.582   Mean   :-0.232     
##  3rd Qu.:-0.0791   3rd Qu.:-0.266   3rd Qu.:-0.061     
##  Max.   : 0.5602   Max.   : 0.687   Max.   : 0.159     
##  fBodyAcc-meanFreq-Y fBodyAcc-meanFreq-Z fBodyAccJerk-mean-X
##  Min.   :-0.3795     Min.   :-0.5201     Min.   :-0.995     
##  1st Qu.:-0.0813     1st Qu.:-0.0363     1st Qu.:-0.983     
##  Median : 0.0079     Median : 0.0658     Median :-0.813     
##  Mean   : 0.0115     Mean   : 0.0437     Mean   :-0.614     
##  3rd Qu.: 0.0863     3rd Qu.: 0.1754     3rd Qu.:-0.282     
##  Max.   : 0.4665     Max.   : 0.4025     Max.   : 0.474     
##  fBodyAccJerk-mean-Y fBodyAccJerk-mean-Z fBodyAccJerk-std-X
##  Min.   :-0.989      Min.   :-0.992      Min.   :-0.995    
##  1st Qu.:-0.973      1st Qu.:-0.980      1st Qu.:-0.985    
##  Median :-0.782      Median :-0.871      Median :-0.825    
##  Mean   :-0.588      Mean   :-0.714      Mean   :-0.612    
##  3rd Qu.:-0.196      3rd Qu.:-0.470      3rd Qu.:-0.247    
##  Max.   : 0.277      Max.   : 0.158      Max.   : 0.477    
##  fBodyAccJerk-std-Y fBodyAccJerk-std-Z fBodyAccJerk-meanFreq-X
##  Min.   :-0.991     Min.   :-0.9931    Min.   :-0.5760        
##  1st Qu.:-0.974     1st Qu.:-0.9837    1st Qu.:-0.2897        
##  Median :-0.785     Median :-0.8951    Median :-0.0609        
##  Mean   :-0.571     Mean   :-0.7565    Mean   :-0.0691        
##  3rd Qu.:-0.169     3rd Qu.:-0.5438    3rd Qu.: 0.1766        
##  Max.   : 0.350     Max.   :-0.0062    Max.   : 0.3314        
##  fBodyAccJerk-meanFreq-Y fBodyAccJerk-meanFreq-Z fBodyGyro-mean-X
##  Min.   :-0.6020         Min.   :-0.6276         Min.   :-0.993  
##  1st Qu.:-0.3975         1st Qu.:-0.3087         1st Qu.:-0.970  
##  Median :-0.2321         Median :-0.0919         Median :-0.730  
##  Mean   :-0.2281         Mean   :-0.1376         Mean   :-0.637  
##  3rd Qu.:-0.0472         3rd Qu.: 0.0386         3rd Qu.:-0.339  
##  Max.   : 0.1957         Max.   : 0.2301         Max.   : 0.475  
##  fBodyGyro-mean-Y fBodyGyro-mean-Z fBodyGyro-std-X  fBodyGyro-std-Y 
##  Min.   :-0.994   Min.   :-0.986   Min.   :-0.995   Min.   :-0.994  
##  1st Qu.:-0.970   1st Qu.:-0.962   1st Qu.:-0.975   1st Qu.:-0.960  
##  Median :-0.814   Median :-0.791   Median :-0.809   Median :-0.796  
##  Mean   :-0.677   Mean   :-0.604   Mean   :-0.711   Mean   :-0.645  
##  3rd Qu.:-0.446   3rd Qu.:-0.264   3rd Qu.:-0.481   3rd Qu.:-0.415  
##  Max.   : 0.329   Max.   : 0.492   Max.   : 0.197   Max.   : 0.646  
##  fBodyGyro-std-Z  fBodyGyro-meanFreq-X fBodyGyro-meanFreq-Y
##  Min.   :-0.987   Min.   :-0.3958      Min.   :-0.6668     
##  1st Qu.:-0.964   1st Qu.:-0.2134      1st Qu.:-0.2943     
##  Median :-0.822   Median :-0.1155      Median :-0.1579     
##  Mean   :-0.658   Mean   :-0.1046      Mean   :-0.1674     
##  3rd Qu.:-0.392   3rd Qu.: 0.0027      3rd Qu.:-0.0427     
##  Max.   : 0.522   Max.   : 0.2492      Max.   : 0.2731     
##  fBodyGyro-meanFreq-Z fBodyAccMag-mean fBodyAccMag-std 
##  Min.   :-0.5075      Min.   :-0.987   Min.   :-0.988  
##  1st Qu.:-0.1548      1st Qu.:-0.956   1st Qu.:-0.945  
##  Median :-0.0508      Median :-0.670   Median :-0.651  
##  Mean   :-0.0572      Mean   :-0.536   Mean   :-0.621  
##  3rd Qu.: 0.0415      3rd Qu.:-0.162   3rd Qu.:-0.365  
##  Max.   : 0.3771      Max.   : 0.587   Max.   : 0.179  
##  fBodyAccMag-meanFreq fBodyBodyAccJerkMag-mean fBodyBodyAccJerkMag-std
##  Min.   :-0.3123      Min.   :-0.994           Min.   :-0.994         
##  1st Qu.:-0.0147      1st Qu.:-0.977           1st Qu.:-0.975         
##  Median : 0.0813      Median :-0.794           Median :-0.813         
##  Mean   : 0.0761      Mean   :-0.576           Mean   :-0.599         
##  3rd Qu.: 0.1744      3rd Qu.:-0.187           3rd Qu.:-0.267         
##  Max.   : 0.4358      Max.   : 0.538           Max.   : 0.316         
##  fBodyBodyAccJerkMag-meanFreq fBodyBodyGyroMag-mean fBodyBodyGyroMag-std
##  Min.   :-0.1252              Min.   :-0.987        Min.   :-0.982      
##  1st Qu.: 0.0453              1st Qu.:-0.962        1st Qu.:-0.949      
##  Median : 0.1720              Median :-0.766        Median :-0.773      
##  Mean   : 0.1625              Mean   :-0.667        Mean   :-0.672      
##  3rd Qu.: 0.2759              3rd Qu.:-0.409        3rd Qu.:-0.428      
##  Max.   : 0.4881              Max.   : 0.204        Max.   : 0.237      
##  fBodyBodyGyroMag-meanFreq fBodyBodyGyroJerkMag-mean
##  Min.   :-0.4566           Min.   :-0.998           
##  1st Qu.:-0.1695           1st Qu.:-0.981           
##  Median :-0.0535           Median :-0.878           
##  Mean   :-0.0360           Mean   :-0.756           
##  3rd Qu.: 0.0823           3rd Qu.:-0.583           
##  Max.   : 0.4095           Max.   : 0.147           
##  fBodyBodyGyroJerkMag-std fBodyBodyGyroJerkMag-meanFreq
##  Min.   :-0.998           Min.   :-0.1829              
##  1st Qu.:-0.980           1st Qu.: 0.0542              
##  Median :-0.894           Median : 0.1116              
##  Mean   :-0.771           Mean   : 0.1259              
##  3rd Qu.:-0.608           3rd Qu.: 0.2081              
##  Max.   : 0.288           Max.   : 0.4263
```


Boxplots of the variables are below. (Visible only in html version)


```r
par(mfrow = c(10, 8), mar = c(1, 1, 1, 1))
for (i in 3:81) {
    boxplot(fileDataMerge[[i]])
}
```

![plot of chunk unnamed-chunk-16](figure/unnamed-chunk-16.png) 


### Result

A tidy dataset, suitable for further anlayis has been created.

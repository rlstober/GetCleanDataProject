##run_analysis
        ## get files and merge
        ## X indicates dataset, y indicates activity column to add 
        ## S is subject coliumn to add
        
        ## get training data        
        fileTrainX<-read.table("X_train.txt")
        fileTrainY<-read.table("y_train.txt")
        fileTrainS<-read.table("subject_train.txt")
        
        ## get test data
        fileTestX<-read.table("X_test.txt")
        fileTestY<-read.table("y_test.txt")
        fileTestS<-read.table("subject_test.txt")
        
        ##Get activities and features
        fileActivity<-read.table("activity_labels.txt", stringsAsFactors=FALSE, col.names=c("activityCode", "activityLabel"))
        fileFeatures<-read.table("features.txt", stringsAsFactors=FALSE)
        
        
        ## Combining Datasets
        
        ## add activity to test and train data
        fileTestXY<-cbind(fileTestX,fileTestY)
        fileTrainXY<-cbind(fileTrainX,fileTrainY)
        
        ## add subject to test and train data
        fileTestXYS<-cbind(fileTestXY,fileTestS)
        fileTrainXYS<-cbind(fileTrainXY,fileTrainS)
        
        ## combine test and train
        fileData<-rbind(fileTrainXYS,fileTestXYS)
        
        ## add activity and subject code to features
        fileFeatures<-rbind(fileFeatures, c(nrow(fileFeatures)+1,"activityCode"))
        fileFeatures<-rbind(fileFeatures, c(nrow(fileFeatures)+1,"subjectCode"))
        
        ## set column names
        colnames(fileData) <-fileFeatures[[2]]
        
        ##subset dataset for features with mean or stdev or code in name
        selectFeature<-(grepl("mean()",fileFeatures$V2))|(grepl("std()",fileFeatures$V2)|(grepl("Code",fileFeatures$V2)))
        fileData<-subset(fileData, select=selectFeature)
        
        ## remove parenthesis in colunnames
        fileDataCols<-colnames(fileData)
        ##escape a metacharacter in a regular expression, you precede it with a backslash.
        ##If your expression is in double quotes, then the backslash itself must be escaped by using double backslashes.
        fileDataCols<-gsub(pattern="\\(|\\)", x=fileDataCols, replacement="")
        ## Assign cleand up names to columns
        colnames(fileData) <-fileDataCols
        ##
        
        ##For each combination of activity and subject in the data, calculate the mean of those entries for each variable.
        ##This means that this data frame will have 180 rows (30 subjects * 6 activities)nb<-dcast(B,c(SubjectLabel,ActivityLabel),variable,mean)
        
        ##First melt or unpivot the dataset
        ## since we want to aggregate by subjectCode and activityCode they are the ids, default allother columns are variables
        fileDataMelt<-melt(fileData, id=c("subjectCode", "activityCode"))
        
        ## Now cast or pivot the columns and get the mean 
        fileDataCast<-dcast(fileDataMelt,activityCode+subjectCode~variable,mean)
        
        ## mere or join the dataset to get activity labels
        ## join by activity code which is common column to both datasets
        fileDataMerge<-merge(fileDataCast, fileActivity, by="activityCode")## write data to tab delimited text file
        write.table(fileDataMerge, "tidydata.txt", sep="\t")
        
        ## print structure to screen
        str(fileDataMerge)

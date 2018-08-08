tbl_df2row <- function(data){
  data <- as.data.frame(data)
  data <- rename(data, c("obsValue"="value"))
  data <- cast(data, formula = VARIABLE+LOCATION+FREQUENCY+UNIT ~ obsTime)
  return(data)
}
prepare_CSV <- function(data, dstruc, filename, freq, dataset_title){
  
  VARIABLE         <- data[,1]
  COUNTRY_CODE     <- data[,2]
  COUNTRY_VARIABLE <- paste(COUNTRY_CODE, VARIABLE, freq, sep="_")
  UNIT_CODE        <- data[,4]
  
  DESCRIPTION      <- dstruc$VARIABLE$label[match(data$VARIABLE,dstruc$VARIABLE$id)]
  COUNTRY          <- dstruc$LOCATION$label[match(data$LOCATION,dstruc$LOCATION$id)]
  UNITS            <- dstruc$UNIT$label[match(data$UNIT,dstruc$UNIT$id)]
  SOURCE           <- dataset_title
  
  data             <- cbind(COUNTRY_VARIABLE,DESCRIPTION,COUNTRY,UNIT_CODE,UNITS,SOURCE,data[,5:ncol(data)])
  names(data)      <- sub("-Q","Q",names(data))
  
  return(data)
}
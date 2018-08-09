tbl_df2row <- function(data){
  data <- as.data.frame(data)
  string <- names(data)
  remove <- c("time","value")
  z <- string [! string %in% remove]
  rowized <- cast(data, formula=paste(paste(z, collapse= " + ")," ~ ..." ))
  rowized_tidy <- rowized[,c(seq(1,length(names(data))-2),seq(ncol(rowized),length(names(data))-1))]
  return(rowized_tidy)
}

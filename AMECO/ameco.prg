' -----------------------------------------------------------------------------------------------------------------------------------------------------
'	PROGRAM:	 		ameco.prg
'
'	PURPOSE: 		AMECO Add-In. 
'
' 	DATE: 				08 / 08 / 2018
'
'	AUTHOR:			Graeme Walsh
' 							Central Bank of Ireland
' -----------------------------------------------------------------------------------------------------------------------------------------------------

' ***********************************************************************************************************************
' EViews AMECO add-in graphical user interface
' ***********************************************************************************************************************

' AMECO web page (Note: this is the default address and can be changed by the user in the @uidialog if necessary.)
  %webpage = "https://ec.europa.eu/info/business-economy-euro/indicators-statistics/economic-databases/macro-economic-database-ameco/download-annual-data-set-macro-economic-database-ameco_en"

' EViews AMECO add-in user interface dialog
  !button = @uidialog(	"Caption","AMECO Add-In", _
  					"Text","--------------------------------------------------------", _
  					"Text","Welcome to the AMECO add-in for EViews 10.", _
  					"Text","--------------------------------------------------------", _
  					"Text","This add-in imports the latest AMECO database into EViews as a workfile object.", _
  					"Text","The data is retrieved from the address shown below.", _
  					"Edit",%webpage,"",200, _
  					"Text", "Warning: Do not edit this URL unless necessary!", _
  					"colbreak", _
  					"Text","--------------------------------------------------------", _
  					"Text","                          Further details.", _
  					"Text","--------------------------------------------------------", _
  					"Text","This add-in uses the EViews R Connector Interface.", _
  					"Text","Please read the add-in documentation for more details.", _
  					"Text","Created by: Graeme Walsh", _
  					"Text","Version: 1.0", _
  					"Text","Released: August 2018")

' Stop the add-in if user chooses to cancel, otherwise proceed.
  if !button = -1 then
  	stop
  endif 

' ***********************************************************************************************************************
' R Programming
' ***********************************************************************************************************************

' Open EViews / R interface
  xopen(type=r)

' Switch on R commands  
  xon

' Read the AMECO web page (Note: do this to find (1) last update string and (2) the zip file address) 
  ameco_web <- %webpage
  temp2 <- tempfile()
  download.file(ameco_web, temp2)
  AMECO_HTML <- paste(readLines(temp2))

' Find the last update string (Note: this info is returned to the user using a @uiprompt.)
  last_update_html <- AMECO_HTML[grep("Last update:",AMECO_HTML)]
  last_update_str  <- gsub(".*<p>|</p>.*", "", last_update_html)

' Find the zip file address
  x <- AMECO_HTML[grep(".zip",AMECO_HTML,fixed = TRUE)[1]]
  ameco_zip <- gsub(".*href=\"|\">.*", "", x)

' Download all of the AMECO zipped text files using R's temp facilities
  temp1 <- tempfile()
  download.file(ameco_zip, temp1)
  zipped_files <- unzip(temp1, list=TRUE)
  func <- function(x) read.csv(unz(temp1, x), header=TRUE, sep=";")
  AMECO <- lapply(zipped_files$Name,func)

' Reshape the data and do some tidying up  
  df <- do.call(rbind,AMECO)
  colnames(df) <- gsub("X","",colnames(df))
  df <- df[,-ncol(df)]

' Save the data as a CSV file using R's temp facilities
  temp3 <- tempfile(fileext=".csv")
  write.csv2(df,file=temp3,row.names=FALSE)

' Switch off R commands
  xoff

' ***********************************************************************************************************************
' EViews Programming
' ***********************************************************************************************************************

' Pass information from R to EViews
  xget(wf=tempwf,name=temp3) temp3
  xget(wf=tempwf,name=last_update_str) last_update_str
  %temp3 = temp3
  %last_update_str = last_update_str
  wfclose tempwf

' Import the CSV temp file
  import(wf=AMECO,page=Data) %temp3 ftype=ascii rectype=crlf skip=0 fieldtype=delimited na="NA" custom=";" byrow colhead=5 namepos=custom colheadnames=("Name","Country","Sub Chapter","Description","Units") eoltype=pad badfield=NA @freq A @id @date(code) @smpl @all
  wfdetails "Name" "Type" "Country" "Sub Chapter" "Description" "Units" "Start" "End"

' Notify the user when the AMECO database was last updated
  @uiprompt(%last_update_str)

' Close EViews / R interface
  xclose

' -----------------------------------------------------------------------------------------------------------------------------------------------------
'	END OF PROGRAM
' -----------------------------------------------------------------------------------------------------------------------------------------------------

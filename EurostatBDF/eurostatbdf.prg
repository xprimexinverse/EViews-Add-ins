' -----------------------------------------------------------------------------------------------------------------------------------------------------
'	PROGRAM:	 		eurostat_bdf.prg
'
'	PURPOSE: 		EurostatBDF Add-In. 
'
' 	DATE: 				18 / 08 / 2018
'
'	AUTHOR:			Graeme Walsh
' 							Central Bank of Ireland
' -----------------------------------------------------------------------------------------------------------------------------------------------------

' ***********************************************************************************************************************
' EViews EurostatBDF add-in graphical user interface
' ***********************************************************************************************************************

' EViews AMECO add-in user interface dialog
  !button = @uidialog(	"Caption","EurostatBDF Add-In", _
  					"Text","--------------------------------------------------------", _
  					"Text","Welcome to the EurostatBDF add-in for EViews 10.", _
  					"Text","--------------------------------------------------------", _
  					"Text","This add-in imports datasets from the Eurostat Bulk Download Facility into EViews as a workfile object.", _
  					"Text","Choose a dataset:", _
  					"Edit",%dataset_name,"",200, _
  					"Text", "", _
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

' Pass the dataset name to R
  dataset_name <- %dataset_name

' Load the EurostatBDF package
  source("https://raw.githubusercontent.com/xprimexinverse/EurostatBDF/master/R/EurostatBDF.R")

' Get the dataset from the Eurostat Bulk Download Facility
  eurostat_dataset <- getEurostat(dataset_name, append_csv=TRUE)

' Extract the dataframe
  df <- eurostat_dataset$csv_data

' Save the data as a CSV file using R's temp facilities
  temp <- tempfile(fileext=".csv")
  write.csv(df, file=temp, row.names=FALSE)

' Get dataset frequency
  period <- getPeriod(dataset_name)
  freq <- as.character(period$freq)

' Get column header properties
  colhead <- getColhead(df)
  colheadnames <- colhead$names
  colheadnum <- colhead$num
  details <- gsub(",","",colheadnames)

' Switch off R commands
  xoff

' ***********************************************************************************************************************
' EViews Programming
' ***********************************************************************************************************************

' Pass information from R to EViews
  xget(wf=tempwf,name=temp) temp
  xget(wf=tempwf,name=colheadnames) colheadnames
  xget(wf=tempwf,name=colheadnum) colheadnum
  xget(wf=tempwf,name=freq) freq
  xget(wf=tempwf,name=details) details
  %temp = temp
  %colheadnames = colheadnames
  !colheadnum = colheadnum
  %freq = freq
  %details = details
  wfclose tempwf

' Import the CSV temp file
  import(wf=%dataset_name,page=%dataset_name) %temp ftype=ascii rectype=crlf skip=0 fieldtype=delimited na="NA" delim=comma byrow colhead=!colheadnum namepos=custom colheadnames=({%colheadnames}) eoltype=pad badfield=NA @freq {%freq} @id @date(identifier) @smpl @all  
  wfdetails {%details}

' Close EViews / R interface
  xclose

' -----------------------------------------------------------------------------------------------------------------------------------------------------
'	END OF PROGRAM
' -----------------------------------------------------------------------------------------------------------------------------------------------------

' -----------------------------------------------------------------------------------------------------------------------------------------------------
'	PROGRAM:	 		oecd.prg
'
'	PURPOSE: 		OECD Add-In. 
'
' 	DATE: 				08 / 08 / 2018
'
'	AUTHOR:			Graeme Walsh
' 							Central Bank of Ireland
' -----------------------------------------------------------------------------------------------------------------------------------------------------

' ***********************************************************************************************************************
' R Programming
' ***********************************************************************************************************************

' Open EViews / R interface
  xopen(type=r)

' Install dependencies (if necessary)
  xpackage OECD
  xpackage reshape

' Switch on R commands  
  xon

' Load dependencies
  library(OECD)
  library(reshape)
  source("https://raw.githubusercontent.com/xprimexinverse/EViews-Add-ins/master/OECD/OCED_misc.R")

' Use OECD package to retrieve the list of OECD datasets
  dataset_list <- get_datasets() 

' Search for OECD Economic Outlooks
  outlook_versions <- search_dataset("economic outlook", data = dataset_list)

' Get the name of the latest OECD Economic Outlooks
  latest_outlook1 <- tail(outlook_versions, n = 5)[1,]
  latest_outlook2 <- tail(outlook_versions, n = 5)[2,]
  latest_outlook3 <- tail(outlook_versions, n = 5)[3,]
  latest_outlook4 <- tail(outlook_versions, n = 5)[4,]
  latest_outlook5 <- tail(outlook_versions, n = 5)[5,]

' Switch off R commands
  xoff

' Pass information from R to EViews
  xget(wf=tempwf,name=latest_outlook1) as.character(latest_outlook1$title)
  %latest_outlook1 = latest_outlook1
  xget(wf=tempwf,name=latest_outlook2) as.character(latest_outlook2$title)
  %latest_outlook2 = latest_outlook2
  xget(wf=tempwf,name=latest_outlook3) as.character(latest_outlook3$title)
  %latest_outlook3 = latest_outlook3
  xget(wf=tempwf,name=latest_outlook4) as.character(latest_outlook4$title)
  %latest_outlook4 = latest_outlook4
  xget(wf=tempwf,name=latest_outlook5) as.character(latest_outlook5$title)
  %latest_outlook5 = latest_outlook5
  %latest_outlooks = @addquotes(%latest_outlook1) + " " + @addquotes(%latest_outlook2) + " " + @addquotes(%latest_outlook3) + " " + @addquotes(%latest_outlook4) + " " + @addquotes(%latest_outlook5)

' ***********************************************************************************************************************
' EViews OECD add-in graphical user interface
' ***********************************************************************************************************************
  
' List selection variable
  !selection = 5

' EViews OECD add-in user interface dialog
  !button = @uidialog(	"Caption","OECD Add-In", _
  					"Text","----------------------------------------------------------------------------------------------------------------------", _
  					"Text","                          Welcome to the OECD add-in for EViews 10.", _
  					"Text","----------------------------------------------------------------------------------------------------------------------", _
  					"Text","This add-in imports the OECD Economic Outlook database into EViews as a workfile object.", _
					"List",!selection,"Choose a dataset:",%latest_outlooks , _ 
					"Text", "Warning: The Add-in can take at least 15 minutes to finish running.", _
  					"Text","----------------------------------------------------------------------------------------------------------------------", _
  					"Text","                                              Further details.", _
  					"Text","----------------------------------------------------------------------------------------------------------------------", _
  					"Text","This add-in uses the EViews R Connector Interface.", _
  					"Text","Please read the add-in documentation for more details.", _
  					"Text","Created by: Graeme Walsh", _
  					"Text","Version: 1.0", _
  					"Text","Released: August 2018")

' Stop the add-in if user chooses to cancel, otherwise proceed.
  if !button = -1 then
     	wfclose tempwf
     	xclose
  	stop
  endif 

' Send user selection from EViews to R
  xput(rtype=vector, name=user_choice) !selection
  wfclose tempwf

' ***********************************************************************************************************************
' R Programming
' ***********************************************************************************************************************

' Switch on R commands  
  xon

' Get the name of the latest OECD Economic Outlook (based on user selection)
  latest_outlook <- tail(outlook_versions, n = 5)[user_choice[1],]
  dataset_id     <- as.character(latest_outlook$id)
  dataset_title  <- as.character(latest_outlook$title)
  dataset_title  <- gsub("[[:space:]]*$","",dataset_title)

' Retrieve the structure of the dataset
  dstruc <- get_data_structure(dataset_id)

' Retrieve the full dataset
'  filter_list <- list(dstruc$LOCATION$id,dstruc$VARIABLE$id,c("A"))
'  df <- get_dataset(dataset = dataset_id, filter = filter_list)
  df <- get_dataset(dataset = dataset_id)

' Extract the data by frequency
  DATA_A <- df[which(df$FREQUENCY=="A"),]
  DATA_Q <- df[which(df$FREQUENCY=="Q"),]

' Convert the data into row format
  DATA_A_ROWS <- tbl_df2row(DATA_A)
  DATA_Q_ROWS <- tbl_df2row(DATA_Q)

' Export to CSV files
  eo_version <- strsplit(as.character(latest_outlook$id),"_")[[1]][1]

  filename_a <- paste0(eo_version,"_A.csv")
  filename_q <- paste0(eo_version,"_Q.csv")

  DATA_A_ROWS <- prepare_CSV(DATA_A_ROWS, dstruc, filename_a, "A", dataset_title)
  DATA_Q_ROWS <- prepare_CSV(DATA_Q_ROWS, dstruc, filename_q, "Q", dataset_title)

' Save the data as CSV files using R's temp facilities
  temp1 <- tempfile(fileext=".csv")
  write.csv2(DATA_A_ROWS,file=temp1,row.names=FALSE)
  temp2 <- tempfile(fileext=".csv")
  write.csv2(DATA_Q_ROWS,file=temp2,row.names=FALSE)
  
' Check on quarterly data
  Q_EXIST <- nrow(DATA_Q_ROWS) > 50

' Switch off R commands
  xoff

' ***********************************************************************************************************************
' EViews Programming
' ***********************************************************************************************************************

' Pass information from R to EViews
  xget(wf=tempwf,name=temp1) temp1
  xget(wf=tempwf,name=temp2) temp2
  xget(wf=tempwf,name=latest_outlook) as.character(latest_outlook$title)
  xget(wf=tempwf,name=Q_EXIST) as.character(Q_EXIST)
  %temp1 = temp1
  %temp2 = temp2
  %latest_outlook = latest_outlook
  %Q_EXIST = Q_EXIST
  wfclose tempwf

' Import the CSV temp files
  import(wf=OECD,page=Annual) %temp1 ftype=ascii rectype=crlf skip=0 fieldtype=delimited na="NA" custom=";" byrow colhead=6 namepos=custom colheadnames=("Name","Description","Country","Unit_code","Units","Source") eoltype=pad badfield=NA @freq A @id @date(country_variable) @smpl @all
  wfdetails "Name" "Type" "Country" "Description" "Units" "Start" "End" "Source" "Unit_code"
  if(%Q_EXIST = "TRUE") then
  	import(wf=OECD,page=Quarterly) %temp2 ftype=ascii rectype=crlf skip=0 fieldtype=delimited na="NA" custom=";" byrow colhead=6 namepos=custom colheadnames=("Name","Description","Country","Unit_code","Units","Source") eoltype=pad badfield=NA @freq Q @id @date(country_variable) @smpl @all
  	wfdetails "Name" "Type" "Country" "Description" "Units" "Start" "End" "Source" "Unit_code"
  endif

' Notify the user which version of the database has been loaded
  @uiprompt(%latest_outlook)

' Close EViews / R interface
  xclose

' -----------------------------------------------------------------------------------------------------------------------------------------------------
'	END OF PROGRAM
' -----------------------------------------------------------------------------------------------------------------------------------------------------



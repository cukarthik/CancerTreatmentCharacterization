Large-Scale Data Analysis to Characterize Variations in Cancer Treatments Across the United States.
==============================

<img src="https://camo.githubusercontent.com/5d52cd64255f470de0b6acd048f408decd5c3c2f445c5e5524052a8f4b1a79d5/68747470733a2f2f696d672e736869656c64732e696f2f62616467652f53747564792532305374617475732d537461727465642d626c75652e737667" alt="Study Status: Started"> 

- Analytics use case(s): **Characterization** 
- Study type: **Clinical Application**
- Tags: **oncology**
- Study lead: **Thomas Falconer** and **Karthik Natarajan**
- Study lead forums tag: **[thomasfalconer](https://forums.ohdsi.org/u/thomasfalconer/summary)**
- Study start date: **October 21, 2021**
- Study end date: **-**
- Protocol: **-**
- Publications: **-**
- Results explorer: **-**


Requirements
============

- A database in [Common Data Model version 5](https://github.com/OHDSI/CommonDataModel) in one of these platforms: SQL Server, Oracle, PostgreSQL, IBM Netezza, Apache Impala, Amazon RedShift, Google BigQuery, or Microsoft APS.
- R version 4.0 or newer
- On Windows: [RTools](http://cran.r-project.org/bin/windows/Rtools/)
- [Java](http://java.com)
- 25 GB of free disk space

See [these instructions](https://ohdsi.github.io/MethodsLibrary/rSetup.html) on how to set up the R environment on Windows.

If you have access to a claims data set please also run this study on it, which is described in the "Run Study on Claims Data" section below

Run Study 
=========
1. In `R`, use the following code to install the dependencies:

    ```r
    install.packages("devtools")
    library(devtools)
    install_github("ohdsi/SqlRender")
    install_github("ohdsi/DatabaseConnector")
    install_github("ohdsi/OhdsiSharing")
    install_github("ohdsi/FeatureExtraction")
    install_github("ohdsi/CohortMethod")
    install.packages("ggplot2")
    install.packages("ggrepel")
    install.packages("dplyr")
    install.packages("readr")
    install.packages("sqldf")
    install.packages("tidyr")
    ```

    If you experience problems on Windows where rJava can't find Java, one solution may be to add `"--no-multiarch"` to each `install_github` call, for example these are two ways to ignore the i386 architecture:
	
    ```r
    install_github("ohdsi/SqlRender", args = "--no-multiarch")
    install_github("ohdsi/SqlRender", INSTALL_opts=c("--no-multiarch"))
    ```
	
    OR for all installs, one can try:
	
    ```r
    options(devtools.install.args = "--no-multiarch")
    ```
	
    Alternatively, ensure that you have installed both 32-bit and 64-bit JDK versions, as mentioned in the [video tutorial](https://youtu.be/K9_0s2Rchbo).
	
2. In `R`, use the following `devtools` command to install the CancerTreatmentCharacterization package:

    ```r
    # install the network package
    devtools::install_github("https://github.com/cukarthik/nci-characterization")
    ```
    Alternatively, you can download the repo and build it locally in RStudio (Menu Bar: "Build" -> "Install and Restart")


4. Once installed, you can execute the study by modifying and using the code below. For your convenience, this code is also provided under `extras/CodeToRun.R`:

    ```r
    library(CancerTreatmentCharacterization)
	
    path <- 's:/CancerTreatmentCharacterization'
   
    # Optional: specify where the temporary files will be created:
    options(andromedaTempFolder = file.path(path, "andromedaTemp"))

	
    # Maximum number of cores to be used:
    maxCores <- parallel::detectCores()
	
    # Minimum cell count when exporting data:
    minCellCount <- 10
	
    # The folder where the study intermediate and result files will be written:
    outputFolder <- "c:/CancerTreatmentCharacterization"
	
    # Details for connecting to the server:
    # See ?DatabaseConnector::createConnectionDetails for help
    connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql",
                                    server = "some.server.com/ohdsi",
                                    user = "",
                                    password = "")
	
    # The name of the database schema where the CDM data can be found:
    cdmDatabaseSchema <- "cdm_synpuf"
	vocabularyDatabaseSchema <- "cdm_synpuf" #schema where your CDM vocabulary is located
   
    # The name of the database schema and table where the study-specific cohorts will be instantiated:
    cohortDatabaseSchema <- "scratch.dbo" #You mush have rights to create tables in this schema
    resultsDatabaseSchema <- "scratch.dbo" #You mush have rights to create tables in this schema
	cohortTable <- "cancer_cohorts" #Table where the person_id for the cohorts are stored
   
    # Some meta-information that will be used by the export function:
    databaseId <- ""          #SiteName
    databaseName <- ""        #SiteName_DatabaseName
    databaseDescription <- "" #Description of site's database
	
    # For Oracle: define a schema that can be used to emulate temp tables:
    oracleTempSchema <- NULL
	
    execute(connectionDetails,
            cdmDatabaseSchema,
            cohortDatabaseSchema = cohortDatabaseSchema,
            cohortTable = 	cohortTable,
            oracleTempSchema = cohortDatabaseSchema,
            outputFolder,
            databaseId = databaseId,
            databaseName = databaseName,
            databaseDescription = databaseDescription,
            reloadData = TRUE,                      #The flag lets the user reload csv data files into the resultsDatabaseSchema. 
                                                    #Note: the first time running the package, this flag should be set to TRUE
    
            createCohorts = TRUE,                   #The flag creates the cohorts. One can set it to FALSE after the first time the cohorts are created.
            runAnalyses = TRUE,                     #This flag runs the analysis. NOTE: The subsequent flags enable or disable parts of the analysis.
            buildDataSet = TRUE,                      #This flag builds the data sets used for the analysis
            runOhdsiCharacterization = TRUE,          #This flag runs the OHDSI characterization package on the cohorts to get a Table1.
            runTreatmentAnalysis = TRUE,              #This flag is the main analysis that characterizes treatment variation
            runDiagnostics = FALSE,                   #This flag runs OHDSI's CohortDiagnostics on the cohorts created
            packageResults = FALSE,
            renderMarkdown = TRUE,                    #This flag runs the treatment analysis within a RMarkdown script for each cancer and outputs the html version of the executed RMarkdown file. 
                                                      # If the variable is set to FALSE, then it executes a regular R script
            maxCores = maxCores,
            minCellCount = minCellCount)
    ```


5. To view the results, one can go to the specified output folder. There you will see a folder for each cancer (breast, prostate, lung and multiple myeloma). Within each folder, there is a _data_ and _plots_ folder. The _data_ folder contains aggregate counts that were used to generate the plots.  
	
   

  
6. Please contact both Karthik Natarajan (kn2174 at cumc dot columbia dot edu) and Thomas Falconer (tf2428 at cumc dot columbia dot edu) after the study execution or if there are any issues that arise. Currently, there is no automated method to submit the results. The plot folders will be need to be manually zipped. We will setup a meeting to review the results. 

Development
===========
CancerTreatmentCharacterization is a custom study package that was developed in R Studio. 

License
=======
The CancerTreatmentCharacterization package is licensed under Apache License 2.0
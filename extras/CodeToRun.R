# Make sure to install all dependencies (not needed if already done):
# install.packages("devtools")
# library(devtools)
# install_github("ohdsi/SqlRender")
# install_github("ohdsi/DatabaseConnector")
# install_github("ohdsi/OhdsiSharing")
# install_github("ohdsi/FeatureExtraction")
# install_github("ohdsi/CohortDiagnostics")
# install_github("ohdsi/CohortMethod")
# install.packages("ggplot2")
# install.packages("ggrepel")
# install.packages("dplyr")
# install.packages("readr")
# install.packages("sqldf")
# install.packages("tidyr")
# install.packages("rmarkdown")
# install.packages("forcats")

# Load the package
library(CancerTreatmentCharacterization)

path <- 's:/CancerTreatmentCharacterization'

# Optional: specify where the temporary files will be created:
options(andromedaTempFolder = file.path(path, "andromedaTemp"))

# Maximum number of cores to be used:
maxCores <- parallel::detectCores()

# Minimum cell count when exporting data:
minCellCount <- 10

# Details for connecting to the server:
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "sql server",
                                                                server = Sys.getenv("PDW_SERVER"),
                                                                user = NULL,
                                                                password = NULL,
                                                                port = Sys.getenv("PDW_PORT"))

# For Oracle: define a schema that can be used to emulate temp tables:
oracleTempSchema <- NULL

# Details specific to the database:
outputFolder <- "c:/CancerTreatmentCharacterization"
db <- "ohdsi_cumc_2021q2r1"
cdmDatabaseSchema <- paste0(db,".dbo") # schema for your CDM instance -- e.g. full_201911_omop_v5
resultsDatabaseSchema <- paste0(db,".results") # schema with write privileges
vocabularyDatabaseSchema <- paste0(db,".dbo") #schema where your CDM vocabulary is located
cohortTable <- "cancer_cohorts"
databaseId <- "mydb"
databaseName <- "MYDATABASE EHR Database"
databaseDescription <- ""
cohortDatabaseSchema <- paste0(db,".results")

# Use this to run the study package. To view the results, one can go to the specified output folder.
# There you will see a folder for each cancer (breast, prostate, lung and multiple myeloma).
# Within each folder, there is a data and plots folder. The data folder contains aggregate counts
# that were used to generate the plots.
execute(connectionDetails,
         cdmDatabaseSchema,
         cohortDatabaseSchema = cohortDatabaseSchema,
         cohortTable = cohortTable,
         oracleTempSchema = cohortDatabaseSchema,
         outputFolder,
         databaseId = databaseId,
         databaseName = databaseName,
         databaseDescription = databaseDescription,
         reloadData = TRUE,
         createCohorts = TRUE,
         runAnalyses = TRUE,
         buildDataSet = TRUE,
         runOhdsiCharacterization = TRUE,
         runTreatmentAnalysis = TRUE,
         runDiagnostics = FALSE,
         packageResults = FALSE,
         renderMarkdown = TRUE,
         maxCores = maxCores,
         minCellCount = minCellCount)


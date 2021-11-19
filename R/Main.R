# Copyright 2019 Observational Health Data Sciences and Informatics
#
# This file is part of NCICharacterization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute the Study
#'
#' @details
#' This function executes the IUDEHRS Study.
#' 
#' The \code{createCohorts}, \code{synthesizePositiveControls}, \code{runAnalyses}, and \code{runDiagnostics} arguments
#' are intended to be used to run parts of the full study at a time, but none of the parts are considered to be optional.
#'
#' @param connectionDetails    An object of type \code{connectionDetails} as created using the
#'                             \code{\link[DatabaseConnector]{createConnectionDetails}} function in the
#'                             DatabaseConnector package.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param oracleTempSchema     Should be used in Oracle to specify a schema where the user has write
#'                             priviliges for storing temporary tables.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param databaseId           A short string for identifying the database (e.g.
#'                             'Synpuf').
#' @param databaseName         The full name of the database (e.g. 'Medicare Claims
#'                             Synthetic Public Use Files (SynPUFs)').
#' @param databaseDescription  A short description (several sentences) of the database.
#' @param createCohorts        Create the cohortTable table with the exposure and outcome cohorts?
#' @param synthesizePositiveControls  Should positive controls be synthesized?
#' @param runAnalyses          Perform the cohort method analyses?
#' @param runDiagnostics       Compute study diagnostics?
#' @param packageResults       Should results be packaged for later sharing?     
#' @param maxCores             How many parallel cores should be used? If more cores are made available
#'                             this can speed up the analyses.
#' @param minCellCount         The minimum number of subjects contributing to a count before it can be included 
#'                             in packaged results.
#'
#' @examples
#' \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         cohortDatabaseSchema = "study_results",
#'         cohortTable = "cohort",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results",
#'         maxCores = 4)
#' }
#'
#' @export
execute <- function(connectionDetails,
                    cdmDatabaseSchema,
                    cohortDatabaseSchema = cohortDatabaseSchema,
                    cohortTable = "cancer_cohorts",
                    oracleTempSchema = cohortDatabaseSchema,
                    outputFolder,
                    databaseId = "Unknown",
                    databaseName = "Unknown",
                    databaseDescription = "Unknown",
                    reloadData = TRUE,
                    createCohorts = TRUE,
                    runAnalyses = TRUE,
                    buildDataSet = TRUE,
                    runOhdsiCharacterization = TRUE,
                    runTreatmentAnalysis = TRUE,
                    runDiagnostics = TRUE,
                    packageResults = TRUE,
                    renderMarkdown = FALSE,
                    maxCores = 4,
                    minCellCount = 5) {

  connection <- DatabaseConnector::connect(connectionDetails)

  #initialize study by loading necessary supporting files
  cohortTable <- "cancer_cohorts"
  package <- "CancerTreatmentCharacterization"
  ParallelLogger::logInfo("Initializing Study")
  initializeStudy(outputFolder, connection, cohortDatabaseSchema, oracleTempSchema, package, reloadData)

  on.exit(ParallelLogger::unregisterLogger("DEFAULT_FILE_LOGGER", silent = TRUE))
  on.exit(ParallelLogger::unregisterLogger("DEFAULT_ERRORREPORT_LOGGER", silent = TRUE), add = TRUE)

  #Create cancer cohorts and output cohort counts to file
  if (createCohorts) {
    ParallelLogger::logInfo("Creating cancer cohorts")
    .createCohorts(connection = connection, package,
                   cdmDatabaseSchema = cdmDatabaseSchema,
                   cohortDatabaseSchema = cohortDatabaseSchema,
                   cohortTable = cohortTable,
                   oracleTempSchema = oracleTempSchema,
                   outputFolder = outputFolder)
  }

  cohortCountsFile <- file.path(outputFolder, "CohortCounts.csv")
  if (!file.exists(cohortCountsFile)) {
    ParallelLogger::logInfo(paste("CohortCounts file not found. File: ", cohortCountsFile))
  } else {
    cohortCounts <- read.csv(cohortCountsFile) #get the cohort counts from earlier when cohorts are created
    # pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = package)
    # cohortsToCreate <- read.csv(pathToCsv)

    #Run Cohort Diagnostics for cohorts
    if (runDiagnostics) {
      ParallelLogger::logInfo("Running Cohort Diagnostics")
      runCohortDiagnostics(connection, package,
                           cdmDatabaseSchema,
                           cohortDatabaseSchema = cohortDatabaseSchema,
                           cohortTable = cohortTable,
                           oracleTempSchema = cohortDatabaseSchema,
                           outputFolder,
                           databaseId,
                           databaseName,
                           databaseDescription,
                           runInclusionStatistics = TRUE,
                           runIncludedSourceConcepts = TRUE,
                           runOrphanConcepts = TRUE,
                           runTimeDistributions = TRUE,
                           runBreakdownIndexEvents = TRUE,
                           runIncidenceRates = TRUE,
                           runCohortOverlap = TRUE,
                           runCohortCharacterization = TRUE,
                           runTemporalCohortCharacterization = TRUE,
                           minCellCount = 10)
    }

    #filter cohort list to cohorts more than on
    filterCohorts <- filterCohorts(cohortCounts, minCellCount = minCellCount)
    procedureConceptTable <- "nci_procedure_concept_code_list"
    output <- outputFolder
    if (buildDataSet) {
      #create concept list table
      ParallelLogger::logInfo("Creating concept list table for analysis")
      sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "CreateConceptListTable.sql",
                                               packageName = package,
                                               dbms = attr(connection, "dbms"),
                                               tempEmulationSchema = oracleTempSchema,
                                               target_database_schema = cohortDatabaseSchema,
                                               table_name = procedureConceptTable)
      DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
    }

    if (runAnalyses) {
      for (i in 1:nrow(filterCohorts)) {
        #establish a new connection for each cohort this clears out temporary tables
        DatabaseConnector::disconnect(connection)
        connection <- DatabaseConnector::connect(connectionDetails)

        cancerResultsOutputFolder <- paste0(output, "/", getCancerDataSetName(filterCohorts$cohortDefinitionId[i]))
        #clear out previous run data
        if (file.exists(cancerResultsOutputFolder)) {
          unlink(cancerResultsOutputFolder, recursive = TRUE)
        } else {
          dir.create(cancerResultsOutputFolder, recursive = TRUE)
        }

        # resultsOutputFolder <- paste0(cancerOutputFolder,"/analysis_results")
        #build data set for analysis
        if (buildDataSet) {
          ParallelLogger::logInfo(paste("Building data set for", filterCohorts$cohortName[i]))
          createConceptListForDataSet(connection, package,
                                      vocabularyDatabaseSchema = vocabularyDatabaseSchema,
                                      cohortDatabaseSchema = cohortDatabaseSchema,
                                      tableName = procedureConceptTable,
                                      cohortId = filterCohorts$cohortDefinitionId[i])
          datasetName <- buildDataSetForCancerCohort(connection, package,
                                                     cohortDatabaseSchema,
                                                     cohortTable,
                                                     cohortId = filterCohorts$cohortDefinitionId[i],
                                                     oracleTempSchema)
        }
        else
          datasetName <- getCancerDataSetName(cohortId = filterCohorts$cohortDefinitionId[i])

        if (runTreatmentAnalysis) {
          if (filterCohorts$cohortDefinitionId[i] %in%  c(1775946, 1775947)) {
            ParallelLogger::logInfo(paste("Running Cohort Treatment Characterization for", filterCohorts$cohortName[i]))
            if (renderMarkdown) {
              mardownFile <- getMarkdownAnalysisFileName(filterCohorts$cohortDefinitionId[i])
              rmarkdown::render(
                input = paste0(getwd(),'/R/',mardownFile$file)
                , output_dir = cancerResultsOutputFolder
                , params = list(
                    cohortId = filterCohorts$cohortDefinitionId[i]
                  , cohortName = datasetName
                  , databaseId = databaseId
                  , cohortDatabaseSchema = cohortDatabaseSchema
                  , minCellCount = minCellCount
                  , outputFolder = cancerResultsOutputFolder
                  , connection = connection
                )
              )
            } else {
              runCancerTreatmentAnalysis(connection,
                                         cohortDatabaseSchema,
                                         cohortId = filterCohorts$cohortDefinitionId[i],
                                         databaseId,
                                         cancerResultsOutputFolder,
                                         minCellCount)
            }
          }
        }

        if (runOhdsiCharacterization) {
          ParallelLogger::logInfo(paste("Running Basic OHDSI Cohort Characterization for", filterCohorts$cohortName[i]))
          runBasicCohortCharacterization(connection,
                                         cdmDatabaseSchema,
                                         cohortDatabaseSchema,
                                         cohortTable,
                                         oracleTempSchema,
                                         cohortId = filterCohorts$cohortDefinitionId[i],
                                         cancerResultsOutputFolder,
                                         minCellCount)
        }

        ParallelLogger::logInfo("Calculating cohort inclusion per year...")
        calculatePerYearCohortInclusion(connection, package,
                                        cohortDatabaseSchema,
                                        cohortTable,
                                        oracleTempSchema,
                                        cancerResultsOutputFolder,
                                        minCellCount)
      }
    }

    if (packageResults) {
      ParallelLogger::logInfo("Packaging results")
      exportResults(outputFolder = outputFolder,
                    databaseId = databaseId,
                    databaseName = databaseName,
                    databaseDescription = databaseDescription,
                    minCellCount = minCellCount,
                    maxCores = maxCores)
    }
  }

  invisible(NULL)
  DatabaseConnector::disconnect(connection)
}

# This function initializes all parameters, creates necessary folders, and loading data to the database for the study
initializeStudy <- function(outputFolder, connection, cohortDatabaseSchema, oracleTempSchema, package, reloadData = TRUE) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)
  ParallelLogger::addDefaultFileLogger(file.path(outputFolder, "log.txt"))
  ParallelLogger::addDefaultErrorReportLogger(file.path(outputFolder, "errorReportR.txt"))

  if (reloadData) {
    #Load ADI data
    # print(paste0("package: ", package))
    # ParallelLogger::logInfo("Loading ADI Data")
    # pathToCsv <- system.file("settings", "adi_state_data.csv", package = package)
    # createAndLoadFileToTable(pathToCsv, sep = ",", connection, cohortDatabaseSchema, createTableFile = "CreateADITable.sql", tableName = "adi_data", targetDialect = attr(connection, "dbms"), oracleTempSchema, package)

    #load CanMed
    ParallelLogger::logInfo("Loading CanMED Data")
    pathToCsv <- system.file("settings", "can_med.txt", package = package)
    createAndLoadFileToTable(pathToCsv, sep = "|", connection, cohortDatabaseSchema, createTableFile = "CreateCanMEDTable.sql", tableName = "can_med", targetDialect = attr(connection, "dbms"), oracleTempSchema, package)

    #Remove Adrenal Glucocorticoid from CanMed table b/c it creates too much noise in the analysis
    sql <- paste0("DELETE FROM @target_database_schema.@table_name WHERE major_class='Adrenal Glucocorticoid'")
    renderedSql <- SqlRender::render(sql = sql, target_database_schema = cohortDatabaseSchema, table_name = "can_med")
    deleteSql <- SqlRender::translate(renderedSql, targetDialect = attr(connection, "dbms"))
    DatabaseConnector::executeSql(connection, deleteSql)

    #Load Routes for Select Ingredients
    ParallelLogger::logInfo("Loading Select Ingredient Routes Data")
    pathToCsv <- system.file("settings", "ingredient_routes.csv", package = package)
    createAndLoadFileToTable(pathToCsv, sep = ",", connection, cohortDatabaseSchema, createTableFile = "CreateIngredientRoutesTable.sql", tableName = "ingedrient_routes", targetDialect = attr(connection, "dbms"), oracleTempSchema, package)
  }
}

createAndLoadFileToTable <- function(pathToCsv, sep = ",", connection, cohortDatabaseSchema, createTableFile, tableName, targetDialect = "sql server", oracleTempSchema, package) {
  #Create table to load data
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = createTableFile,
                                           packageName = package,
                                           dbms = attr(connection, "dbms"),
                                           tempEmulationSchema = oracleTempSchema,
                                           target_database_schema = cohortDatabaseSchema,
                                           table_name = tableName)
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)


  #Load data from csv file
  data <- read.csv(file = pathToCsv, sep = sep)
  #Construct the values to insert
  # paste0(apply(head(data), 1, function(x) paste0("('", paste0(x, collapse = "', '"), "')")), collapse = ", ")
  #batch load the rows
  chunk <- 1000
  n <- nrow(data)
  r <- rep(1:ceiling(n / chunk), each = chunk)[1:n]
  d <- split(data, r)

  for (i in d) {
    # values <- paste0(apply(head(i), 1, function(x) paste0("('", paste0(x, collapse = "', '"), "')")), collapse = ", ")

    # if (dbms!='bigquery')
    #   values <- paste0(apply(i, 1, function(x) paste0("('", paste0(x, collapse = "', '"), "')")), collapse = ", ")
    # else {
      # for (i in d) {

        # below statement create the one-liner used
        # v1 <- apply(i, 1, function(x) ifelse(is.na(strtoi(x)), paste0("'", x,"'"), paste0(x)))
        # v2 <- apply(v1, 2, function(x) paste(x, collapse = ", "))
        # values <- paste0("(", v2, ")", collapse=",")
        values <- paste0("(", apply(apply(i, 1, function(x) ifelse(is.na(strtoi(x)), paste0("'", x,"'"), paste0(x))), 2, function(x) paste(x, collapse = ", ")), ")", collapse=",")
      # }

    # }
    sql <- paste0("INSERT INTO @target_database_schema.@table_name VALUES ", values, ";")
    renderedSql <- SqlRender::render(sql = sql, target_database_schema = cohortDatabaseSchema, table_name = tableName)
    insertSql <- SqlRender::translate(renderedSql, targetDialect = targetDialect)
    DatabaseConnector::executeSql(connection, insertSql)
  }
}

# This function filters out cohorts based on minimum cell count. This filtered list will be used for the rest of the study.
filterCohorts <- function(cohortCounts, minCellCount = 10) {
  filteredCohorts <- cohortCounts[cohortCounts$count >= minCellCount,]
  for (row in 1:nrow(cohortCounts)) {
    if (cohortCounts$count <= minCellCount) {
      msg <- paste(cohortCounts$cohortDefinitionId, "-", cohortCounts$cohortName, "cohort count is too low (less than min cell count) to run study.")
      ParallelLogger::logInfo(msg)
    }
  }
  return(filteredCohorts)
}

# validCohort <- function(cohortId, cohortCounts, minCellCount) {
#   index <- grep(cohortId, cohortCounts$cohortDefinitionId)
#   return(length(index) != 0 && cohortCounts$personCount[index] > minCellCount)
# }

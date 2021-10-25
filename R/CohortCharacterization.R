# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of cervello
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

#' @details
#' Runs basic characterization for each cohort package
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
#' @param outputFolder         Name of local folder where the results were generated; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#'
#' @export
runBasicCohortCharacterization <- function(connection,
                                           cdmDatabaseSchema,
                                           cohortDatabaseSchema,
                                           cohortTable,
                                           oracleTempSchema,
                                           cohortId,
                                           outputFolder,
                                           minCellCount = 5) {

  covariateSettings <- FeatureExtraction::createDefaultCovariateSettings()
  covariateSettings$DemographicsAge <- TRUE # Need to Age (Median, IQR)
  covariateSettings$DemographicsPostObservationTime <- TRUE # Need to calculate Person-Year Observation post index date (Median, IQR)

  covariateData2 <- FeatureExtraction::getDbCovariateData(connection = connection,
                                                          cdmDatabaseSchema = cdmDatabaseSchema,
                                                          cohortDatabaseSchema = cohortDatabaseSchema,
                                                          cohortTable = cohortTable,
                                                          cohortId = cohortId,
                                                          covariateSettings = covariateSettings,
                                                          aggregated = TRUE)
  summary(covariateData2)
  result <- FeatureExtraction::createTable1(covariateData2, specifications = getCustomizeTable1Specs(), output = "one column")
  #  FeatureExtraction::saveCovariateData(covariateData2, file.path(outputFolder,paste0(cohortId,"_covariates")))
  # print(result, row.names = FALSE, right = FALSE)
  analysisFolder <- outputFolder #right now putting the results in the output folder may in the future create a separate folder
  if (!file.exists(analysisFolder)) {
    dir.create(analysisFolder, recursive = TRUE)
  }
  ParallelLogger::logInfo(paste("Writing table 1 for", getCancerDataSetName(cohortId)))
  write.csv(result, file.path(outputFolder, paste0(cohortId, "_table1.csv")), row.names = FALSE)
}

getCustomizeTable1Specs <- function() {
  s <- FeatureExtraction::getDefaultTable1Specifications()
  appendedTable1Spec <- rbind(s, c("Age", 2, "")) # Add Age as a continuous variable to table1
  appendedTable1Spec <- rbind(appendedTable1Spec, c("PriorObservationTime", 8, "")) # Add Observation prior index date
  appendedTable1Spec <- rbind(appendedTable1Spec, c("PostObservationTime", 9, "")) # Add Observation post index date
  return(appendedTable1Spec)
}

#Retrieves and writes yearly inclusion counts for all cohorts
calculatePerYearCohortInclusion <- function(connection, package,
                                            cohortDatabaseSchema,
                                            cohortTable,
                                            oracleTempSchema,
                                            outputFolder,
                                            minCellCount) {

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "GetCountsPerYear.sql",
                                           packageName = package,
                                           dbms = attr(connection, "dbms"),
                                           target_database_schema = cohortDatabaseSchema,
                                           study_cohort_table = cohortTable,
                                           tempEmulationSchema = oracleTempSchema)
  counts <- DatabaseConnector::querySql(connection, sql)
  filtered_counts <- counts[counts["PERSON_COUNT"] > minCellCount,]

  analysisFolder <- outputFolder #right now putting the results in the output folder may in the future create a separate folder
  if (!file.exists(analysisFolder)) {
    dir.create(analysisFolder, recursive = TRUE)
  }
  output <- file.path(analysisFolder, "cohort_counts_per_year.csv")
  write.table(filtered_counts, file = output, sep = ",", row.names = FALSE, col.names = TRUE)
}

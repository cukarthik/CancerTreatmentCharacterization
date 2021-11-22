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
#' Run the patient count and median ADI for each County
#' 
#' @param connection           An object of type \code{connection} that has an established database connection.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema Schema name where intermediate data can be stored. You will need to have
#'                             write priviliges in this schema. Note that for SQL Server, this should
#'                             include both the database and schema name, for example 'cdm_data.dbo'.
#' @param cdmDatabaseSchema    Schema name where your patient-level data in OMOP CDM format resides.
#'                             Note that for SQL Server, this should include both the database and
#'                             schema name, for example 'cdm_data.dbo'.
#' @param cohortTable          The name of the table that will be created in the work database schema.
#'                             This table will hold the exposure and outcome cohorts used in this
#'                             study.
#' @param outputFolder         Name of local folder to place results; make sure to use forward slashes
#'                             (/). Do not use a folder on a network drive since this greatly impacts
#'                             performance.
#' @param minCellCount         The minimum number of subjects contributing to a count before it can be included
#'                             in packaged results.
#' @param package              SQLRender packageName
#'
#' @export

#Run the patient count and median ADI for each County. Any value less than minCellCount limit will be returned as a label. 
CohortADIAnalysis <- function(connection, package, cohortDatabaseSchema, cdmDatabaseSchema, cohortTable, outputFolder, minCellCount=10){
  ParallelLogger::logInfo(paste("Extracting Geometry and ADI Data"))
  geom_table <- 'location_geocode_bg_adi'
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = 'ExtractGeomBG.sql',
                                       packageName = package,
                                       dbms = attr(connection, "dbms"),
                                       target_database_schema = cohortDatabaseSchema,
                                       cdm_database_schema = cdmDatabaseSchema,
                                       cohort_table = cohortTable,
                                       adi_data = 'adi_data')
  DatabaseConnector::executeSql(connection, sql)
  adi_county_count_sql <- "SELECT cohort_definition_id, COUNTY_NAME, STATE_NAME, CASE WHEN COUNT(DISTINCT person_id) > @minCellCount THEN STR(COUNT(DISTINCT person_id)) ELSE CONCAT('<=', STR(@minCellCount)) END AS person_count 
  FROM @cohort_database_schema.@table_name GROUP BY cohort_definition_id, STATE_NAME, COUNTY_NAME"
  adi_county_count_sql <- SqlRender::render(adi_county_count_sql,
                                      minCellCount = minCellCount,
                           cohort_database_schema = cohortDatabaseSchema,
                           table_name = geom_table)
  adi_county_count_sql <- SqlRender::translate(adi_county_count_sql, targetDialect = attr(connection, "dbms"))
  adi_county_count_result <- DatabaseConnector::querySql(connection, adi_county_count_sql)
  adi_county_count_result$PERSON_COUNT <- as.character(adi_county_count_result$PERSON_COUNT)
  
  adi_county_median_sql <- "SELECT cohort_definition_id, COUNTY_NAME, STATE_NAME, person_id, ADI_STATERNK FROM @cohort_database_schema.@table_name"
  adi_county_median_sql <- SqlRender::render(adi_county_median_sql,
                                            cohort_database_schema = cohortDatabaseSchema,
                                            table_name = geom_table)
  adi_county_median_sql <- SqlRender::translate(adi_county_median_sql, targetDialect = attr(connection, "dbms"))
  adi_county_median_result <- DatabaseConnector::querySql(connection, adi_county_median_sql)
  adi_county_median_result <- adi_county_median_result[!is.na(as.numeric(as.character(adi_county_median_result$ADI_STATERNK))),]
  adi_county_median_result$ADI_STATERNK <- as.numeric(adi_county_median_result$ADI_STATERNK)
  
  adi_county_median_result <- adi_county_median_result %>% group_by(COHORT_DEFINITION_ID, STATE_NAME, COUNTY_NAME) %>% mutate(Median_ADI=median(ADI_STATERNK))
  
  adi_county_median_result <- subset(adi_county_median_result, select = -c(PERSON_ID, ADI_STATERNK))
  adi_county_median_result <- unique(adi_county_median_result)
  
  write.csv(adi_county_count_result, file.path(outputFolder, "ADICountyCountResult.csv"))
  write.csv(adi_county_median_result, file.path(outputFolder, "ADICountyMedianADIResult.csv"))
}
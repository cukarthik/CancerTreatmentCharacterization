# Title     : TODO
# Objective : TODO
# Created by: karthik
# Created on: 7/15/21

createConceptListForDataSet <- function(connection,
                                        package,
                                        vocabularyDatabaseSchema,
                                        cohortDatabaseSchema,
                                        tableName,
                                        cohortId) {

  sqlFile <- getConceptListSqlFileName(cohortId)
  ParallelLogger::logInfo(paste("Building ", sqlFile$cancerName,  " Concept List..."))
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = sqlFile,
                                           packageName = package,
                                           dbms = attr(connection, "dbms"),
                                           target_database_schema = cohortDatabaseSchema,
                                           vocabulary_database_schema = vocabularyDatabaseSchema,
                                           table_name = tableName,
                                           cohort_id = cohortId)
  DatabaseConnector::executeSql(connection, sql)
}

buildDataSetForCancerCohort <- function(connection,
                                        package,
                                        cohortDatabaseSchema,
                                        cohortTable,
                                        cohortId,
                                        oracleTempSchema) {

  sqlFile <- getBuildSqlFileName(cohortId)
  ParallelLogger::logInfo(paste("Building ", sqlFile$cancerName,  " Analytic Dataset..."))
  datasetName <- getCancerDataSetName(cohortId)
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = sqlFile$sqlFile,
                                           packageName = package,
                                           dbms = attr(connection, "dbms"),
                                           tempEmulationSchema = oracleTempSchema,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           vocabulary_database_schema = vocabularyDatabaseSchema,
                                           target_database_schema = cohortDatabaseSchema,
                                           cohort_table = cohortTable,
                                           can_med_table = "can_med",
                                           # adi_data_table = "adi_data",
                                           ingredient_routes_table = "ingedrient_routes",
                                           target_cohort_dataset_name = datasetName,
                                           cohort_id = cohortId)
  DatabaseConnector::executeSql(connection, sql)
  return(datasetName)
}


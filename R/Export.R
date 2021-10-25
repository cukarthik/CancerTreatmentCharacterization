# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of IUDEHRStudy
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

#' Export all results to tables
#'
#' @description
#' Outputs all results to a folder called 'export', and zips them.
#'
#' @param outputFolder          Name of local folder to place results; make sure to use forward slashes
#'                              (/). Do not use a folder on a network drive since this greatly impacts
#'                              performance.
#' @param databaseId            A short string for identifying the database (e.g. 'Synpuf').
#' @param databaseName          The full name of the database.
#' @param databaseDescription   A short description (several sentences) of the database.
#' @param minCellCount          The minimum cell count for fields contains person counts or fractions.
#' @param maxCores              How many parallel cores should be used? If more cores are made
#'                              available this can speed up the analyses.
#'
#' @export
exportResults <- function(outputFolder,
                          databaseId,
                          databaseName,
                          databaseDescription,
                          minCellCount = 5,
                          maxCores) {
  exportFolder <- file.path(outputFolder, "export")
  if (!file.exists(exportFolder)) {
    dir.create(exportFolder, recursive = TRUE)
  }

  exportExposures(outputFolder = outputFolder,
                  exportFolder = exportFolder)

  exportDiagnostics(outputFolder = outputFolder,
                    exportFolder = exportFolder,
                    databaseId = databaseId,
                    minCellCount = minCellCount,
                    maxCores = maxCores)

  # Add all to zip file -------------------------------------------------------------------------------
  ParallelLogger::logInfo("Adding results to zip file")
  zipName <- file.path(exportFolder, sprintf("Results_%s.zip", databaseId))
  files <- list.files(exportFolder, pattern = ".*\\.csv$|.*\\.png$")
  oldWd <- setwd(exportFolder)
  on.exit(setwd(oldWd))
  DatabaseConnector::createZipFile(zipFile = zipName, files = files)
  ParallelLogger::logInfo("Results are ready for sharing at:", zipName)
}

exportExposures <- function(outputFolder, exportFolder) {
  ParallelLogger::logInfo("Exporting exposures")
  ParallelLogger::logInfo("- exposure_of_interest table")
  pathToCsv <- system.file("settings", "TcosOfInterest.csv", package = "IUDEHRStudy")
  tcosOfInterest <- read.csv(pathToCsv, stringsAsFactors = FALSE)
  pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = "IUDEHRStudy")
  cohortsToCreate <- read.csv(pathToCsv)
  createExposureRow <- function(exposureId) {
    atlasName <- as.character(cohortsToCreate$atlasName[cohortsToCreate$cohortId == exposureId])
    name <- as.character(cohortsToCreate$name[cohortsToCreate$cohortId == exposureId])
    cohortFileName <- system.file("cohorts", paste0(name, ".json"), package = "IUDEHRStudy")
    definition <- readChar(cohortFileName, file.info(cohortFileName)$size)
    return(tibble::tibble(exposureId = exposureId,
                          exposureName = atlasName,
                          definition = definition))
  }
  exposuresOfInterest <- unique(c(tcosOfInterest$targetId, tcosOfInterest$comparatorId))
  exposureOfInterest <- lapply(exposuresOfInterest, createExposureRow)
  exposureOfInterest <- do.call("rbind", exposureOfInterest)
  colnames(exposureOfInterest) <- SqlRender::camelCaseToSnakeCase(colnames(exposureOfInterest))
  fileName <- file.path(exportFolder, "exposure_of_interest.csv")
  readr::write_csv(exposureOfInterest, fileName)
}

enforceMinCellValue <- function(data, fieldName, minValues, silent = FALSE) {
  toCensor <- !is.na(pull(data, fieldName)) & pull(data, fieldName) < minValues & pull(data, fieldName) != 0
  if (!silent) {
    percent <- round(100 * sum(toCensor)/nrow(data), 1)
    ParallelLogger::logInfo("   censoring ",
                            sum(toCensor),
                            " values (",
                            percent,
                            "%) from ",
                            fieldName,
                            " because value below minimum")
  }
  if (length(minValues) == 1) {
    data[toCensor, fieldName] <- -minValues
  } else {
    data[toCensor, fieldName] <- -minValues[toCensor]
  }
  return(data)
}

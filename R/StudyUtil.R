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
#
#' This file is a R script contains utility functions for the study


#' This function returns the sql script file name that builds the cancer specific dataset based on the cohortId
#'
getBuildSqlFileName <- function(cohortId) {
  if (cohortId == 1775946)
    return(list(sqlFile="BuildCancerAnalysisDataSet.sql", cancerName="Breast Cancer"))
    # return(list(sqlFile = "BuildBreastCancerAnalysisDataSet.sql", cancerName = "Breast Cancer"))
  else if (cohortId == 1775947)
    return(list(sqlFile = "BuildCancerAnalysisDataSet.sql", cancerName = "Prostate Cancer"))
    # return(list(sqlFile="BuildProstateCancerAnalysisDataSet.sql", cancerName="Prostate Cancer"))
  else if (cohortId == 1775948)
    return(list(sqlFile = "BuildCancerAnalysisDataSet.sql", cancerName = "Multiple Myeloma"))
    # return(list(sqlFile="BuildBreastCancerAnalysisDataSet.sql", cancerName="Multiple Myeloma"))
  else if (cohortId == 1775949)
    return(list(sqlFile = "BuildCancerAnalysisDataSet.sql", cancerName = "Lung Cancer"))
    # return(list(sqlFile="BuildBreastCancerAnalysisDataSet.sql", cancerName="Lung Cancer"))
  else if (cohortId == 1775950)
    return(list(sqlFile = "BuildCancerAnalysisDataSet.sql", cancerName = "Prostate Cancer Surveillance"))
    # return(list(sqlFile="BuildProstateCancerAnalysisDataSet.sql", cancerName="Prostate Cancer Surveillance"))
  else return(NULL) #this line should not execute
}

#' This function returns the sql script file name that creates a list of concepts for the specific cancer based on the cohortId
#'
getConceptListSqlFileName <- function(cohortId) {
  if (cohortId == 1775946)
    return(list(sqlFile = "ProcedureConceptListForBreastCancerAnalysis.sql", cancerName = "Breast Cancer"))
  else if (cohortId == 1775947)
    return(list(sqlFile = "ProcedureConceptListForProstateCancerAnalysis.sql", cancerName = "Prostate Cancer"))
  else if (cohortId == 1775948)
    return(list(sqlFile = "ProcedureConceptListForBreastCancerAnalysis.sql", cancerName = "Multiple Myeloma"))
  else if (cohortId == 1775949)
    return(list(sqlFile = "ProcedureConceptListForLungCancerAnalysis.sql", cancerName = "Lung Cancer"))
  else if (cohortId == 1775950)
    return(list(sqlFile = "ProcedureConceptListForProstateCancerAnalysis.sql", cancerName = "Prostate Cancer Surveillance"))
  else return(NULL) #this line should not execute
}

getMarkdownAnalysisFileName <- function(cohortId) {
  if (cohortId == 1775946)
    return(list(file = "AnalysisMarkdown-BreastCancer.Rmd", cancerName = "Breast Cancer"))
  else if (cohortId == 1775947)
    return(list(file = "AnalysisMarkdown-ProstateCancer.Rmd", cancerName = "Prostate Cancer"))
  else if (cohortId == 1775948)
    return(list(file = "AnalysisMarkdown-BreastCancer.Rmd", cancerName = "Multiple Myeloma"))
  else if (cohortId == 1775949)
    return(list(file = "AnalysisMarkdown-BreastCancer.Rmd", cancerName = "Lung Cancer"))
  else if (cohortId == 1775950)
    return(list(sqlFile = "AnalysisMarkdown-BreastCancer.Rmd", cancerName = "Prostate Cancer Surveillance"))
  else return(NULL) #this line should not execute
}


#' This function returns the appropriate data set needed to run the analysis for a specific cancer cohort based on the cohortId
#'
getCancerDataSet <- function(cohortDatabaseSchema, cohortId, connection) {
  sql <- "select * from @target_database_schema.@dataset_name"
  datasetName <- getCancerDataSetName(cohortId)
  renderedSql <- render(sql = sql, target_database_schema = cohortDatabaseSchema, dataset_name = datasetName)
  translatedSql <- translate(renderedSql, targetDialect = connection@dbms)
  cancerCohortDataTable <- DatabaseConnector::querySql(connection, translatedSql)
  names(cancerCohortDataTable) <- tolower(names(cancerCohortDataTable))
  return(cancerCohortDataTable)
}


#' This function returns the appropriate vectors needed to run the analysis for a specific cancer cohort based on the cohortId
#'
getVectorsForSpecificCancer <- function(cohortId) {
  if (cohortId == 1775946) {
    #local interventions
    interventions <- c('Radical Mastectomy', 'Partial Mastectomy', 'Cryoablation', 'Radiotherapy')

    #drug vectors
    HR_positive_drugs <- c('Tamoxifen', 'Letrozole', 'Anastrozole', 'Raloxifene', 'Exemestane', 'Fulvestrant', 'Toremifene', 'Palbociclib')
    HER2_positive_drugs <- c('Trastuzumab', 'Pertuzumab', 'ADO-Trastuzumab Emtansine', 'Neratinib', 'Lapatinib', 'Tucatinib', 'fam-trastuzumab deruxtecan-nxki')
    chemo_drugs <- c('Docetaxel', 'Cyclophosphamide', 'Epiribicin', 'Eribulin', 'Etoposide', 'Paclitaxel', 'Carboplatin', 'Doxorubicin', 'Fluorouracil', 'Capecitabine', 'Gemcitabine', 'Vinorelbine', 'Methotrexate', 'Irinotecan')
    all_breast_antineoplastics <- c(HR_positive_drugs, HER2_positive_drugs, chemo_drugs)
    return(list(interventions=interventions, hr_positive_drugs=HR_positive_drugs, her2_positive_drugs=HER2_positive_drugs,
         chemo_drugs=chemo_drugs, drugs_vector=all_breast_antineoplastics))
  }
  else if (cohortId == 1775947) {
    #local interventions
    interventions <- c('Prostatectomy', 'Radiotherapy', 'Cryoablation', 'HIFU')

    #drug vectors
    endocrine_drugs <- c('Abiraterone', 'Enzalutamide', 'Apalutamide', 'Darolutamide', 'Leuprolide', 'Goserelin', 'Triptorelin', 'Abarelix', 'Bicalutamide', 'Nilutamide', 'Flutamide', 'Degarelix', 'Relugolix', 'Estradiol')
    chemo_drugs <- c('Docetaxel', 'Cabizataxel')
    immuno_drugs <- c('Sipuleucel-T') #immuno-stimulating so thought to separate into its own category
    targeted_drugs <- c('Radium-223', 'Olaparib', 'Rucaparib') #inhibitory mechanisms
    return(list(interventions=interventions, endocrine_drugs=endocrine_drugs, immuno_drugs=immuno_drugs,
         chemo_drugs=chemo_drugs, targeted_drugs=targeted_drugs, drugs_vector=c(endocrine_drugs, chemo_drugs, immuno_drugs, targeted_drugs)))
  } else if (cohortId == 1775949) {
    lung_interventions_vector <- c("Total Lobectomy", "Radiotherapy", "Wedge Resection", "Lobectomy", "Pneumonectomy")
    cancerAntineoplastics <- c('Chemotherapy', 'Immunotherapy')
    return(list(interventions=lung_interventions_vector, drugs_vector=cancerAntineoplastics))
  }
  else return(NULL)

}

#' This function returns the cancer specific dataset name based on the cohortId
#'
getCancerDataSetName <- function(cohortId) {
  sqlFile <- getBuildSqlFileName(cohortId)
  datasetName <- paste0("nci_", gsub(" ", "_", tolower(sqlFile$cancerName)), "_treatment_dataset")
  return(datasetName)
}

#' This function augments the cancer specific dataset interventions per patient
#'
augmentCancerDataSet <- function(cancerCohortDataTable, interventionsVector, drugVector, timeWindowForInterventions) {
  interventionsPivotWide <- cancerCohortDataTable %>%
    filter(intervention_type %in% interventionsVector | generic_drug_name %in% drugVector) %>%
    filter(difftime(cohort_start_date, intervention_date) <= timeWindowForInterventions) %>%
    distinct(person_id, dx_year, intervention_type, age_group) %>%
    arrange(dx_year, person_id, intervention_type) %>%
    pivot_wider(names_from = intervention_type, values_from = intervention_type)

  ###Appending distinct patient intervention field to BreastCancerTable###
  interventions_by_pt <- interventionsPivotWide %>% unite(distinct_interventions, 4:ncol(interventionsPivotWide), sep = ' + ', na.rm = TRUE)
  augmentedCancerTable <- cancerCohortDataTable %>%
    left_join(interventions_by_pt, by = c('person_id')) %>%
    select(-c(age_group.x, dx_year.x)) %>%
    rename(age_group = age_group.y, dx_year = dx_year.y)

  return(augmentedCancerTable)
}

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

#' Execute breast cancer specific characterization analysis
multipleMyelomaSpecificAnalysis <- function(cohortName, cancerCohortDataTable, cancerSpecificVectors, databaseId, outputFolder, minCellCount) {

  ParallelLogger::logInfo(paste("Creating plot of intervention types by year SINCE 2000 for", cohortName))
  examineInterventionsPerYear(cancerCohortDataTable %>% filter(dx_year >= 2000), cohortName, databaseId, outputFolder, minCellCount)

  #plot 11b
  #first line chemotherapy in the adjuvant setting
  adjuvant_chemo_records <- cancerCohortDataTable %>%
    filter(generic_drug_name %in% cancerSpecificVectors$chemo_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
# plot <- examinePercentChemoForAdjuvantTherapy(adjuvant_chemo_records, cohortName, databaseId, outputFolder, minCellCount)
  title <- "Percent Distribution of First Chemotherapy Administered, by Year"
  file <- "percent_of_distribution_first_line_chemotherapy"
  createPercentPlotForTherapy(adjuvant_chemo_records, title, file, cohortName, databaseId, minCellCount, outputFolder)

  # proteasome inhibitors irrespective of transplantation
  adjuvant_proteasome_inhibitors_records <- cancerCohortDataTable %>%
    filter(generic_drug_name %in% cancerSpecificVectors$proteasome_inhibitors) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)


  #plot the data
  title <- "Percent Distribution of First Proteasome Inhibitor Administered, by Year"
  file <- "percent_of_distribution_first_proteasome_inhibitor"
  createPercentPlotForTherapy(adjuvant_proteasome_inhibitors_records, title, file, cohortName, databaseId, minCellCount, outputFolder)


  # IMiDs
  adjuvant_IMiDs_records <- cancerCohortDataTable %>%
    filter(generic_drug_name %in% cancerSpecificVectors$IMiDs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)


  #plot the data
  title <- "Percent Distribution of First IMiD Administered, by Year"
  file <- "percent_of_distribution_first_IMiD"
  createPercentPlotForTherapy(adjuvant_IMiDs_records, title, file, cohortName, databaseId, minCellCount, outputFolder)

}
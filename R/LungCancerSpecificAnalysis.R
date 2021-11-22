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
prostateCancerSpecificAnalysis <- function(cohortName, cancerCohortDataTable, cancerSpecificVectors, databaseId, outputFolder, minCellCount) {

  #creating a table that stores all first cancer fighting drug records for each patient
  first_drug_record <- cancerCohortDataTable %>%
    filter(ingredient_type == 'Cancer-fighting', major_class != 'Adrenal Glucocorticoid', generic_drug_name != 'aspirin') %>%
    distinct(person_id, cohort_start_date, age_at_diagnosis, generic_drug_name, ingredient_type, neoadjuvant, intervention_date) %>%
    group_by(person_id) %>%
    arrange(intervention_date) %>%
    mutate(drug_sequence = row_number()) %>%
    filter(drug_sequence == 1) %>%
    arrange(intervention_date)

  ParallelLogger::logInfo(paste("Creating plot of intervention types by year SINCE 2000 for", cohortName))
  examineInterventionsPerYear(cancerCohortDataTable %>% filter(dx_year >= 2000), cohortName, databaseId, outputFolder, minCellCount)

  #plot 11b
  #first line chemotherapy in the adjuvant setting
  ParallelLogger::logInfo(paste("Creating plot of percent of chemo for adjuvant therapy for", cohortName))
  adjuvant_chemo_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '0', generic_drug_name %in% cancerSpecificVectors$chemo_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  examinePercentChemoForAdjuvantTherapy(adjuvant_chemo_records, cohortName, databaseId, outputFolder, minCellCount)

  #plot 11c
  #first line chemotherapy in the neoadjuvant setting
  ParallelLogger::logInfo(paste("Creating plot of percent of chemo for NEOadjuvant therapy for", cohortName))
  neoadjuvant_chemo_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '1', generic_drug_name %in% cancerSpecificVectors$chemo_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  examinePercentChemoForNeoAdjuvantTherapy(neoadjuvant_chemo_records, cohortName, databaseId, outputFolder, minCellCount)

  #first line checkpoint inhibitors in the adjuvant setting
  ParallelLogger::logInfo(paste("Creating plot of percent of checkpoint inhibitors for adjuvant therapy for", cohortName))
  adjuvant_checkpoint_inhibitors_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '0', generic_drug_name %in% cancerSpecificVectors$checkpoint_inhibitors) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  title <- "Percent and count distributions of first line checkpoint therapy in the adjuvant setting, by year"
  file <- "percent_of_distribution_first_line_checkpoint_therapy_adjuvant"
  createPercentPlotForTherapy(adjuvant_checkpoint_inhibitors_records, title, file, cohortName, databaseId, minCellCount, outputFolder)

  #first line checkpoint inhibitors in the neoadjuvant setting
  ParallelLogger::logInfo(paste("Creating plot of percent of checkpoint inhibitors for NEOadjuvant therapy for", cohortName))
  neoadjuvant_checkpoint_inhibitors_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '1', generic_drug_name %in% cancerSpecificVectors$checkpoint_inhibitors) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  title <- "Percent and count distributions of first line checkpoint therapy in the neoadjuvant setting, by year"
  file <- "percent_of_distribution_first_line_checkpoint_therapy_neoadjuvant"
  createPercentPlotForTherapy(neoadjuvant_checkpoint_inhibitors_records, title, file, cohortName, databaseId, minCellCount, outputFolder)


  #first line VEGF positive_drugs in the adjuvant setting
  ParallelLogger::logInfo(paste("Creating plot of percent of VEGF positive drugs for adjuvant therapy for", cohortName))
  adjuvant_vegf_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '0', generic_drug_name %in% cancerSpecificVectors$VEGF_positive_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  title <- "Percent and count distributions of first line VEGF positive drugs in the adjuvant setting, by year"
  file <- "percent_of_distribution_first_line_vegf_therapy_adjuvant"
  createPercentPlotForTherapy(adjuvant_vegf_records, title, file, cohortName, databaseId, minCellCount, outputFolder)

  #first line VEGF positive_drugs in the neoadjuvant setting
  ParallelLogger::logInfo(paste("Creating plot of percent of VEGF positive drugs for NEOadjuvant therapy for", cohortName))
  neoadjuvant_vegf_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '1', generic_drug_name %in% cancerSpecificVectors$VEGF_positive_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  title <- "Percent and count distributions of first line VEGF therapy in the neoadjuvant setting, by year"
  file <- "percent_of_distribution_first_line_vegf_therapy_neoadjuvant"
  createPercentPlotForTherapy(neoadjuvant_vegf_records, title, file, cohortName, databaseId, minCellCount, outputFolder)

  #adjuvant EGFR positive_drugs
  ParallelLogger::logInfo(paste("Creating plot of percent of EGFR positive drugs for adjuvant therapy for", cohortName))
  adjuvant_egfr_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '0', generic_drug_name %in% cancerSpecificVectors$EGFR_positive_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  title <- "Percent and count distributions of first line EGFR therapy in the adjuvant setting, by year"
  file <- "percent_of_distribution_first_line_egfr_therapy_adjuvant"
  plot <- createPercentPlotForTherapy(adjuvant_egfr_records, title, file, cohortName, databaseId, minCellCount, outputFolder)


  #neoadjuvant EGFR positive_drugs
  ParallelLogger::logInfo(paste("Creating plot of percent of EGFR positive drugs for NEOadjuvant therapy for", cohortName))
  neoadjuvant_vegf_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '1', generic_drug_name %in% cancerSpecificVectors$EGFR_positive_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)

  #plot the data
  title <- "Percent and count distributions of first line EGFR therapy in the neoadjuvant setting, by year"
  file <- "percent_of_distribution_first_line_egfr_therapy_neoadjuvant"
  plot <- createPercentPlotForTherapy(neoadjuvant_vegf_records, title, file, cohortName, databaseId, minCellCount, outputFolder)

  #adjuvant all systemic drugs for lung
  ParallelLogger::logInfo(paste("Creating plot of percent of all antineoplastics for adjuvant therapy for", cohortName))
  adjuvant_all_antineoplastics_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '0', generic_drug_name %in% cancerSpecificVectors$drugs_vector) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)

  #plot the data
  title <- "Percent and count distributions of first line all antineoplastics adjuvant setting, by year"
  file <- "percent_of_distribution_first_line_all_lung_antineoplastics_adjuvant"
  plot <- createPercentPlotForTherapy(adjuvant_all_antineoplastics_records, title, file, cohortName, databaseId, minCellCount, outputFolder)

}
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
breastCancerSpecificAnalysis <- function(cohortName, cancerCohortDataTable, cancerSpecificVectors, databaseId, outputFolder, minCellCount) {

  #creating a table that stores all first cancer fighting drug records for each patient
  first_drug_record <- cancerCohortDataTable %>%
    filter(ingredient_type == 'Cancer-fighting', major_class != 'Adrenal Glucocorticoid', generic_drug_name != 'aspirin') %>%
    distinct(person_id, cohort_start_date, age_at_diagnosis, generic_drug_name, ingredient_type, neoadjuvant, intervention_date) %>%
    group_by(person_id) %>%
    arrange(intervention_date) %>%
    mutate(drug_sequence = row_number()) %>%
    filter(drug_sequence == 1) %>%
    arrange(intervention_date)

  #plot 5
  #creating a table of just tamoxifen and anastrozole
  # ParallelLogger::logInfo(paste("Creating plot of tamoxifen and anastrozole for", cohortName))
  # tamoxifenVsAnastrozoleAnalysis(first_drug_record, outputFolder, minCellCount)

  #plot 6
  #plotting histogram of all first drugs given to breast cancer pts
  # ParallelLogger::logInfo(paste("Creating plot of first drugs given for", cohortName))
  # examineFirstDrugRecord(first_drug_record, outputFolder, minCellCount)

  #plot 7
  #same as plot 4 but stratified by ingredient type
  #number of anti-neoplastic drugs approved by FDA, by year
  #number of distinct 'cancer fighting' drugs administered per year -- this excludes all glucocorticoids and aspirin
  # ParallelLogger::logInfo(paste("Creating plot of 'cancer fighting' drugs administered per year for", cohortName))
  # examineTumorVsChemoTreatment(cancerCohortDataTable, outputFolder, FDA_drug_approvals)

  ######for plot 9, would be more useful to note which neoadjuvant therapies are being used (so something like plot 11)#############
  #plot 9
  # ParallelLogger::logInfo(paste("Creating plot of neoadjuvant therapies for", cohortName))
  # examineNeoadjuvantPercentages(cancerCohortDataTable, outputFolder, minCellCount)

  #plot 10
  #looking at the variation in drugs for patients who received just systemic treatment
  # ParallelLogger::logInfo(paste("Creating plot of first line therapies for advanced stage cancers for", cohortName))
  # examineFirstLineTherapyForAdvancedStageCancer(cancerCohortDataTable, outputFolder, patient_interventions)

  #All the below plots are based on the index date of each patient and the earliest drug intervention
  #for irrespective of the year the drug (interventin) was taken

  #plot 11a
  #Endocrine distribution in the adjuvant setting for each subject
  ParallelLogger::logInfo(paste("Creating plot of percent of endocrine therapy for adjuvant therapy for", cohortName))
  #selecting for patients who are labeled as having adjuvant aromatase inhibitor adjuvant records
  adjuvant_endrocrine_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '0', generic_drug_name %in% cancerSpecificVectors$hr_positive_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  examinePercentEndocrineForAdjuvantTherapy(adjuvant_endrocrine_records, cohortName, databaseId, outputFolder, minCellCount)
 
  #Endocrine distribution in the neoadjuvant setting for each subject
  ParallelLogger::logInfo(paste("Creating plot of percent of endocrine therapy for Neoadjuvant therapy for", cohortName))
  neoadjuvant_endrocrine_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '1', generic_drug_name %in% cancerSpecificVectors$hr_positive_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  examinePercentEndocrineForNeoAdjuvantTherapy(neoadjuvant_endrocrine_records, cohortName, databaseId, outputFolder, minCellCount)

  #plot 11b
  #first line chemotherapy in the adjuvant setting for each subject
  ParallelLogger::logInfo(paste("Creating plot of percent of chemo for adjuvant therapy for", cohortName))
  adjuvant_chemo_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '0', generic_drug_name %in% cancerSpecificVectors$chemo_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  examinePercentChemoForAdjuvantTherapy(adjuvant_chemo_records, cohortName, databaseId, outputFolder, minCellCount)

  #plot 11c
  #first line chemotherapy in the neoadjuvant setting for each subject
  ParallelLogger::logInfo(paste("Creating plot of percent of chemo for NEOadjuvant therapy for", cohortName))
  neoadjuvant_chemo_records <- cancerCohortDataTable %>%
    filter(neoadjuvant == '1', generic_drug_name %in% cancerSpecificVectors$chemo_drugs) %>%
    distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
    arrange(dx_year, person_id, intervention_date) %>%
    group_by(person_id) %>%
    slice(1)
  examinePercentChemoForNeoAdjuvantTherapy(neoadjuvant_chemo_records, cohortName, databaseId, outputFolder, minCellCount)

  #plot 12
  # ParallelLogger::logInfo(paste("Creating plot of immnunotherapy for", cohortName))
  # examineImmunoTherapy(cancerCohortDataTable, outputFolder, minCellCount)

  #plot 13
  # ParallelLogger::logInfo(paste("Creating plot of antineoplastics over time for", cohortName))
  # examineAntineoplasticsOverTime(cancerCohortDataTable, outputFolder, minCellCount)

  #plot 14
  #AntiHER2 treatment variation in adjuvant setting
  ParallelLogger::logInfo(paste("Creating plot of anti-HER2 for adjuvant therapy over time for", cohortName))
  AntiHER2s <- cancerCohortDataTable %>%
          filter(neoadjuvant == '0', generic_drug_name %in% cancerSpecificVectors$her2_positive_drugs) %>%
          # distinct(dx_year, person_id, generic_drug_name) %>%
          # group_by(dx_year, generic_drug_name) %>%
          # tally() %>%
          # rename(patient_count = n)
          distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
              arrange(dx_year, person_id, intervention_date) %>%
              group_by(person_id) %>%
              slice(1)
  examineAntiHER2AdjuvantTherapy(AntiHER2s, cohortName, databaseId, outputFolder, minCellCount)

  #AntiHER2 treatment variation in neoadjuvant setting
  ParallelLogger::logInfo(paste("Creating plot of anti-HER2 for neoadjuvant therapy over time for", cohortName))
  AntiHER2s <- cancerCohortDataTable %>%
          filter(neoadjuvant == '1', generic_drug_name %in% cancerSpecificVectors$her2_positive_drugs) %>%
          # distinct(dx_year, person_id, generic_drug_name) %>%
          # group_by(dx_year, generic_drug_name) %>%
          # tally() %>%
          # rename(patient_count = n)
          distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
              arrange(dx_year, person_id, intervention_date) %>%
              group_by(person_id) %>%
              slice(1)

  examineAntiHER2NeoAdjuvantTherapy(AntiHER2s, cohortName, databaseId, outputFolder, minCellCount)
}

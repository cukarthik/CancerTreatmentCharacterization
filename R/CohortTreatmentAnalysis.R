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

#' Execute the cancer characterization analysis
#'
#' @details
#' This function executes the cohort diagnostics.
#'
#' @param connection           An object of type \code{connection} that has an established database connection.
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
#' @param minCellCount         The minimum number of subjects contributing to a count before it can be included
#'                             in packaged results.
#'
#' @export
runCancerTreatmentAnalysis <- function(connection, cohortDatabaseSchema, cohortId, databaseId, outputFolder, minCellCount = 5) {

  cancerCohortDataTable <- getCancerDataSet(cohortDatabaseSchema, cohortId, connection)

  cohortName <- getCancerDataSetName(cohortId)
  # names(cancerCohortDataTable) #list column names in data frame
  # head(cancerCohortDataTable) #output first few rows of data frame

  #year a year field based on 'cohort start date' in order to perform year-based analyses
  # cancerCohortDataTable <- cancerCohortDataTable %>%
  #   mutate(dx_year = substr(cohort_start_date, 1, 4)) %>%
  #   dplyr::arrange(dx_year, person_id, intervention_date)

  time_window_for_interventions <- 365

  cancerSpecificVectors <- getVectorsForSpecificCancer(cohortId)
  #function to produce interventions per patient
  augmentCancerDataSet <- augmentCancerDataSet(cancerCohortDataTable = cancerCohortDataTable,
                                               interventionsVector = cancerSpecificVectors$interventions,
                                               drugVector = cancerSpecificVectors$drugs_vector,
                                               timeWindowForInterventions = time_window_for_interventions)

  #clear out previous run data
  if (file.exists(outputFolder)) {
    unlink(outputFolder, recursive = TRUE)
  } else {
    dir.create(outputFolder, recursive = TRUE)
  }

  #counting intervention types by year
  ParallelLogger::logInfo(paste("Creating plot of intervention types by year for", cohortName))
  examineInterventionsPerYear(augmentCancerDataSet, cohortName, databaseId, outputFolder, minCellCount)

  #plot 1
  #counting distinct diagnoses by year
  ParallelLogger::logInfo(paste("Creating plot of distinct Dxs by year for", cohortName))
  examineDxPerYear(augmentCancerDataSet, cohortName, databaseId, outputFolder, minCellCount)

  #plot 2.1
  #average age at diagnosis by year
  # ParallelLogger::logInfo(paste("Creating plot of average age at Dx by year for", cohortName))
  # examineAvgAgeAtDx(augmentCancerDataSet, outputFolder, minCellCount)

  #plot 2.2
  #percent distribution of  age at diagnosis by year
  ParallelLogger::logInfo(paste("Creating plot of percent distribution of age at Dx", cohortName))
  examinePercentAgeAtDx(augmentCancerDataSet, cohortName, databaseId, outputFolder, minCellCount)

  #plot 3
  #average number of drugs, by cohort year
  ParallelLogger::logInfo(paste("Creating plot of average number of drugs by year for", cohortName))
  examineAvgNumDrugsByTreatmentClass(augmentCancerDataSet, cohortName, databaseId, outputFolder, minCellCount)

  #plot 4
  #percentage of FDA approved drugs that are administered each year
  #number of antineoplastic drugs approved by FDA, by year
  # ParallelLogger::logInfo(paste("Creating plot of number of antineoplastic drugs approved by FDA by year for", cohortName))
  # FDA_drug_approvals <- examineNumFDAApprovedDrugPerYr(augmentCancerDataSet, outputFolder, minCellCount)

  FDA_drug_approvals <- augmentCancerDataSet %>%
      distinct(generic_drug_name, approval_year) %>%
      mutate(year = substr(approval_year, 1, 4)) %>%
      arrange(year) %>%
      select(year) %>%
      group_by(year) %>%
      tally() %>%
      arrange(year) %>%
      filter(year != 2099)
  #counting distinct interventions for each patient for each cohort year WITH ENDOCRINE THERAPY INCLUDED
  if (cohortId == 1775946)  #Breast Cancer
  {
    ParallelLogger::logInfo(paste("Creating plot of distinct interventions for each patient for each cohort year WITH ENDOCRINE THERAPY for", cohortName))
    breastCancerSpecificAnalysis(cohortName, augmentCancerDataSet, cancerSpecificVectors, databaseId, outputFolder, minCellCount)
  }
  else if (cohortId == 1775947)
    prostateCancerSpecificAnalysis(cohortName, augmentCancerDataSet, cancerSpecificVectors, databaseId, outputFolder, minCellCount)
  # else if (cohortId == 1775948)
  #   multipleMyelomaCancerSpecificAnalysis(cohortName, cancerCohortDataTable, FDA_drug_approvals, patient_interventions, outputFolder, minCellCount)
  # else if (cohortId == 1775949)
  #   lungCancerSpecificAnalysis(cohortName, cancerCohortDataTable, FDA_drug_approvals, patient_interventions, outputFolder, minCellCount)
}

#' counting intervention types by year
#' @export
examineInterventionsPerYear <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, minCellCount) {
   distinct_breast_interventions <- cancerCohortDataTable %>%
                                 distinct(person_id, dx_year, distinct_interventions, age_group)

  interventions_cnts <- distinct_breast_interventions %>% arrange(person_id) %>%
    group_by(dx_year, distinct_interventions) %>%
    tally() %>% arrange(dx_year, desc(n))

  interventions_year_totals <- interventions_cnts %>%
    group_by(dx_year) %>%
    summarise(year_total = sum(n))

  numCancerInterventionsPerYear <- interventions_cnts %>% #cancerCohortDataTable %>%
    inner_join(interventions_year_totals, by = c('dx_year')) %>%
    mutate(pct = round(n * 100 / year_total))

  # numCancerInterventionsPerYear <- cancerInterventionsConcatenatedTotals %>%
  #   unite(distinct_interventions, 4:ncol(cancerCohortDataTable), sep = ' + ', na.rm = TRUE) %>%
  #   arrange(person_id) %>%
  #   group_by(dx_year, distinct_interventions) %>%
  #   tally() %>%
  #   arrange(dx_year, desc(n))

  colourCount <- length(unique(numCancerInterventionsPerYear$distinct_interventions))
  getPalette <- colorRampPalette(brewer.pal(26, "Set3"))

  z <- ggplot2::ggplot(numCancerInterventionsPerYear, aes(fill = distinct_interventions, x = dx_year, y = pct)) +
       geom_bar(position = 'fill', stat = 'identity') +
       geom_text(aes(label = n), position = position_fill(vjust = .5), size = 2.5) +
       ggtitle('Percent Distribution of Intervention Types by Year') +
       theme(legend.position = 'bottom', legend.text = element_text(size = 4), legend.key.size = unit(.25, 'cm'), legend.title = element_text(size = 6)) +
       scale_fill_manual(values = getPalette(colourCount))
  # ggsave(file.path(Folder, 'Plots/Plot 1 - Percent distribution of intervention types, by year.pdf'))
  file <- "percent_interventions_types_per_year"
  saveAnalysis(x = z, data = numCancerInterventionsPerYear, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount, fieldName = "n")
  return(z)
}

#' counting distinct diagnoses by year
#' @export
examineDxPerYear <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, minCellCount) {
  #plot 1
  Number_of_Dx_per_year <- cancerCohortDataTable %>%
    group_by(dx_year) %>%
    summarise(count = n_distinct(person_id))
  z <- ggplot2::ggplot(data = Number_of_Dx_per_year, aes(x = dx_year, y = count, group = 1)) +
    geom_line() +
    geom_point(size = 3, color = 'blue') +
    labs(x = 'Year', y = 'Number of Dx', title = 'Number of Dx Per Year')
  file <- "number_of_dx_per_year"
  saveAnalysis(x = z, data = Number_of_Dx_per_year, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount, fieldName = "count")
  return(z)
}

#' average age at diagnosis by year
#' @export
examineAvgAgeAtDx <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, minCellCount) {
  #plot 2
  avg_age_at_dx <- cancerCohortDataTable %>%
    group_by(dx_year) %>%
    summarise(mean_age = mean(age_at_diagnosis), std = sd(age_at_diagnosis), n = n())
  x <- ggplot2::ggplot(data = avg_age_at_dx, aes(x = dx_year, y = mean_age, group = 1)) +
    geom_line() +
    geom_point(size = 3, color = 'blue') +
    labs(x = 'Year', y = 'Average age', title = 'Average Age at Diagnosis') +
    ylim(45, 65)
  file <- "avg_age_at_dx"
  saveAnalysis(x = x, data = avg_age_at_dx, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  return(x)
}

#' percent distribution of Ages at Diagnosis
#' @export
examinePercentAgeAtDx <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, minCellCount) {
  age_group_at_dx <- cancerCohortDataTable %>%
    distinct(person_id, dx_year, age_group) %>%
    group_by(dx_year) %>%
    count(age_group) %>%
    arrange(dx_year)
  age_year_total <- age_group_at_dx %>%
    group_by(dx_year) %>%
    summarise(year_total = sum(n))

  age_group_at_dx <- age_group_at_dx %>%
    inner_join(age_year_total, by = c('dx_year')) %>%
    mutate(pct = round(n * 100 / year_total))

  colourCount =  length(unique(cancerCohortDataTable$distinct_interventions))
  getPalette = colorRampPalette(brewer.pal(26, "Set3"))

  x <- ggplot(age_group_at_dx, aes(fill = age_group, x = dx_year, y = pct)) +
    geom_bar(position = "fill", stat = "identity") +
    geom_text(aes(label = pct), position = position_fill(vjust = .5), size = 1) +
    ggtitle('Percent Distribution of Age Group at Time of Diagnosis by Year') +
    theme(plot.title = element_text(size = 12), legend.position = 'bottom',
          legend.text = element_text(size = 5), legend.key.size = unit(.5, 'cm'),
          legend.title = element_text(size = 5)) +
    scale_fill_manual(values = getPalette(colourCount))

  file <- "age_group_percent_at_dx"
  saveAnalysis(x = x, data = age_group_at_dx, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  return(x)
}

#' @export
examineAvgNumDrugsByTreatmentClass <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, minCellCount) {
  #average number of drugs, by cohort year
  #plus average number of distinct major class drugs, by cohort year
  drug_count_pp <- cancerCohortDataTable %>%
    filter(intervention_type == 'Drug') %>%
    distinct(person_id, generic_drug_name, dx_year) %>%
    group_by(dx_year, person_id) %>%
    mutate(drug_count = n())
  mean_and_sd_of_drugs_by_year <- drug_count_pp %>%
    group_by(dx_year) %>%
    summarise(average_number_of_drugs = mean(drug_count), standard_deviation = sd(drug_count))

  #Major classes
  major_classes_pp <- cancerCohortDataTable %>%
    filter(rx_category == 'Chemotherapy' | rx_category == 'Immunotherapy') %>%
    distinct(person_id, dx_year, major_class) %>%
    group_by(dx_year, person_id) %>%
    mutate(major_class_count = n())
  mean_and_sd_of_classes_by_year <- major_classes_pp %>%
    group_by(dx_year) %>%
    summarise(class_avg = mean(major_class_count), class_sd = sd(major_class_count))

  #Joining two tables to include in the same plot
  mean_drugs_and_mean_classes_by_year <- mean_and_sd_of_drugs_by_year %>%
    inner_join(mean_and_sd_of_classes_by_year, by = c("dx_year" = "dx_year"))
  #    %>% rename(drugs_given = n.y)

  # #plot the data
  # z <- ggplot2::ggplot(data = mean_and_sd_of_drugs_by_year, aes(x = dx_year)) +
  #   geom_line(aes(y = average_number_of_drugs, group = 1)) +
  #   geom_line(aes(y = standard_deviation, group = 1)) +
  #   scale_y_continuous(sec.axis = ~. / 1.5, name = 'standard deviation of drugs')
  # #plot the data
  # x <- ggplot2::ggplot(data = mean_and_sd_of_classes_by_year, aes(x = dx_year)) +
  #   geom_line(aes(y = class_avg, group = 1)) +
  #   geom_line(aes(y = class_sd, group = 1)) +
  #   scale_y_continuous(sec.axis = ~. / 1.5, name = 'standard deviation of drugs')

  file <- "mean_and_sd_of_drugs_and_classes_by_year"

  #first create an object that stores just one year of values for in-graph labeling of lines
  labels <- mean_drugs_and_mean_classes_by_year %>% filter(!is.na(dx_year)) %>% slice(1)
  
  x <- ggplot(data = mean_drugs_and_mean_classes_by_year, aes(x = dx_year)) +
    geom_line(aes(y = average_number_of_drugs, group = 1), color = 'red') +
    geom_line(aes(y = standard_deviation, group = 1), linetype = 'dashed', color = 'red') +
    geom_line(aes(y = class_avg, group = 1), color = 'blue') +
    geom_line(aes(y = class_sd, group = 1), linetype = 'dashed', color = 'blue') +
    geom_label_repel(data = labels, aes(x = dx_year, y = average_number_of_drugs, label = 'avg number of drugs administered'), color = 'red') +
    geom_label_repel(data = labels, aes(x = dx_year, y = standard_deviation, label = 'stdev of drugs'), color = 'red') +
    geom_label_repel(data = labels, aes(x = dx_year, y = class_avg, label = 'avg number of drug classes'), color = 'blue') +
    geom_label_repel(data = labels, aes(x = dx_year, y = class_sd, label = 'stdev of classes'), color = 'blue') +
    scale_y_discrete(limits = c('1', '2', '3', '4', '5', '6', '7', '8', '9'))
  #saving plot
  saveAnalysis(x = x, data = labels, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  # saveAnalysis(x = z, data = drug_count_pp, analysisFolder = outputFolder, fileName = "drug_count_pp", minCellCount = 0)
  # saveAnalysis(x = z, data = mean_and_sd_of_drugs_by_year, analysisFolder = outputFolder, fileName = "mean_and_sd_of_drugs_by_year", minCellCount = 0)
  # saveAnalysis(x = x, data = major_classes_pp, analysisFolder = outputFolder, fileName = "major_classes_pp", cohortName, databaseId, minCellCount = 0)
  # saveAnalysis(x = x, data = mean_and_sd_of_classes_by_year, analysisFolder = outputFolder, fileName = "mean_and_sd_of_classes_by_year", cohortName, databaseId, minCellCount = 0)
  saveAnalysis(x = x, data = mean_drugs_and_mean_classes_by_year, analysisFolder = outputFolder, fileName = "mean_drugs_and_mean_classes_by_year", cohortName, databaseId, minCellCount = 0)

  return(x)
}

# examineNumFDAApprovedDrugPerYr <- function(cancerCohortDataTable, outputFolder, minCellCount) {
#   #plot 4
#   FDA_drug_approvals <- cancerCohortDataTable %>%
#     distinct(generic_drug_name, approval_year) %>%
#     mutate(year = substr(approval_year, 1, 4)) %>%
#     arrange(year) %>%
#     select(year) %>%
#     group_by(year) %>%
#     tally() %>%
#     arrange(year) %>%
#     filter(year != 2099)
#   #cumulative count of all approved drugs - should be non-decreasing from left to right
#   FDA_drug_approvals$cumulative_approvals <- cumsum(FDA_drug_approvals$n)
#   cumulative_approvals <- FDA_drug_approvals$cumulative_approvals
#
#   #number of distinct 'cancer fighting' drugs administered per year -- this excludes all glucocorticoids and aspirin
#   distinct_drugs_by_year <- cancerCohortDataTable %>%
#     filter(ingredient_type == 'Cancer-fighting', major_class != 'Adrenal Glucocorticoid', generic_drug_name != 'aspirin') %>%
#     mutate(drug_year = substr(intervention_date, 1, 4)) %>%
#     distinct(generic_drug_name, drug_year) %>%
#     group_by(drug_year) %>%
#     tally()
#
#   #adding 'distinct drugs by year' to 'FDA drug approvals' to get df ready for percentage calculation
#   drugs_used_per_year <- FDA_drug_approvals %>%
#     inner_join(distinct_drugs_by_year, by = c("year" = "drug_year")) %>%
#     rename(drugs_given = n.y) %>%
#     mutate(pct = round(drugs_given * 100 / cumulative_approvals, 0))
#   #plot both columns in same graph to show percentage
#   x <- ggplot2::ggplot(data = drugs_used_per_year, aes(x = year)) +
#     geom_col(aes(y = cumulative_approvals, group = 1), fill = 'red') +
#     geom_col(aes(y = drugs_given, group = 1), fill = 'blue') +
#     geom_text(data = drugs_used_per_year, aes(x = year, y = pct, label = pct, color = 'black')) +
#     labs(title = "Comparing available approved FDA drugs to drugs presscribed, by year", x = 'year', y = 'counts')
#
#   # ggsave(file.path(analysisPlotsFolder, "Plots/cancer_fighting_drugs_used_per_year.pdf"))
#   file <- "fda_approved_cancer_fighting_drugs_used_per_year"
#   # saveAnalysis(x = x, data = drugs_used_per_year, analysisFolder = outputFolder, fileName = file, minCellCount = 0)
#   return(FDA_drug_approvals)
# }

# examineEndocrineTherapyIntervention <- function(cancerCohortDataTable, outputFolder, minCellCount) {
#   patient_interventions <- cancerCohortDataTable %>%
#     filter(patient_interventions != 'NULL', major_class != 'Adrenal Glucocorticoid', generic_drug_name != 'aspirin') %>%
#     distinct(person_id, dx_year, patient_interventions)
#   interventions_by_year <- sqldf("select dx_year, patient_interventions, count(*) as count
#                                from patient_interventions
#                                group by dx_year, patient_interventions
#                                order by dx_year, patient_interventions")
#   denom <- sqldf("select dx_year, sum(count) as sum
#                   from interventions_by_year
#                   group by dx_year")
#   pct_preparation <- sqldf("select a.*, d.sum
#                           from interventions_by_year a
#                           JOIN denom d ON a.dx_year=d.dx_year
#                           order by dx_year, patient_interventions")
#   interventions_by_year_with_pct <- sqldf("select *, count*100/sum as pct
#                                         from pct_preparation
#                                         order by dx_year, patient_interventions")
#   x <- ggplot(interventions_by_year_with_pct, aes(x = dx_year, y = count, fill = patient_interventions)) +
#     geom_bar(position = 'dodge', stat = 'identity') +
#     geom_text(aes(label = pct), position = position_dodge(width = .9), vjust = -0.25, colour = 'black') +
#     labs(title = "Distribution of all interventions (with endrocrine therapy), by year", x = 'year', y = 'counts')
#   file <- "interventions_by_year_with_endocrine_therapy"
#   saveAnalysis(x = x, data = interventions_by_year_with_pct, analysisFolder = outputFolder, fileName = file, minCellCount = 0)
#   return(c(patient_interventions=patient_interventions, plot=x)
# }


# tamoxifenVsAnastrozoleAnalysis <- function(first_drug_record, outputFolder, minCellCount) {
#   Tamoxifen_Anastrozole <- first_drug_record %>%
#     ungroup(person_id) %>%
#     filter(generic_drug_name %in% c('Tamoxifen', 'Anastrozole')) %>%
#     mutate(drug_year = substr(intervention_date, 1, 4)) %>%
#     select(drug_year, generic_drug_name) %>%
#     group_by(drug_year, generic_drug_name) %>%
#     tally()
#   Tamoxifen_Anastrozole <- Tamoxifen_Anastrozole %>% mutate(drug_year = as.numeric(drug_year))
#   x <- ggplot2::ggplot(data = Tamoxifen_Anastrozole, aes(x = drug_year, y = n, fill = generic_drug_name)) +
#     geom_bar(position = 'stack', stat = 'identity') +
#     ggtitle('Tamoxifen vs. Anastrozole for first line therapy choice')
#   file <- "tamoxifen_anastrozole"
#   saveAnalysis(x = x, data = Tamoxifen_Anastrozole, analysisFolder = outputFolder, fileName = file, minCellCount = 0)
#   return(x)
# }

#' @export
examineFirstDrugRecord <- function(first_drug_record, cohortName, databaseId, outputFolder, minCellCount) {
  first_drug_record_counts <- first_drug_record %>%
    ungroup(person_id) %>%
    mutate(drug_year = substr(intervention_date, 1, 4)) %>%
    select(drug_year, generic_drug_name) %>%
    group_by(drug_year, generic_drug_name) %>%
    tally()
  first_drug_record_counts <- first_drug_record_counts %>% mutate(drug_year = as.numeric(drug_year))
  x <- ggplot2::ggplot(data = first_drug_record_counts, aes(x = drug_year, y = n, fill = generic_drug_name)) +
    geom_bar(position = 'stack', stat = 'identity') +
    ggtitle('First drug administered post Dx, by year, by drug')
  file <- "first_drug_record_counts"
  saveAnalysis(x = x, data = first_drug_record_counts, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  return(x)
}

#' @export
examineTumorVsChemoTreatment <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, FDA_drug_approvals) {
  #number of anti-neoplastic drugs approved by FDA, by year

  #number of distinct 'cancer fighting' drugs administered per year -- this excludes all glucocorticoids and aspirin
  distinct_drugs_by_year_by_type <- cancerCohortDataTable %>%
    filter(ingredient_type %in% c('Cancer-fighting', 'Supportive'), major_class != 'Adrenal Glucocorticoid', generic_drug_name != 'aspirin') %>%
    mutate(drug_year = substr(intervention_date, 1, 4)) %>%
    distinct(generic_drug_name, ingredient_type, drug_year) %>%
    group_by(drug_year, ingredient_type) %>%
    tally()

  #adding 'distinct drugs by year' to 'FDA drug approvals' to get data frame ready for percentage calculation
  cumulative_approvals <- FDA_drug_approvals$cumulative_approvals
  drugs_used_per_year_by_type <- distinct_drugs_by_year_by_type %>%
    inner_join(FDA_drug_approvals, by = c("drug_year" = "year")) %>%
    rename(drugs_given = n.x) %>%
    select(-n.y) %>%
    group_by(drug_year, ingredient_type) %>%
    mutate(pct = round(drugs_given * 100 / cumulative_approvals, 0))
  x <- ggplot2::ggplot(data = drugs_used_per_year_by_type, aes(x = drug_year, y = drugs_given, fill = ingredient_type)) +
    geom_bar(stat = 'identity') +
    labs(title = "Comparing tumor treating vs chemo supportive drug administrations", x = 'year', y = 'counts')
  file <- "cancer_fighting_drugs_used_per_year_by_type"
  saveAnalysis(x = x, data = drugs_used_per_year_by_type, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  return(x)
}

#' @export
examineNeoadjuvantPercentages <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, minCellCount) {
  #creating denom values for subsequent JOIN
  #you need the ungroup() function if you want to drop a variable that was used in a preceding group_by() function; ie, neoadjuvant in this ex
  denom <- cancerCohortDataTable %>%
    distinct(person_id, dx_year, neoadjuvant) %>%
    group_by(dx_year, neoadjuvant) %>%
    count(neoadjuvant) %>%
    filter(neoadjuvant == 'N') %>%
    ungroup() %>%
    select(dx_year, n)
  neo <- cancerCohortDataTable %>%
    distinct(person_id, dx_year, neoadjuvant) %>%
    group_by(dx_year, neoadjuvant) %>%
    count(neoadjuvant)
  neo_pcts <- left_join(neo, denom, by = "dx_year") %>% mutate(neo_pct = case_when(neoadjuvant == '1' ~ n.x * 100 / n.y, TRUE ~ 0))
  x <- ggplot2::ggplot(data = neo_pcts, aes(x = dx_year, y = neo_pct, group = 1)) +
    geom_col(fill = 'blue') +
    labs(x = 'Year', y = 'Neoadjuvant %', title = '% of patients who received neoadjuvant therapy, by year')
  file <- "neoadjuvant_percentages"
  saveAnalysis(x = x, data = neo_pcts, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  return(x)
}

#' @export
examineFirstLineTherapyForAdvancedStageCancer <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, minCellCount) {
  metastatic_drug_records <- cancerCohortDataTable %>%
    filter(distinct_interventions == 'Drug', ingredient_type == 'Cancer-fighting', major_class != 'Adrenal Glucocorticoid', generic_drug_name != 'aspirin') %>%
    arrange(dx_year, person_id, intervention_date)
  min_drug_indicator <- sqldf('select person_id, generic_drug_name, intervention_date, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY intervention_date) as min_drug_indicator
                             from metastatic_drug_records
                             order by person_id, intervention_date')
  min_drug_date <- sqldf('select person_id, generic_drug_name as first_drug_administered, intervention_date as min_drug_date
                        from  min_drug_indicator
                        where min_drug_indicator = 1
                        order by person_id, intervention_date')
  #step 4
  min_drug_date_added <- sqldf("select a.*, b.first_drug_administered, b.min_drug_date
                              from metastatic_drug_records a
                              LEFT JOIN min_drug_date b ON a.person_id=b.person_id
                              order by dx_year, person_id, intervention_date")
  #step 5
  combination_drug <- min_drug_date_added %>%
    mutate(combination_drug = ifelse(difftime(as.Date(min_drug_date), as.Date(intervention_date), units = 'days') <= 3, generic_drug_name, 'no combination therapy')) %>%
    arrange(dx_year, person_id, intervention_date)
  #step 6
  combination_treatment <- combination_drug %>%
    mutate(combination_treatment = case_when(combination_drug != 'no combination therapy' & combination_drug != first_drug_administered ~ paste0(first_drug_administered, ' + ', combination_drug), TRUE ~ first_drug_administered)) %>%
    arrange(dx_year, person_id, intervention_date)

  #step 7
  almost_ready_for_counts <- combination_treatment %>%
    distinct(person_id, dx_year, combination_treatment) %>%
    arrange(dx_year, person_id, combination_treatment)
  #step 8
  penultimate <- almost_ready_for_counts %>%
    group_by(dx_year, person_id) %>%
    filter(combination_treatment == max((combination_treatment))) %>%
    select(person_id, dx_year, combination_treatment) %>%
    arrange(dx_year, person_id)
  #step 9
  stageIV_firstLine_concurrentTherapies <- penultimate %>%
    group_by(dx_year, combination_treatment) %>%
    tally() %>%
    arrange(dx_year, desc(n))
  max_first_line_for_each_year <- stageIV_firstLine_concurrentTherapies %>%
    group_by(dx_year) %>%
    arrange(desc(n)) %>%
    slice(1:2)
  x <- ggplot(stageIV_firstLine_concurrentTherapies, aes(x = dx_year, y = n, fill = combination_treatment)) +
    geom_bar(position = 'dodge', stat = 'identity') +
    geom_text(aes(label = n), position = position_dodge(width = .9), vjust = -0.25, colour = 'black') +
    geom_label_repel(data = max_first_line_for_each_year, aes(x = dx_year, y = n, label = combination_treatment), color = 'black') +
    labs(title = "Stage IV First Line Therapies, by Year For Top Two Used Drugs", x = 'year', y = 'counts') +
    theme(legend.position = 'none')
  file <- "stage_iv_first_line_therapies"
  saveAnalysis(x = x, data = stageIV_firstLine_concurrentTherapies, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  return(x)
}

#' @export
examinePercentEndocrineForAdjuvantTherapy <- function(adjuvant_endrocrine_records, cohortName, databaseId, outputFolder, minCellCount) {
  # plot 11a
  #calculating the percent of patients who receive adjuvant Endocrine therapy, by year
  #selecting for patients who are labeled as having adjuvant drug records
  # patients_with_adjuvant_records <- cancerCohortDataTable %>%
  #   filter(neoadjuvant == '0') %>%
  #   distinct(person_id, dx_year)

  #grabbing rows that indicate drug admin subsequent to local intervention
  # patients_with_adjuvant_records_by_year <- patients_with_adjuvant_records %>%
  #   group_by(dx_year) %>%
  #   tally() %>%
  #   arrange(dx_year)

  #calculating denoms for each Dx year
  # adjuvant_year_denoms <- patients_with_adjuvant_records %>%
  #   group_by(dx_year) %>%
  #   tally() %>%
  #   arrange(dx_year)

  title <- "Percent distribution of first line monotherapy endocrine therapy in the adjuvant setting, by year"
  file <- "percent_of_distribution_first_line_mono_endocrine_therapy_adjuvant"
  x <- createPercentPlotForTherapy(adjuvant_endrocrine_records, title, file, cohortName, databaseId, minCellCount, outputFolder)
  return(x)
}

#' @export
examinePercentEndocrineForNeoAdjuvantTherapy <- function(neoadjuvant_endrocrine_records, cohortName, databaseId, outputFolder, minCellCount) {
  # plot 11a - 2
  title <- "Percent distribution of first line monotherapy endocrine therapy in the neoadjuvant setting, by year"
  file <- "percent_of_distribution_first_line_mono_endocrine_therapy_neoadjuvant"
  x <- createPercentPlotForTherapy(neoadjuvant_endrocrine_records, title, file, cohortName, databaseId, minCellCount, outputFolder)
  return(x)
}

#' selecting for patients who are labeled as having adjuvant chemotherapy or immunotherapy records
#' @export
examinePercentChemoForAdjuvantTherapy <- function(adjuvant_chemo_records, cohortName, databaseId, outputFolder, minCellCount) {
  # adjuvant_chemo_records <- cancerCohortDataTable %>%
  #   filter(neoadjuvant == '0', rx_category == 'Chemotherapy') %>%
  #   distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
  #   arrange(dx_year, person_id, intervention_date) %>%
  #   group_by(person_id) %>%
  #   slice(1)

  #plot the data
  title <- "Percent distribution of first line chemotherapy in the adjuvant setting, by year"
  file <- "percent_of_distribution_first_line_chemotherapy_adjuvant"
  x <- createPercentPlotForTherapy(adjuvant_chemo_records, title, file, cohortName, databaseId, minCellCount, outputFolder)
  return(x)
}

#' selecting for patients who are labeled as having NEOadjuvant chemotherapy
#' @export
examinePercentChemoForNeoAdjuvantTherapy <- function(neoadjuvant_chemo_records, cohortName, databaseId, outputFolder, minCellCount) {
  # neoadjuvant_chemo_records <- cancerCohortDataTable %>%
  #   filter(neoadjuvant == '1', rx_category == 'Chemotherapy') %>%
  #   distinct(person_id, dx_year, generic_drug_name, intervention_date) %>%
  #   arrange(dx_year, person_id, intervention_date) %>%
  #   group_by(person_id) %>%
  #   slice(1)

  #plot the data
  title <- "Percent distribution of first line chemotherapy in the neoadjuvant setting, by year"
  file <- "percent_of_distribution_first_line_chemotherapy_neoadjuvant"
  x <- createPercentPlotForTherapy(neoadjuvant_chemo_records, title, file, cohortName, databaseId, minCellCount, outputFolder)
  return(x)
}

#' generic function that plots the percentage of a therapy (i.e. chemo, immno, etc) by year
#' @export
createPercentPlotForTherapy <- function(specific_therapy_records, title, file, cohortName, databaseId, minCellCount, outputFolder) {
  #first subsetting the data to get the highest two counts per year
  first_line_therapy_counts_by_year <- specific_therapy_records %>%
    group_by(dx_year, generic_drug_name) %>%
    tally()

  year_total <- first_line_therapy_counts_by_year %>%
    group_by(dx_year) %>%
    summarise(year_total = sum(n))

  first_line_therapy_counts_by_year <- first_line_therapy_counts_by_year %>%
    inner_join(year_total, by = c('dx_year')) %>%
    mutate(pct = round(n * 100 / year_total))

  #plot the data
  x <- ggplot(first_line_therapy_counts_by_year, aes(fill = generic_drug_name, x = dx_year, y = pct)) +
    geom_bar(position = 'fill', stat = 'identity') +
    geom_text(aes(label = n), position = position_fill(vjust = .5), size = 3) +
    ggtitle(title) +
    theme(plot.title = element_text(size = 12), legend.position = 'bottom',
          legend.text = element_text(size = 5), legend.key.size = unit(.5, 'cm'), #legend.key.size = unit(.25, 'cm'),
          legend.title = element_text(size = 5))
  saveAnalysis(x = x, data = first_line_therapy_counts_by_year, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  return(x)
}

#percentage of patients each year who have at least one administration record of an Immunotherapy
# examineImmunoTherapy <- function(cancerCohortDataTable, outputFolder, minCellCount) {
#   #plot 12
#   #percentage of patients each year who have at least one administration record of an Immunotherapy
#   #patients who received at least one drug in either the neoadjuvant or adjuvant setting
#   immuno_plot_denom <- cancerCohortDataTable %>%
#     filter(intervention_type == 'Drug') %>%
#     distinct(person_id, dx_year) %>%
#     arrange(dx_year, person_id) %>%
#     group_by(dx_year) %>%
#     tally()
#
#   #patients who received at least one immunotherapy in either the neoadjuvant or adjuvant setting
#   ImmunotherapyCounts <- cancerCohortDataTable %>%
#     filter(rx_category == 'Immunotherapy', generic_drug_name != 'Denosumab', generic_drug_name != 'Cetuximab') %>%
#     distinct(person_id, dx_year, generic_drug_name) %>%
#     arrange(dx_year, person_id) %>%
#     group_by(dx_year, generic_drug_name) %>%
#     tally()
#
#   #plot the data
#   x <- ImmunotherapyCounts %>% ggplot() +
#     geom_col(data = immuno_plot_denom, aes(x = dx_year, y = n)) +
#     geom_col(data = ImmunotherapyCounts, aes(x = dx_year, y = n, fill = generic_drug_name)) +
#     ggtitle('Of the Patients Receiving Systemic Therapy, Counts of Those Who Received Immunotherapy')
#
#   file <- "counts_received_immunotherapy"
#   saveAnalysis(x = x, data = ImmunotherapyCounts, analysisFolder = outputFolder, fileName = file, minCellCount = 0)
#   return(x)
# }

#' distribution of classes of antineoplastics over time
#' @export
examineAntineoplasticsOverTime <- function(cancerCohortDataTable, cohortName, databaseId, outputFolder, minCellCount) {
  classes_pp <- cancerCohortDataTable %>%
    filter(ingredient_type == 'Cancer-fighting', major_class != 'Adrenal Glucocorticoid', generic_drug_name != 'aspirin') %>%
    distinct(person_id, dx_year, major_class) %>%
    group_by(dx_year, major_class) %>%
    tally()

  plot13_year_total <- classes_pp %>%
    group_by(dx_year) %>%
    summarise(year_total = sum(n))

  classes_pp <- classes_pp %>%
    inner_join(plot13_year_total, by = c('dx_year')) %>%
    mutate(pct = round(n * 100 / year_total))

  colourCount <-  length(unique(classes_pp$major_class))
  getPalette <- colorRampPalette(brewer.pal(26, "Set3"))

  #plot the data
  x <- ggplot(classes_pp, aes(fill = major_class, x = dx_year, y = pct)) +
    geom_bar(position = 'fill', stat = 'identity') +
    ggtitle('Percentage of Patients Each Year Who Receive Each Drug Class by Year') +
    theme(legend.position = 'bottom', legend.text = element_text(size = 5),
          legend.key.size = unit(.25, 'cm'), legend.title = element_text(size = 5)) +
    scale_fill_manual(values = getPalette(colourCount))

  file <- "percent_antineoplastics_by_year"
  saveAnalysis(x = x, data = classes_pp, analysisFolder = outputFolder, fileName = file, cohortName, databaseId, minCellCount = 0)
  return(x)
}

#' percent distribution of antiher2 over time
#' @export
examineAntiHER2AdjuvantTherapy <- function(adjuvant_antiher2_records, cohortName, databaseId, outputFolder, minCellCount) {

  #plot the data
  title <- "Percent Distribution of First Line AntiHER2 in the Adjuvant Setting by Year"
  file <- "percent_of_distribution_first_line_antiHER2_adjuvant"
  x <- createPercentPlotForTherapy(adjuvant_antiher2_records, title, cohortName, databaseId, file, minCellCount, outputFolder)
  return(x)
}

#' percent distribution of antiher2 over time
#' @export
examineAntiHER2NeoAdjuvantTherapy <- function(neoadjuvant_antiher2_records, cohortName, databaseId, outputFolder, minCellCount) {

  #plot the data
  title <- "Percent Distribution of First Line AntiHER2 in the NeoAdjuvant Setting by Year"
  file <- "percent_of_distribution_first_line_antiHER2_NEOadjuvant"
  x <- createPercentPlotForTherapy(neoadjuvant_antiher2_records, title, file, cohortName, databaseId, minCellCount, outputFolder)
  return(x)
}

#' function writes the aggregate data as well as the plot image to files
#' @export
saveAnalysis <- function(x, data = last_plot()$data[[1]], analysisFolder, fileName, cohortName, databaseId, minCellCount, fieldName = "") {
  fullFileName <- paste0(databaseId, "_", gsub(" ", "_", cohortName), "_", fileName)
  analysisPlotsFolder <- paste0(analysisFolder, "/plots")
  if (!file.exists(analysisPlotsFolder)) {
    dir.create(analysisPlotsFolder, recursive = TRUE)
  }
  analysisDataFolder <- paste0(analysisFolder, "/data") #this folder store the underlying data that generates the plots, which are only aggregate analyses
  if (!file.exists(analysisDataFolder)) {
    dir.create(analysisDataFolder, recursive = TRUE)
  }
  fullCsvFileName <- file.path(analysisDataFolder, fullFileName)
  write_rds(x, file.path(analysisDataFolder, paste0(fullFileName, ".Rds")))
  saveDataToCsv(data, fullCsvFileName, minCellCount, fieldName)
  ggsave(plot = x, file.path(analysisPlotsFolder, paste0(fullFileName, ".pdf")))
}

saveDataToCsv <- function(data, fileName, minCellCount, fieldName) {
  colnames(data) <- SqlRender::camelCaseToSnakeCase(colnames(data))
  unfilteredFile <- paste0(fileName, ".csv")
  filteredFile <- paste0(fileName, "_filtered.csv")
  if (file.exists(fileName)) {
    ParallelLogger::logDebug("Overwriting and replacing previous ",
                             unfilteredFile,
                             " with new.")
  } else {
    ParallelLogger::logDebug("creating ", unfilteredFile)
  }
  #writing NON-censored data
  readr::write_excel_csv(
    x = data,
    file = unfilteredFile,
    na = "",
    append = FALSE,
    delim = ","
  )
  if (minCellCount > 0) {
    if (file.exists(fileName)) {
      ParallelLogger::logDebug("Overwriting previous ", filteredFile, " file.")
    } else {
      ParallelLogger::logDebug("creating ", filteredFile)
    }
    #writing censored data
    enforceMinCellValue(data, fieldName, minCellCount)
    readr::write_excel_csv(
      x = data,
      file = filteredFile,
      na = "",
      append = FALSE,
      delim = ","
    )
  }
}

enforceMinCellValue <- function(data, fieldName, minValues, silent = FALSE) {
  toCensor <- !is.na(pull(data, fieldName)) &
    pull(data, fieldName) < minValues &
    pull(data, fieldName) != 0
  if (!silent) {
    percent <- round(100 * sum(toCensor) / nrow(data), 1)
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

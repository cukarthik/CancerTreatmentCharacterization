#make a copy of the csv files of interest into a tmp directory
# cp *_multiple_myeloma_treatment_dataset_mean_drugs_and_mean_classes_by_year.csv ~/Downloads/tmp-nci-results 

#create aggregate file
#for f in `ls`; do awk 'NR == 1 {print $0 ",\"source\""; split(FILENAME, a, "_"); SOURCE = a[1]; next;}{print $0 ","SOURCE}' $f; done | sort -r  | uniq > all_sources_lung_cancer_treatment_dataset_mean_drugs_and_mean_classes_by_year.csv


#########################################FUNCTIONS############################################################

#This function plots the intervention by year for each cancer. It de-duplicates interventions before plotting
#NOTE: have not figured out how to 
plotAggregateInterventions <- function(data, cohortName, outputFolder="~/Downloads/", fileName="test2") {
dedup_interventions <- data %>% 
  mutate(unique_interventions = map_chr(strsplit(data$distinct_interventions, " \\+ "), 
                                        ~ toString(sort(.x)))) %>%
  group_by(source, dx_year, unique_interventions, year_total) %>%
  summarise(unique_total = sum(n), unique_pct = sum(pct)) %>% 
  mutate(filtered_labels = replace(unique_total, unique_total<=10, ""))

colourCount <- length(unique(dedup_interventions$unique_interventions))

width <- 1980
height <- 2040
outputFile <- paste0(outputFolder, "/",  fileName, ".png")
print(paste0("output file:", outputFile))
png(file=outputFile, width=width, height=height)

p <- ggplot(dedup_interventions, aes(fill = unique_interventions, x = dx_year, y = unique_pct)) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  geom_bar(position = 'fill', stat = 'identity') +
  #  facet_wrap(~ source , ncol = 2, scales = "free" ) +
  facet_wrap(~ factor(source, levels = c('CCAE', 'CUIMC', 'MDCD', 'STANFORD', 'MDCR', 'TUFTS')) , ncol = 2 , scales = "free") +
  geom_text(aes(label = filtered_labels), position = position_fill(vjust = .5), size = 5) +
  ggtitle(paste0("Percent Distribution of Intervention Types by Year (", cohortName, ")")) +
  #  theme(legend.position = 'bottom', legend.text = element_text(size = 4),
  #        legend.key.size = unit(.25, 'cm'), legend.title = element_text(size = 6)) +
  theme(legend.position = 'bottom', legend.text = element_text(size = 12),
        legend.key.size = unit(.25, 'cm'), legend.title = element_text(size = 0), 
        legend.spacing.x = unit(.25, "cm")) +
  theme(plot.title = element_text(hjust = 0.5, size=30,face="bold"), strip.text = element_text(size = 15)) +
  theme(axis.text=element_text(size=12),  axis.title=element_text(size=20,face="bold")) +
  labs(x = "Diagnosis Year", y = "Percentage", cex.lab = 2) +
  scale_x_continuous(breaks= pretty_breaks()) +
  scale_fill_manual(values = colorRampPalette(brewer.pal(12, "Set3"))(colourCount))
show(p)
dev.off()
}

#This function aggregates the plots for average drug and drug class
plotAggregateAvgDrugsAdministered <- function(mean_drugs_and_mean_classes_by_year, cohortName, outputFolder="~/Downloads/", fileName="test2") {
  #1280x800
  width <- 1280
  height <- 800#(9/16) * width
  #Breast Cancer Average number of antineoplastics agents administered plot
  labels <- mean_drugs_and_mean_classes_by_year %>% filter(!is.na(dx_year)) %>% slice(1)

  outputFile <- paste0(outputFolder, "/", fileName, ".png")
  print(paste0("output file:", outputFile))
  png(file=outputFile, width=width, height=height)
  
  p <- ggplot(data = mean_drugs_and_mean_classes_by_year, aes(x = dx_year)) +
    geom_line(aes(y = average_number_of_drugs, group = 1, colour="Avg # of Drugs")) +
    geom_line(aes(y = standard_deviation, group = 1, colour="Std Dev of Drugs"), linetype=2) +
    geom_line(aes(y = class_avg, group = 2, colour="Avg # of Classes of Drugs")) +
    geom_line(aes(y = class_sd, group = 2, colour="Std Dev of Classes of Drugs"), linetype=2) +
    facet_wrap(~ factor(source, levels = c('CCAE', 'CUIMC', 'MDCD', 'STANFORD', 'MDCR', 'TUFTS')) , ncol = 2 ) +
    ggtitle(paste0("Administered Drugs by Year (", cohortName, ")")) +
    theme(legend.position = 'bottom', legend.text = element_text(size = 10),
          #legend.key.size = unit(.25, 'cm'), 
          legend.title = element_text(size = 0), 
          legend.spacing.x = unit(.25, "cm")
    ) +
#    theme(plot.title = element_text(hjust = 0.5, size=30,face="bold")) +
    theme(plot.title = element_text(hjust = 0.5, size=30,face="bold"), strip.text = element_text(size = 15)) +
    theme(axis.text=element_text(size=12),  axis.title=element_text(size=20,face="bold")) +
    labs(y="Avg Number of Drugs", x = "Diagnosis Year", cex.lab = 2) +
    scale_x_continuous(breaks= pretty_breaks()) 
  show(p)
  dev.off()
}

plotAggregateAnalyses <- function(data, outputFolder="~/Downloads/", fileName="test2",
                                  title="TITLE") {
  colourCount <- length(unique(data$generic_drug_name))
  width <- 1280
  height <- 800
  outputFile <- paste0(outputFolder, "/",  fileName, ".png")
  print(paste0("output file:", outputFile))
  png(file=outputFile, width=width, height=height)
 
  data <- data %>% 
    mutate(filtered_labels = replace(n, n<=10, ""))
   
  p <- ggplot(data, aes(fill = generic_drug_name, x = dx_year, y = pct)) +
    scale_y_continuous(labels = percent_format(accuracy = 1)) +
    geom_bar(position = 'fill', stat = 'identity') +
    #  facet_wrap(~ source , ncol = 2, scales = "free" ) +
    facet_wrap(~ factor(source, levels = c('CCAE', 'CUIMC', 'MDCD', 'STANFORD', 'MDCR', 'TUFTS')) , ncol = 2 ) +
    geom_text(aes(label = filtered_labels), position = position_fill(vjust = .5), size = 5) +
    ggtitle(title) +
    #  theme(legend.position = 'bottom', legend.text = element_text(size = 4),
    #        legend.key.size = unit(.25, 'cm'), legend.title = element_text(size = 6)) +
    theme(legend.position = 'bottom', legend.text = element_text(size = 20),
          legend.key.size = unit(.5, 'cm'), legend.title = element_text(size = 0), 
          legend.spacing.x = unit(.25, "cm")) +
    theme(plot.title = element_text(hjust = 0.5, size=35), strip.text = element_text(size = 15)) +
    theme(axis.text=element_text(size=12),  axis.title=element_text(size=30)) +
    labs(x = "Diagnosis Year", y = "Percentage", cex.lab = 2) +
    scale_x_continuous(labels = scales::number_format(), breaks= pretty_breaks())
    scale_fill_manual(values = colorRampPalette(brewer.pal(12, "Paired"))(colourCount))
  show(p)
  dev.off()
}

#########################################SCRIPT############################################################

library(devtools)
library(ggplot2)
library(dplyr)
library(purrr)
library(stringr)
library(RColorBrewer)
library(scales)

#ToDo: change the values for the input and output folders
inputFolder <- "~/tmp-nci-results/all/"
outputFolder <- "~/tmp-nci-results/all/"

#########################################BREAST############################################################
#breast intervention plot 
data <- read.csv(paste0(inputFolder,"all_sources_breast_cancer_treatment_dataset_percent_interventions_types_per_year.csv"))
cohortName <- "Breast"
fileName <- "breast_interventions_by_year"
plotAggregateInterventions(data, cohortName = cohortName, outputFolder = outputFolder, fileName = fileName)
# dedup_interventions <- data %>% 
#   mutate(unique_interventions = map_chr(strsplit(data$distinct_interventions, " \\+ "), 
#                                         ~ toString(sort(.x)))) %>%
#   group_by(source, dx_year, unique_interventions, year_total) %>%
#   summarise(unique_total = sum(n), unique_pct = sum(pct)) %>% 
#   mutate(filtered_labels = replace(unique_total, unique_total<=10, ""))
# ggplot(dedup_interventions, aes(fill = unique_interventions, x = dx_year, y = unique_pct)) +
#   scale_y_continuous(labels = percent_format(accuracy = 1)) +
#   geom_bar(position = 'fill', stat = 'identity') +
# #  facet_wrap(~ source , ncol = 2, scales = "free" ) +
#   facet_wrap(~ factor(source, levels = c('CCAE', 'CUIMC', 'MDCD', 'STANFORD', 'MDCR', 'TUFTS')) , ncol = 2 , scales = "free") +
#   geom_text(aes(label = filtered_labels), position = position_fill(vjust = .5), size = 3) +
#   ggtitle('Percent Distribution of Intervention Types by Year (Breast)') +
# #  theme(legend.position = 'bottom', legend.text = element_text(size = 4),
# #        legend.key.size = unit(.25, 'cm'), legend.title = element_text(size = 6)) +
#   theme(legend.position = 'bottom', legend.text = element_text(size = 12),
#         legend.key.size = unit(.25, 'cm'), legend.title = element_text(size = 0), 
#         legend.spacing.x = unit(.25, "cm")) +
#   theme(plot.title = element_text(hjust = 0.5), strip.text = element_text(size = 15)) +
#   labs(x = "Diagnosis Year", y = "Percentage") +
#   scale_x_continuous(breaks= pretty_breaks())
#  # scale_x_continuous(breaks=seq(2000, 2020, 2))
# ggsave(filename = "~/Downloads/test.png")

fileName <- "breast_avg_drug_class"
data <- read.csv(paste0(outputFolder,"all_sources_breast_cancer_treatment_dataset_mean_drugs_and_mean_classes_by_year.csv"))
plotAggregateAvgDrugsAdministered(data, cohortName = cohortName, outputFolder = outputFolder, fileName = fileName)


#1280x800
# width = 1280
# height = 800#(9/16) * width
# #Breast Cancer Average number of antineoplastics agents administered plot
# mean_drugs_and_mean_classes_by_year <- read.csv(paste0(outputFolder,"all_sources_breast_cancer_treatment_dataset_mean_drugs_and_mean_classes_by_year.csv"))
# labels <- mean_drugs_and_mean_classes_by_year %>% filter(!is.na(dx_year)) %>% slice(1)
# ggplot(data = mean_drugs_and_mean_classes_by_year, aes(x = dx_year)) +
#   geom_line(aes(y = average_number_of_drugs, group = 1, colour="Avg # of Drugs")) +
#   geom_line(aes(y = standard_deviation, group = 1, colour="Std Dev of Drugs"), linetype=2) +
#   geom_line(aes(y = class_avg, group = 2, colour="Avg # of Classes of Drugs")) +
#   geom_line(aes(y = class_sd, group = 2, colour="Std Dev of Classes of Drugs"), linetype=2) +
#   facet_wrap(~ factor(source, levels = c('CCAE', 'CUIMC', 'MDCD', 'STANFORD', 'MDCR', 'TUFTS')) , ncol = 2 ) +
#   ggtitle('Administered Drugs by Year (Breast)') +
#   theme(legend.position = 'bottom', legend.text = element_text(size = .1/.pt),
#         #legend.key.size = unit(.25, 'cm'),
#         legend.title = element_text(size = 0),
#         legend.spacing.x = unit(.25, "cm")
#         ) +
#   theme(plot.title = element_text(hjust = 0.5)) +
#   theme(plot.title = element_text(hjust = 0.5), strip.text = element_text(size = 15/.pt)) +
#   labs(y="Avg Number of Drugs", x = "Diagnosis Year")
#  coord_fixed(ratio = (width/height))
#ggsave(filename = "~/Downloads/test2.png", width = 10.16, height = 6.35, units = "cm")

#code to generate aggregate data file
# for f in `ls | grep breast | grep chemotherapy_neoadjuvant.csv`; do awk 'NR == 1 {print $0 ",\"source\""; split(FILENAME, a, "_"); SOURCE = a[1]; next;}{print $0 ","SOURCE}' $f; done | sort -r  | uniq > all/all_sources_breast_cancer_chemotherapy_neoadjuvant.csv
fileName <- "breast_chemotherapy_neoadjuvant"
title <- "First-line Chemotherapy in the Neoadjuvant Setting (Breast)"
data <- read.csv(paste0(outputFolder,"all_sources_breast_cancer_chemotherapy_neoadjuvant.csv"))
fieldName <- "generic_drug_name" #field in data that will be plotted
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)



#########################################PROSTATE############################################################
data <- read.csv(paste0(inputFolder,"all_sources_prostate_cancer_treatment_dataset_percent_interventions_types_per_year.csv"))
cohortName <- "Prostate"
fileName <- "prostate_interventions_by_year"
plotAggregateInterventions(data, cohortName = cohortName, outputFolder = outputFolder, fileName = fileName)

#Prostate Cancer Average number of antineoplastics agents administered plot 
mean_drugs_and_mean_classes_by_year <- read.csv(paste0(outputFolder,"all_sources_prostate_cancer_treatment_dataset_mean_drugs_and_mean_classes_by_year.csv"))
fileName <- "prostate_avg_drug_class"
plotAggregateAvgDrugsAdministered(mean_drugs_and_mean_classes_by_year, cohortName = cohortName, outputFolder = outputFolder, fileName = fileName)

fileName <- "prostate_chemotherapy_neoadjuvant"
title <- "Percent Distribution of First-line Chemotherapy Neoadjuvant (Prostate)"
data <- read.csv(paste0(outputFolder,"all_sources_prostate_cancer_chemotherapy_neoadjuvant.csv"))
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)

fileName <- "prostate_chemotherapy_adjuvant"
title <- "Percent Distribution of First-line Chemotherapy Adjuvant (Prostate)"
data <- read.csv(paste0(outputFolder,"all_sources_prostate_cancer_chemotherapy_adjuvant.csv"))
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)

#########################################Lung############################################################
#Lung Cancer Average number of antineoplastics agents administered plot 
data <- read.csv(paste0(inputFolder,"all_sources_lung_cancer_treatment_dataset_percent_interventions_types_per_year.csv"))
cohortName = "Lung"
fileName = "lung_interventions_by_year"

#fix data by merging Total Lobectomy and Lobectomy into one
data$distinct_interventions_orig <- data$distinct_interventions
data <- data %>% 
  mutate(tmp_col = str_replace(data$distinct_interventions, "Total Lobectomy", "Lobectomy"))  %>% 
  mutate(distinct_interventions = sapply(strsplit(tmp_col, " \\+ "), 
                                       function(x) paste(unique(x), collapse = " + ")))
plotAggregateInterventions(data, cohortName = cohortName, outputFolder = outputFolder, fileName = fileName)


mean_drugs_and_mean_classes_by_year <- read.csv(paste0(outputFolder,"all_sources_lung_cancer_treatment_dataset_mean_drugs_and_mean_classes_by_year.csv"))
fileName <- "lung_avg_drug_class"
plotAggregateAvgDrugsAdministered(mean_drugs_and_mean_classes_by_year, cohortName = cohortName, outputFolder = outputFolder, fileName = fileName)

####Lung Chemo
fileName <- "lung_chemotherapy_neoadjuvant"
title <- "Percent Distribution of First-line Chemotherapy Neoadjuvant (Lung)"
data <- read.csv(paste0(outputFolder,"all_sources_lung_cancer_chemotherapy_neoadjuvant.csv"))
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)


fileName <- "lung_chemotherapy_adjuvant"
title <- "Percent Distribution of First-line Chemotherapy Adjuvant (Lung)"
data <- read.csv(paste0(outputFolder,"all_sources_lung_cancer_chemotherapy_adjuvant.csv"))
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)

####Lung EGFR
fileName <- "lung_egfr_neoadjuvant"
title <- "Percent Distribution of First-line EGFR Therapy Neoadjuvant (Lung)"
data <- read.csv(paste0(outputFolder,"all_sources_lung_cancer_egfr_therapy_neoadjuvant.csv"))
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)


fileName <- "lung_egfr_adjuvant"
title <- "Percent Distribution of First-line EGFR Therapy Adjuvant (Lung)"
data <- read.csv(paste0(outputFolder,"all_sources_lung_cancer_egfr_therapy_adjuvant.csv"))
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)

####Lung VEGF
fileName <- "lung_vegf_neoadjuvant"
title <- "Percent Distribution of First-line VEGF Therapy Neoadjuvant (Lung)"
data <- read.csv(paste0(outputFolder,"all_sources_lung_cancer_vegf_therapy_neoadjuvant.csv"))
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)


fileName <- "lung_vegf_adjuvant"
title <- "Percent Distribution of First-line VEGF Therapy Adjuvant (Lung)"
data <- read.csv(paste0(outputFolder,"all_sources_lung_cancer_vegf_therapy_adjuvant.csv"))
plotAggregateAnalyses(data, outputFolder = outputFolder, fileName = fileName, title = title)

#########################################Multiple Myeloma############################################################
#for f in `ls | grep multiple | grep interventions_types_per_year.csv`; do awk 'NR == 1 {print $0 ",\"source\""; split(FILENAME, a, "_"); SOURCE = a[1]; next;}{print $0 ","SOURCE}' $f; done | sort -r  | uniq > all/all_sources_multiple_myeloma_treatment_dataset_interventions_types_per_year.csv  
data <- read.csv(paste0(inputFolder,"all_sources_multiple_myeloma_treatment_dataset_percent_interventions_types_per_year.csv"))
cohortName = "Multiple Myeloma"
fileName = "mm_interventions_by_year"
plotAggregateInterventions(data, cohortName = cohortName, outputFolder = outputFolder, fileName = fileName)

#MM Average number of antineoplastics agents administered plot 
#for f in `ls | grep multiple | grep mean_drugs_and_mean_classes_by_year.csv`; do awk 'NR == 1 {print $0 ",\"source\""; split(FILENAME, a, "_"); SOURCE = a[1]; next;}{print $0 ","SOURCE}' $f; done | sort -r  | uniq > all/all_sources_multiple_myeloma_treatment_dataset_mean_drugs_and_mean_classes_by_year.csv
mean_drugs_and_mean_classes_by_year <- read.csv(paste0(outputFolder,"all_sources_multiple_myeloma_treatment_dataset_mean_drugs_and_mean_classes_by_year.csv"))
fileName <- "mm_avg_drug_class"
plotAggregateAvgDrugsAdministered(mean_drugs_and_mean_classes_by_year, cohortName = cohortName, outputFolder = outputFolder, fileName = fileName)



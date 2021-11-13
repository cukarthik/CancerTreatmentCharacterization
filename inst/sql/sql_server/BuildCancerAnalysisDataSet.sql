--This is a generic script that builds the an analytic dataset for a cancer.
--It references CanMED for drugs and a list of concept codes for procedures
--and tranfusions from a table created prior the execution of this script.

{DEFAULT @window_in_months = "12"}
{DEFAULT @procedure_list = "nci_procedure_concept_code_list"}

----------------------------------------------------
---Starting with @cohort_table table and grabbing
----all relevant drug records and procedure records
----subsequent to biopsy date in NCI_phenotype table

---------------------------------------------------------------
-----DROPPING ALL TEMP TABLES FOR RE-EXECUTION OF SCRIPT-------
---------------------------------------------------------------
IF OBJECT_ID('#all_nci_procedures', 'U') IS NOT NULL
    DROP TABLE #all_nci_procedures;
IF OBJECT_ID('#all_nci_procedures_no_dups', 'U') IS NOT NULL
    DROP TABLE #all_nci_procedures_no_dups;
-- IF OBJECT_ID('#all_nci_pts_all_drugs', 'U') IS NOT NULL
-- DROP TABLE #all_nci_pts_all_drugs;
IF OBJECT_ID('#all_nci_pts_all_drugs_no_dups', 'U') IS NOT NULL
    DROP TABLE #all_nci_pts_all_drugs_no_dups;
IF OBJECT_ID('#min_proc_date', 'U') IS NOT NULL
    DROP TABLE #min_proc_date;
IF OBJECT_ID('#min_proc_date_fr', 'U') IS NOT NULL
    DROP TABLE #min_proc_date_fr;
IF OBJECT_ID('#min_procedure_date_added', 'U') IS NOT NULL
    DROP TABLE #min_procedure_date_added;
IF OBJECT_ID('#neoadjuvant_field', 'U') IS NOT NULL
    DROP TABLE #neoadjuvant_field;
IF OBJECT_ID('#all_nci_pts_all_transfusions', 'U') IS NOT NULL
    DROP TABLE #all_nci_pts_all_transfusions;
IF OBJECT_ID('#demographics', 'U') IS NOT NULL
    DROP TABLE #demographics;
IF OBJECT_ID('@target_database_schema.@target_cohort_dataset_name', 'U') IS NOT NULL
    DROP TABLE @target_database_schema.@target_cohort_dataset_name;

IF OBJECT_ID('@target_database_schema.temp_nci_cancer_treatments', 'U') IS NOT NULL
    DROP TABLE @target_database_schema.temp_nci_cancer_treatments;

CREATE TABLE @target_database_schema.temp_nci_cancer_treatments
(
    person_id    BIGINT,
    cohort_start_date    date,
    cohort_end_date    date,
    intervention_type    varchar(100),
    intervention_date date,
    generic_drug_name varchar(500),
    rx_category varchar(100),
    major_class varchar(100),
    minor_class varchar(100),
    concept_id INT,
    concept_name varchar(500),
    approval_year date,
    first_in_class INT,
    quantity FLOAT,
    dose_unit_source_value varchar(50),
    drug_source_value varchar(500)
);

------------------------------
-----CODE LIST PREPARATION----
------------------------------
--**********************************************************************************************************************
select distinct nci.cohort_definition_id,
                subject_id,
                cohort_start_date,
                cohort_end_date,
                pc.concept_name as procedure_name,
                modality,
                procedure_concept_id,
                procedure_date
into #all_nci_procedures_no_dups
from @target_database_schema.@cohort_table nci
JOIN @cdm_database_schema.procedure_occurrence po ON nci.subject_id = po.person_id
JOIN @target_database_schema.@procedure_list pc on pc.concept_id = po.procedure_concept_id
WHERE po.procedure_date >= nci.cohort_start_date
  and po.procedure_date < DATEADD(month, @window_in_months, nci.cohort_start_date)
  and nci.cohort_definition_id = @cohort_id
  and pc.cohort_definition_id = @cohort_id
order by subject_id, procedure_date;

--------------------------------
---done with procedure records--
--------------------------------
--**********************************************************************************************************************

-------------------------------
---Now we grab drug records---
------------------------------
SELECT distinct cohort_definition_id,
                subject_id,
                cohort_start_date,
                cohort_end_date,
                generic_name,
                rx_category,
                major_class,
                minor_class,
                ancestor_concept_id,
                descendant_concept_id,
                descendant_concept,
                approval_year,
                first_in_class,
                drug_concept_id,
                drug_exposure_start_date,
                quantity,
                dose_unit_source_value,
                drug_source_value
into #all_nci_pts_all_drugs_no_dups
FROM @target_database_schema.@cohort_table nci
JOIN @cdm_database_schema.drug_exposure de ON nci.subject_id=de.person_id
JOIN @target_database_schema.@can_med_table drugs ON de.drug_concept_id=drugs.descendant_concept_id
-- LEFT JOIN @vocabulary_database_schema.concept_relationship cr on de.drug_concept_id = cr.concept_id_1
-- LEFT JOIN @vocabulary_database_schema.concept c2 on cr.concept_id_2 = c2.concept_id and cr.relationship_id = 'RxNorm has dose form'
where de.drug_exposure_start_date >= nci.cohort_start_date
  and de.drug_exposure_start_date <= DATEADD(month, @window_in_months, nci.cohort_start_date)
  and nci.cohort_definition_id = @cohort_id;

---------------------------------------------------------------
---COMBINE PROCEDURE RECORDS AND DRUG RECORDS
---TO CREATE ONE DATASET WITH ALL TREATMENT INFORMATION
---------------------------------------------------------------
INSERT INTO @target_database_schema.temp_nci_cancer_treatments
SELECT subject_id               as person_id,
       cohort_start_date,
       cohort_end_date,
       'Drug'                   as intervention_type,
       drug_exposure_start_date as intervention_date,
       generic_name             as generic_drug_name,
       rx_category,
       major_class,
       minor_class,
       descendant_concept_id    as concept_id,
       descendant_concept       as concept_name,
       approval_year,
       first_in_class,
       quantity,
       dose_unit_source_value,
       drug_source_value
FROM #all_nci_pts_all_drugs_no_dups
;

INSERT INTO @target_database_schema.temp_nci_cancer_treatments
SELECT subject_id           as person_id,
       cohort_start_date,
       cohort_end_date,
--        CASE
--            WHEN modality = 'Prostatectomy' THEN 'Prostatectomy'
--            WHEN modality = 'PET scan' THEN 'PET scan'
--            WHEN modality = 'Ultrasound' THEN 'Ultrasound'
--            WHEN modality = 'MRI' THEN 'MRI'
--            WHEN modality = 'Cryoablation' THEN 'Cryoablation'
--            WHEN modality = 'HIFU' THEN 'HIFU'
--            ELSE 'Radiotherapy'
--        END
       modality             AS intervention_type,
       procedure_date       as intervention_date,
       'NULL'               as generic_drug_name,
       'NULL'               as rx_category,
       'NULL'               as major_class,
       'NULL'               as minor_class,
       procedure_concept_id as concept_id,
       procedure_name       as concept_name,
       '01/01/2099'         as approval_year,
       99                   as first_in_class,
       -1                   as quantity,
       'NULL'               as dose_unit_source_value,
       'NULL'               as drug_source_value
FROM #all_nci_procedures_no_dups
;

---checking the resulting concatenated tables
-- select *
-- from @target_database_schema.temp_nci_cancer_treatments
-- order by person_id, intervention_date

---------------------------------
--DEVICE TABLE INFORMATION
---------------------------------
---------------------------------------------
--INSERTING TRANSFUSION DATA INTO MAIN FILE--
---------------------------------------------

SELECT nci.*,
       c.concept_name as concept_name,
       de.device_concept_id,
       de.device_exposure_start_date
INTO #all_nci_pts_all_transfusions
FROM @target_database_schema.@cohort_table nci
JOIN @cdm_database_schema.device_exposure de
ON nci.subject_id=de.person_id
    JOIN @vocabulary_database_schema.concept c on de.device_concept_id= c.concept_id
where de.device_exposure_start_date >= nci.cohort_start_date
  and de.device_exposure_start_date <= DATEADD(month, @window_in_months, nci.cohort_start_date)
  and c.vocabulary_id = 'ISBT'
  and nci.cohort_definition_id = @cohort_id
order by subject_id, device_exposure_start_date;


---INSERTING TEMP TABLE INFORMATION INTO MAIN DATASET
INSERT INTO @target_database_schema.temp_nci_cancer_treatments
SELECT distinct subject_id                 as person_id,
                cohort_start_date,
                cohort_end_date,
                'Transfusion'              as intervention_type,
                device_exposure_start_date as intervention_date,
                'NULL'                     as generic_drug_name,
                'NULL'                     as rx_category,
                'NULL'                     as major_class,
                'NULL'                     as minor_class,
                device_concept_id          as concept_id,
                concept_name,
                '01/01/2099'               as approval_year,
                99                         as first_in_class,
                -1                         as quantity,
                'NULL'                     as dose_unit_source_value,
                'NULL'                     as drug_source_value
FROM #all_nci_pts_all_transfusions;

---------------------------------------------
----MOVING ON TO CREATING DERIVATIVE FIELDS
----THAT WILL BE USED IN R ANALYSES
---------------------------------------------
---creating MIN procedure Date for each patient using
-- surgery or radiotherapy dates for preparation of neoadjuvant adjuvant cut
select person_id, cohort_start_date, cohort_end_date, intervention_type, min(intervention_date) as min_procedure_date
into #min_proc_date
from @target_database_schema.temp_nci_cancer_treatments
where intervention_type in (
            select distinct modality
            from @target_database_schema.@procedure_list
            where cohort_definition_id = @cohort_id and
                  modality not in ('CT Scan', 'PET Scan', 'Mammography', 'Ultrasound', 'MRI')
      )--('Prostatectomy', 'Radiotherapy', 'Cryoablation', 'HIFU')
group by person_id, cohort_start_date, cohort_end_date, intervention_type
order by person_id, cohort_start_date, cohort_end_date, intervention_type
;

--drop table #min_proc_date_fr
select person_id, min(min_procedure_date) as min_procedure_date
into #min_proc_date_fr
from #min_proc_date
group by person_id
order by person_id
;

--drop table #min_procedure_date_added
select a.*, b.min_procedure_date
into #min_procedure_date_added
from @target_database_schema.temp_nci_cancer_treatments a
left join #min_proc_date_fr b ON a.person_id = b.person_id
;

-- select *
-- from #min_procedure_date_added
-- order by person_id, intervention_date

--Creating the neoadjuvant field
select *,
       case
           when intervention_type = 'Drug' and intervention_date < min_procedure_date then '1'
           when intervention_type = 'Drug' and intervention_date >= min_procedure_date then '0'
           else 'N'
           end as neoadjuvant
into #neoadjuvant_field
from #min_procedure_date_added
;
---drop table #neoadjuvant_field

---QA check to make sure neoadjuvant field is populated correctly
-- select *
-- from #neoadjuvant_field
-- where intervention_type in ('Surgery', 'Radiotherapy', 'Drug')
-- order by person_id, intervention_date
--
-- select *
-- from #neoadjuvant_field
-- where neoadjuvant = '1'
-- order by person_id, intervention_date
--
-- select *
-- from #neoadjuvant_field
-- order by intervention_date

--drop table #neoadjuvant_field

------------------------
---creating supportive vs cancer fighting ingredient distinction
select *,
       case
           when Rx_category = 'Ancillary Agent' then 'Chemo-supportive'
           when rx_category != 'Ancillary Agent' and intervention_type = 'Drug' then 'Antineoplastic'
           else 'NULL'
       end as ingredient_type
into #ingredient_type
from #neoadjuvant_field
order by person_id, intervention_date
;
-- select *
-- from #ingredient_type
-- order by person_id, intervention_date

select *
into #NCI_Cancer
from #ingredient_type
order by person_id, intervention_date

-- select *
-- from #NCI_Cancer
-- order by person_id, intervention_date

---------------------------------------------
----Bringing in Age, Ethnicity, Race fields--
---------------------------------------------
select nci.*
     , p.person_id
     , p.gender_source_value
     , p.year_of_birth
     , p.month_of_birth
     , p.day_of_birth
     , p.birth_datetime
     , year(cohort_start_date) - year_of_birth           as age_at_diagnosis
     , c.concept_name                                    as race
     , c2.concept_name                                   as ethnicity
     , loc.location_id
into #demographics
from @cdm_database_schema.person p
JOIN @target_database_schema.@cohort_table nci ON nci.subject_id = p.person_id
JOIN @vocabulary_database_schema.concept c ON p.race_concept_id = c.concept_id
JOIN @vocabulary_database_schema.concept c2 ON p.ethnicity_concept_id = c2.concept_id
LEFT JOIN @cdm_database_schema.location loc ON p.location_id = loc.location_id
WHERE nci.cohort_definition_id = @cohort_id
order by subject_id
;
---QC steps for #demo data
-- select race, count(*) as count
-- from #demographics
-- group by race
-- order by count (*)

-- select age_at_diagnosis, count(*) as count
-- from #demographics
-- group by age_at_diagnosis
-- order by age_at_diagnosis

select nci.*,
       d.age_at_diagnosis,
       d.race,
       d.ethnicity
into #NCI_with_demographics
from #NCI_Cancer nci
JOIN #demographics d ON nci.person_id = d.person_id
order by person_id, intervention_date
;

--------------------------------
-----CREATE DOSING COLUMNS-----
-------------------------------
-----using the newly created drug_strength table to populate the dose field
select f.*, ds.amount_value, ds.numerator_value
INTO #NCI_Cancer_DrugStrength
FROM #NCI_with_demographics f
LEFT JOIN @vocabulary_database_schema.drug_strength ds ON f.concept_id = ds.drug_concept_id
order by person_id, intervention_date;

---drop table #NCI_Cancer_DrugStrength

--this is a correction step b/c we are adding dosing
--todo: refactor to include dosing by making NCI_Cancer a temp table
DROP TABLE #NCI_Cancer;


-----------------------------------
select x.*, year(cohort_start_date) as cohort_year
into #dataset
from #NCI_Cancer_DrugStrength as x
-- join #patient_interventions as p on p.person_id = x.person_id and p.cohort_year = year(x.cohort_start_date)
order by x.person_id, x.intervention_date
;

select distinct de.*,
                case
                    when lower(c2.concept_name) like '%oral%' then 'Oral'
                    when c2.concept_id = 19135866 then 'Oral' --Chewable Tablet
                    when c2.concept_id = 19127776 and lower(de.concept_name) like '%oral%' then 'Oral'
                    when lower(c2.concept_name) like '%vaginal%' then 'Vaginal'
                    when lower(c2.concept_name) like '%topical%' then 'Skin'
                    when lower(c2.concept_name) like '%transderm%' then 'Skin'
                    when lower(c2.concept_name) like '%inject%' then 'Injection'
                    when lower(c2.concept_name) like '%ophthal%' then 'Ophthalmic'
                    when c2.concept_id = 19126920 then 'Injection' --Chewable Tablet
                    when c2.concept_id is null and d.route_concept_id in (4302612, 4142048) then 'Injection'
                    when c2.concept_id is null and d.route_concept_id = 4263689 then 'Skin'
                    when c2.concept_id is null and d.route_concept_id = 4132161 then 'Oral'
                    when r.concept_id is not null then r.route
                    else c2.concept_name
                end                                                              as route,
                CONCAT(SUBSTRING(cast(age_at_diagnosis as varchar), 1, 1), '0s') as age_group,
                YEAR(cohort_start_date)                                          as dx_year
--              , d.route_concept_id, c3.concept_name as route_name, d.drug_source_value AS d_drug_source_value
into @target_database_schema.@target_cohort_dataset_name
FROM #dataset de (nolock)
LEFT JOIN @cdm_database_schema.drug_exposure d (nolock) on de.concept_id= d.drug_concept_id
    AND de.person_id=d.person_id
    AND de.intervention_date= d.drug_exposure_start_date
LEFT JOIN @vocabulary_database_schema.concept_relationship cr on de.concept_id = cr.concept_id_1
    and cr.relationship_id = 'RxNorm has dose form'
    AND de.intervention_type = 'Drug'
LEFT JOIN @vocabulary_database_schema.concept c2 on cr.concept_id_2 = c2.concept_id
LEFT JOIN @vocabulary_database_schema.concept c3 on d.route_concept_id = c3.concept_id
LEFT JOIN @target_database_schema.@ingredient_routes_table r on r.concept_id = d.drug_concept_id
;

IF OBJECT_ID('@target_database_schema.temp_nci_cancer_treatments', 'U') IS NOT NULL
    DROP TABLE @target_database_schema.temp_nci_cancer_treatments;


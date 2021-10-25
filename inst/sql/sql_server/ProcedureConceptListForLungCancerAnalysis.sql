{DEFAULT @table_name = "nci_procedure_concept_code_list"}
{DEFAULT @cohort_id = 1775949}

IF OBJECT_ID('#procedure_codes', 'U') IS NOT NULL
 DROP TABLE #procedure_codes;
 --------------------------------------------------------------------
-----PROCEDURE CODE LIST PREPARATION for prostate cancer dataset----
--------------------------------------------------------------------
CREATE TABLE #procedure_codes
(
    procedure_concept_id   INT,
    procedure_name	       VARCHAR(255),
	modality			   VARCHAR(100)
)
 -----1. RADIOTHERAPY CODES--------------
--(this insertion into #procedure_codes looks different than the rest of the insertions b/c grabbing high level radiation code leads to observation only codes, which won't and don't help in the PO table. 

--grabbing radiotherapy records associated with BC patients with  'radiation' or 'brachytherapy' word
INSERT INTO #procedure_codes
select distinct
  c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Radiotherapy' as modality
from @vocabulary_database_schema.concept C where concept_name like '%radiation%' or concept_name like '%brachytherapy%'
and standard_concept = 'S'
and domain_id = 'PROCEDURE'
;

-----2. SURGICAL CODES--------------

--Total Lobectomy Codes
INSERT INTO #procedure_codes
select distinct c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Total Lobectomy' as modality
from @vocabulary_database_schema.concept_ancestor ca (nolock)
join @vocabulary_database_schema.concept c (nolock)  on ca.descendant_concept_id=c.concept_id
where ca.ancestor_concept_id in (4234745, 45887822) --'total lobectomy of lung'
  and
      ca.descendant_concept_id not in (
            select distinct ca.descendant_concept_id
            from @vocabulary_database_schema.concept_ancestor ca (nolock)
            where ca.ancestor_concept_id in (45890571, 4067713) --Removal of lung, other than pneumonectomy, Bilobectomy of lung
        )
;

--ToDo: need to re-evaluate this concept set
--partial lobectomy codes
INSERT INTO #procedure_codes
select
c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Lobectomy' as modality
from @vocabulary_database_schema.concept c
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4070879  --'lobectomy of lung'
and
      ca.descendant_concept_id not in (
          select distinct c.concept_id
            from @vocabulary_database_schema.concept_ancestor ca (nolock)
            join @vocabulary_database_schema.concept c (nolock)  on ca.descendant_concept_id=c.concept_id
            where ca.ancestor_concept_id in (4234745, 45887822, 4067713) --'total lobectomy of lung', 'Bilobectomy of lung'
              and
                  ca.descendant_concept_id not in (
                        select distinct ca.descendant_concept_id
                        from @vocabulary_database_schema.concept_ancestor ca (nolock)
                        where ca.ancestor_concept_id = 45890571 --Removal of lung, other than pneumonectomy
              )
        )
order by procedure_name
;

--Bilobectomy
INSERT INTO #procedure_codes
select
c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Bilobectomy' as modality
from @vocabulary_database_schema.concept c
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4067713 --'Bilobectomy of lung'
order by procedure_name
;

--total pneumonectomy
INSERT INTO #procedure_codes
select
c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Pneumonectomy' as modality
from @vocabulary_database_schema.concept c
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id in (4172438, 1014125)  --'Total pneumonectomy'  'Removal of lung, pneumonectomy'
order by procedure_name
;

--wedge resection
INSERT INTO #procedure_codes
select
c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Wedge Resection' as modality
from @vocabulary_database_schema.concept c
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4337034 --'Wedge excision of lung' ---40485447  --'Thoracoscopic wedge resection of lung'
order by procedure_name
;

--CryoAblation Codes
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Cryoablation' as modality
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id in (4328579, 45765611, 4233443, 4332525, 2110046, 42628460, 4146273 ) --CT, fluoresence, MRI and ultrasound guided ablation, respectively
;

--CT Scans
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'CT Scan' as modality
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4060500;

--PET Scans
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'PET Scan' as modality
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4305790 and c.concept_name not like '%myocardial%'
;

--Prostate Ultrasounds
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Ultrasound' as modality
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4037672 and concept_name like '%lung%'
;

--MRI (whole body)
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'MRI' as modality
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4013636
;

INSERT INTO @target_database_schema.@table_name
-- select distinct 1775947, procedure_concept_id, procedure_name, modality, 'Procedure'
select distinct @cohort_id, procedure_concept_id, procedure_name, modality, 'Procedure'
from #procedure_codes
order by procedure_concept_id
;

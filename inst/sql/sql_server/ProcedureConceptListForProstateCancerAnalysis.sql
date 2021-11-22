{DEFAULT @table_name = "nci_procedure_concept_code_list"}
{DEFAULT @cohort_id = 1775947}

--------------------------------------------------------------------
-----PROCEDURE CODE LIST PREPARATION for prostate cancer dataset----
--------------------------------------------------------------------
CREATE TABLE #procedure_codes
(
    procedure_concept_id   INT,
    procedure_name	       VARCHAR(255),
	modality			   VARCHAR(100)
);

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

--Prostatectomy codes
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Prostatectomy' as modality
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id in (45889370, 4235738)
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

--High intensity Focused Ultrasound ablation
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'HIFU' as modality
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id in (42628583, 36676810);

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
where ca.ancestor_concept_id = 4037672 and concept_name like '%prostate%'
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

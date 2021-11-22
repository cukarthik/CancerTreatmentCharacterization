{DEFAULT @table_name = "nci_procedure_concept_code_list"}
{DEFAULT @cohort_id = 1775946}

--------------------------------------------------------------------
-----PROCEDURE CODE LIST PREPARATION for breast cancer dataset----
--------------------------------------------------------------------
-----1. RADIOTHERAPY CODES--------------
CREATE TABLE #procedure_codes
(
    procedure_concept_id   INT,
    procedure_name	       VARCHAR(255),
	modality			   VARCHAR(100)
);

--BreastAblationCodes (radiotherapy codes)
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
--OperationOnBreastCodes

--Radical Mastectomy
INSERT INTO #procedure_codes
select
c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Radical Mastectomy' as modality
from @vocabulary_database_schema.concept c
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4298492
;

--Partial Mastectomy/Lumpectomy
INSERT INTO #procedure_codes
select
c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Partial Mastectomy' as modality
from @vocabulary_database_schema.concept c
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4275911
;

--Cryoablation Codes
INSERT INTO #procedure_codes
select
c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Cryoablation' as modality
from @vocabulary_database_schema.concept c
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id in (4328579, 45765611, 4233443, 4332525)
;

--CT Scans
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'CT Scan' as intervention_type
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4060500
;

--PET Scans
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'PET Scan' as intervention_type
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4305790 and c.concept_name not like '%myocardial%';

--Mammographies
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Mammography' as intervention_type
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4324693
;

--Breast Ultrasounds
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'Ultrasound' as intervention_type
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4264054
;

--MRI (whole body)
INSERT INTO #procedure_codes
select c.concept_id as procedure_concept_id
, c.concept_name as procedure_name
, 'MRI' as intervention_type
from @vocabulary_database_schema.concept c 
join @vocabulary_database_schema.concept_ancestor ca on c.concept_id=ca.descendant_concept_id
where ca.ancestor_concept_id = 4013636
order by procedure_name
;

---create permanent table that can be referenced by the 'building BC dataset' script
INSERT INTO @target_database_schema.@table_name
select distinct @cohort_id, procedure_concept_id, procedure_name, modality, 'Procedure'
from #procedure_codes
order by procedure_concept_id
;

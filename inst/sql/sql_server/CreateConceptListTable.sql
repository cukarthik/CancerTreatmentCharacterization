{DEFAULT @table_name = "nci_procedure_concept_code_list"}

IF OBJECT_ID('@target_database_schema.@table_name', 'U') IS NOT NULL
DROP TABLE @target_database_schema.@table_name;

CREATE TABLE @target_database_schema.@table_name
(
	cohort_definition_id int,
	concept_id int not null,
	concept_name varchar(255),
	modality varchar(150),
    domain_id varchar(20)
)


{DEFAULT @table_name = "can_med"}

IF OBJECT_ID('@target_database_schema.@table_name', 'U') IS NOT NULL
DROP TABLE @target_database_schema.@table_name;

CREATE TABLE @target_database_schema.@table_name
(
	generic_name varchar(500),
	rx_category varchar(150),
	major_class varchar(250),
	minor_class varchar(250),
	ancestor_concept_id int not null,
	descendant_concept_id int not null,
	descendant_concept varchar(255) not null,
	approval_year date,
	first_in_class int not null
)


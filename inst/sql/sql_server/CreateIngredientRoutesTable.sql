{DEFAULT @table_name = "ingedrient_routes"}

IF OBJECT_ID('@target_database_schema.@table_name', 'U') IS NOT NULL
	DROP TABLE @target_database_schema.@table_name;

CREATE TABLE @target_database_schema.@table_name (
	concept_id INT,
	concept_name varchar(200),
	route varchar(50)
);
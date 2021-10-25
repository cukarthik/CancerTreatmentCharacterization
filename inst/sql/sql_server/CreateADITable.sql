{DEFAULT @table_name = "adi_data"}

IF OBJECT_ID('@target_database_schema.@table_name', 'U') IS NOT NULL
DROP TABLE @target_database_schema.@table_name;

CREATE TABLE @target_database_schema.@table_name
(
	STATE varchar(2),
	TYPE varchar(5),
	ZIPID varchar(10),
	FIPS varchar(12),
	GISJOIN varchar(15),
	ADI_NATRANK varchar(20),
	ADI_STATERNK varchar(20)
)



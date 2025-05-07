USE DATABASE {{ database }};
USE SCHEMA {{ schema }};

CREATE OR REPLACE STAGE employee_stage
  URL='s3://api-data-snowflake/employees/'
  DIRECTORY = ( ENABLE = TRUE,  AUTO_REFRESH = true )
  STORAGE_INTEGRATION = api_data_aws_integration;



CREATE OR REPLACE STAGE department_stage
  URL='s3://api-data-snowflake/departments/'
  DIRECTORY = ( ENABLE = TRUE,  AUTO_REFRESH = true )
  STORAGE_INTEGRATION = api_data_aws_integration;



CREATE OR REPLACE STAGE jobs_stage
  URL='s3://api-data-snowflake/jobs/'
  DIRECTORY = ( ENABLE = TRUE,  AUTO_REFRESH = true )
  STORAGE_INTEGRATION = api_data_aws_integration;


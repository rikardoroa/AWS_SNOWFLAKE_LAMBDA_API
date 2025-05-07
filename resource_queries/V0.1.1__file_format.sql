USE DATABASE {{ database }};
USE SCHEMA {{ schema }};


CREATE OR REPLACE FILE FORMAT employee_data
TYPE = 'CSV'
FIELD_DELIMITER = ',' 

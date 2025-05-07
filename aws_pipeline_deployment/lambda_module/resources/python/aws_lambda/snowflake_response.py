import os
import snowflake.connector
import boto3
import json
import pandas as pd


class SnowflakeApi:

    def __init__(self):
        self.session = boto3.session.Session()
        self.client = self.session.client(service_name='secretsmanager')
        self.secret = "snowflake_credentials"

    def get_secret(self):
        response = self.client.get_secret_value(SecretId=self.secret)
        snowflake_data = json.loads(response['SecretString'])
        return snowflake_data

    def get_connection(self):
        snowflake_data = self.get_secret()
        conn = snowflake.connector.connect(
            account=snowflake_data['account'],
            user=snowflake_data['user'],
            password=snowflake_data['password'],
            warehouse=snowflake_data['warehouse'],
            database=snowflake_data['database'],
            schema=snowflake_data['schema'],
            role=snowflake_data['role']
        )
        return conn

    def get_employee_data(self):
        conn = self.get_connection()
        cur = conn.cursor()
        cur.execute('select * from EMPLOYEE')
        emp_results = cur.fetchall()

        df = pd.DataFrame(emp_results,
                          columns=['EMPLOYEE_ID', 'EMPLOYEE_NAME', 'EMPLOYEE_HIRED_DATE', 'EMPLOYEE_DPT_ID',
                                   'EMPLOYEE_JOB_ID'])
        df['EMPLOYEE_HIRED_DATE'] = df['EMPLOYEE_HIRED_DATE'].astype('str')
        all_emp_data = json.loads(df.to_json(orient='records'))
        return all_emp_data
  

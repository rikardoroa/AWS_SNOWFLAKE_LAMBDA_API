import os
import snowflake.connector
import boto3
import json
import pandas as pd
import logging



logger = logging.getLogger()
logger.setLevel(logging.INFO)


class SnowflakeApi:

    def __init__(self):
        self.session = boto3.session.Session()
        self.client = self.session.client(service_name='secretsmanager')
        self.secret = "snowflake_credentials"

    def get_secret(self):
        try:
            response = self.client.get_secret_value(SecretId=self.secret)
            snowflake_data = json.loads(response['SecretString'])
            return snowflake_data
        except Exception as e:
             logger.info(f"can not retrieve the secret:{e}")

    def get_connection(self):
        try:
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
        except Exception as e:
             logger.info(f"can not connect to snowflake, verify connection credentials:{e}")

    def get_data(self, table):
        try:
            conn = self.get_connection()
            cur = conn.cursor()
            if table == 'employee':
                cur.execute('select * from employee order by  employee_id')
                emp_results = cur.fetchall()
                df = pd.DataFrame(emp_results)
                df['EMPLOYEE_HIRED_DATE'] = df['EMPLOYEE_HIRED_DATE'].astype('str')
                all_emp_data = json.loads(df.to_json(orient='records'))
                return all_emp_data

            if table == 'departments':
                cur.execute('select * from departments')
                dpt_results = cur.fetchall()
                df = pd.DataFrame(dpt_results)
                all_dpt_data = json.loads(df.to_json(orient='records'))
                return all_dpt_data

            if table == 'jobs':
                cur.execute('select * from jobs')
                job_results = cur.fetchall()
                df = pd.DataFrame(job_results)
                all_job_data = json.loads(df.to_json(orient='records'))
                return all_job_data
        except Exception as e:
             logger.info(f"can not create the dataframe, verify the process:{e}")


  

  

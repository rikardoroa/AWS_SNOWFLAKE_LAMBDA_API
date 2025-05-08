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
             
            metadata = {
                    'employee': 'select * from employee order by employee_id',
                    'departments':'select * from departments',
                    'jobs': 'select * from jobs'
            }

            query = metadata.get(table)
            if query:
                cur.execute(query)
                snowflake_table_results = cur.fetchall()
                columns = [desc[0] for desc in cur.description]
                df = pd.DataFrame(snowflake_table_results, columns=columns)
                all_data = json.loads(df.to_json(orient='records'))
                return all_data
            else:
                return [{"error": f"Invalid table '{table}' specified."}]


          
        except Exception as e:
             logger.info(f"can not create the dataframe, verify the process:{e}")


  

  

import json
import pandas as pd
from snowflake.connector.pandas_tools import write_pandas
from snowflake_response import SnowflakeApi

api = SnowflakeApi()

class PostSnowflakeData:


    @classmethod
    def postdata(cls, payload):


        df = pd.DataFrame(payload)
        chunks = 1000
        start = 0
        for i in range(0,len(df),chunks):
            chunks_df = df.loc[start:chunks]
            if len(chunks_df) != 0:
                PostSnowflakeData.insert_data(chunks_df)
            start = chunks + 1
            chunks = (start-1) + 1000
            
        return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"message": "success"}, default=str)  
                }

    @classmethod
    def insert_data(cls, chunks):
        try:
            conn = api.get_connection()
            write_pandas(
                conn=conn,
                df=chunks,
                table_name='EMPLOYEE',   
                schema='API_DATA', 
            )
            conn.close()
        except Exception as e:
            print(f"this is the error:{e}")
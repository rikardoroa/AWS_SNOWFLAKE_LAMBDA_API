import json
import pandas as pd
from snowflake.connector.pandas_tools import write_pandas
from snowflake_response import SnowflakeApi

api = SnowflakeApi()

class PostSnowflakeData:


    @classmethod
    def postdata(cls, payload):


        df = pd.DataFrame(payload)
        chunks = round(df2.shape[0] / 1000)
        start = 0
        end  = 1000
        for i in range(0,chunks):
            chunks_df = df.loc[start:end]
            PostSnowflakeData.insert_data(chunks_df)
            start = end + 1
            end = (start-1) + 1000

        return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"message": "success"}, default=str)  
                }

    @classmethod
    def insert_data(cls, chunks):
        conn = api.get_connection()
        write_pandas(
            conn=conn,
            df=chunks,
            table_name='EMPLOYEE',   
            schema='API_DATA',      
            quote_identifiers=False   
        )
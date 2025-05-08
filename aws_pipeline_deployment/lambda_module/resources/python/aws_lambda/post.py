import json
import pandas as pd
from snowflake.connector.pandas_tools import write_pandas
from snowflake_response import SnowflakeApi
import logging



logger = logging.getLogger()
logger.setLevel(logging.INFO)


api = SnowflakeApi()

class PostSnowflakeData:


    @classmethod
    def postdata(cls, payload, table):
        try:
            df = pd.DataFrame(payload)
            chunks = 1000
            start = 0
            for i in range(0,len(df),chunks):
                chunks_df = df.loc[start:chunks]
                if len(chunks_df) != 0:
                    PostSnowflakeData.insert_data(chunks_df, table)
                start = chunks + 1
                chunks = (start-1) + 1000
        

            return {
                        "statusCode": 200,
                        "headers": {"Content-Type": "application/json"},
                        "body": json.dumps({"message": "success"}, default=str)  
                    }
        except Exception as e:
             logger.info(f"can not create the chunks, verify the process:{e}")


    @classmethod
    def insert_data(cls, chunks, table):
        try:

            conn = api.get_connection()
            cur = conn.cursor()
            cur.execute("SELECT CURRENT_SCHEMA()")
            schema = cur.fetchone()[0]
            write_pandas(
                conn=conn,
                df=chunks,
                table_name=table,   
                schema=schema, 
            )
            conn.close()
        except Exception as e:
              logger.info(f"can not insert the data into snowflake, we have this error:{e}")
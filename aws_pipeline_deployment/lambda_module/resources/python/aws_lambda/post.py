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
        
        """
        Splits the input data into chunks and inserts them into the specified Snowflake table.

        Args:
            payload (list[dict]): A list of JSON records to insert.
            table (str): The name of the Snowflake table to insert into.

        Returns:
            dict: A standard API response object with status code and message.

        Logs:
            Logs an error if chunking or processing fails.
        """
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
            
            """
            Inserts a chunk of data into a specified Snowflake table using the write_pandas helper.

            Args:
                chunks (pd.DataFrame): A DataFrame containing the data to insert.
                table (str): The name of the table where the data will be inserted.

            Logs:
                Logs an error message if insertion fails.
            """

            conn = api.get_connection()
            cur = conn.cursor()
            cur.execute("SELECT CURRENT_SCHEMA()")
            schema = cur.fetchone()[0]
            write_pandas(
                conn=conn,
                df=chunks,
                table_name=table.upper(),   
                schema=schema, 
            )
            conn.close()
        except Exception as e:
              logger.info(f"can not insert the data into snowflake, we have this error:{e}")
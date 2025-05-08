import json
import pandas as pd
from snowflake.connector.pandas_tools import write_pandas
from snowflake_response import SnowflakeApi

api = SnowflakeApi()

class PostSnowflakeData:


    @classmethod
    def postdata(cls, payload):


        df = pd.DataFrame(payload)
        print(df)
        print("hol rroa")
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

            emp_data = chunks.values.tolist()
            conn = api.get_connection()
            cur = conn.cursor()
            insert_sql = """
                INSERT INTO EMPLOYEE (
                    EMPLOYEE_NAME,
                    EMPLOYEE_HIRED_DATE,
                    EMPLOYEE_DPT_ID,
                    EMPLOYEE_JOB_ID
                ) VALUES (%s, %s, %s, %s)
                """

            cur.executemany(insert_sql, emp_data)
            conn.commit()
            conn.close()


            # conn = api.get_connection()
            # write_pandas(
            #     conn=conn,
            #     df=chunks,
            #     table_name='EMPLOYEE',   
            #     schema='API_DATA', 
            # )
            # conn.close()
        except Exception as e:
            print(f"this is the error:{e}")
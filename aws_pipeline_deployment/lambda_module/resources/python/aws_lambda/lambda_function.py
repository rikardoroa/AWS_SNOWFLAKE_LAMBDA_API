import json
from snowflake_response import SnowflakeApi

def lambda_handler(event, context):
    
    api = SnowflakeApi()
    api.get_secret()


    method = event.get("httpMethod", "").upper()

    if method == "GET":
        try:
            employees = api.get_employee_data()
            #print(employees)

            return {
                    "statusCode": status_code,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": str(e)}, default=str)  
            }

        except Exception as e:
            return  {
                    "statusCode": 500,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps(employees, default=str)  
            }


    

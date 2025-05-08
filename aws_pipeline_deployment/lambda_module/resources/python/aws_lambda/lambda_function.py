import json
from snowflake_response import SnowflakeApi
from get import GetSnowflakeData

def lambda_handler(event, context):
    
    api = SnowflakeApi()
    api.get_secret()
    get_data  = GetSnowflakeData ()

    method = event.get("httpMethod", "").upper()

    if method == "GET":
    
            employees = api.get_employee_data()
            result = get_data.getdata(employees)
            return result
         

    if method == "POST":
        payload = json.loads(event["body"])
        print(payload)
        return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"message": "success"}, default=str)  
                }


    

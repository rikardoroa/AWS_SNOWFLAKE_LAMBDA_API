import json
from snowflake_response import SnowflakeApi
from get import GetSnowflakeData
from post import PostSnowflakeData

def lambda_handler(event, context):
    
    api = SnowflakeApi()
    api.get_secret()
    get_data  = GetSnowflakeData ()
    post_data = PostSnowflakeData()
    print("hola ricardo roa")
    print(event)


    method = event.get("httpMethod", "").upper()

    if method == "GET":
    
        employees = api.get_employee_data()
        result = get_data.getdata(employees)
        return result
         

    if method == "POST":
        response = json.loads(event["body"])
        payload = post_data.postdata(response)
        return payload


    return {
                   
                "body": json.dumps({"message": "success"})  
            }

        


    

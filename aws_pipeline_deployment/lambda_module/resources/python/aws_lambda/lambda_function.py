import json
from snowflake_response import SnowflakeApi

def lambda_handler(event, context):
    
    api = SnowflakeApi()
    api.get_secret()
    emp = api.get_employee_data()
    print(emp)



    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }

import json
from snowflake_response import SnowflakeApi
from get import GetSnowflakeData
from post import PostSnowflakeData

def lambda_handler(event, context):

    """
    Handles HTTP GET and POST requests via API Gateway to interact with Snowflake.

    - GET: Returns data from the specified table (via ?table=...).
    - POST: Inserts data into the specified table from request body.

    Args:
        event (dict): Incoming request from API Gateway.
        context (object): Lambda context (unused).

    Returns:
        dict: API response with statusCode and JSON body.
    """
    
    api = SnowflakeApi()
    api.get_secret()
    get_data  = GetSnowflakeData ()
    post_data = PostSnowflakeData()
  
  
    method = event.get("httpMethod", "").upper()
    query_params = event.get("queryStringParameters")
    table = query_params.get("table", "").lower()
    
    if query_params:

        if table:
            if method == "GET":
                result = api.get_data(table)
                query =  get_data.getdata(result)
                return query

            if method == "POST":
                response = json.loads(event["body"])
                payload = post_data.postdata(response, table)
                return payload

        if table is None:
                return {
                        "body": json.dumps({"error": "can't  retrieve data!, use a query"})  
                    }

    return {
                   
                "body": json.dumps({"message": "success"})  
            }

        


    

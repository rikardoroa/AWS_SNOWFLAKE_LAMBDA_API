import json


class GetSnowflakeData:

    @classmethod
    def getdata(cls, payload):
        try:

            return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps(payload, default=str)   
            }
        except Exception as e:
            return  {
                    "statusCode": 500,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"error": str(e)}, default=str)  
            }




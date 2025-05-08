import json


class PostSnowflakeData:


    @classmethod
    def postdata(cls, payload):

        print(payload)
        return {
                    "statusCode": 200,
                    "headers": {"Content-Type": "application/json"},
                    "body": json.dumps({"message": "success"}, default=str)  
                }
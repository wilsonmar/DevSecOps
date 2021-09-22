# aws-lambda-email-send-boto3.py
# based on https://gist.github.com/nktstudios/082eaac2d179dbc564a2b280a838d851

import json
import boto3

def lambda_handler(event, context):
    
    ses = boto3.client('ses')

    body = """
	    Hello and welcome to the SES Lambda Python Demo.
	
	    Regards,
	    NKT Studios
    """

    ses.send_email(
	    Source = 'insert FROM address here',
	    Destination = {
		    'ToAddresses': [
			    'Insert TO address here'
		    ]
	    },
	    Message = {
		    'Subject': {
			    'Data': 'SES Demo',
			    'Charset': 'UTF-8'
		    },
		    'Body': {
			    'Text':{
				    'Data': body,
				    'Charset': 'UTF-8'
			    }
		    }
	    }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Successfully sent email from Lambda using Amazon SES')
    }
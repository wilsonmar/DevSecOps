#!/bin/bash

# ssl_cert_req.sh in 
# Called from ssl_cert_req.tf.
# Based on https://github.com/divgo/terraform/tree/master/aws_ssl_static_website

# Extract the "site_name" variable from input JSON
eval "$(jq -r '@sh "domain=\(.site_name)"')"

# issue a CLI to request our cert
cert=$(aws acm request-certificate --domain-name $domain)
echo $cert > out.txt # output the response to a local file

# open the local file & pass to jq so we can extract the arn
certarn=$(cat out.txt | jq -r ".CertificateArn")

# output the arn so we can inpect if we want to
echo $certarn >> out.txt

# return a valid JSON document so we can reference the arn later
jq -n --arg cert_arn "$certarn" '{"CertificateArn":$cert_arn}'
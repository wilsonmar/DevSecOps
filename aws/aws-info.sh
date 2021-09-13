#!/usr/bin/env bash

# aws-info.sh in DevSecOps/ aws
# Based on https://medium.com/circuitpeople/aws-cli-with-jq-and-bash-9d54e2eabaf1
#          https://theagileadmin.com/2017/05/26/aws-cli-queries-and-jq/

# After you obtain a Terminal (console) in your enviornment,
# cd to folder, copy this line and paste in the terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/aws/aws-info.sh)" -v -i


# https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
export AWS_PROFILE="cdb-aws-09"
echo ">>> Edit ~/.aws/credentials"
echo ">>> Setup credentials from AVM to AWS_PROFILE=$AWS_PROFILE :"

echo ">>> aws whoami: Calling UserId, Account, Arn?"
# https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html
aws sts get-caller-identity

# echo ">>> When was AWS user account created?"
# https://docs.aws.amazon.com/cli/latest/reference/iam/get-user.html
# ERROR: aws iam get-user --user-name "$AWS_PROFILE" --cli-input-json "json" | jq -r ".User.CreateDate[:4]" 

# Laghima Mishra on golden images

echo ">>> What AWS account is being used?"
{ aws sts get-caller-identity & aws iam list-account-aliases; } | jq -s ".|add"

echo ">>> Which region is being used?"
aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]'

echo ">>> How many instances of each type running/stopped?"
aws ec2 describe-instances | jq -r "[[.Reservations[].Instances[]|{ state: .State.Name, type: .InstanceType }]|group_by(.state)|.[]|{state: .[0].state, types: [.[].type]|[group_by(.)|.[]|{type: .[0], count: ([.[]]|length)}] }]"
   # [ { "state": "running", "types": [ { "type": "t3.medium", "count": 1    } ] } ]

echo ">>> Which of my EC2 Security Groups are being used?"
MY_SEC_GROUPS="$( aws ec2 describe-network-interfaces | jq '[.NetworkInterfaces[].Groups[]|.]|map({ (.GroupId|tostring): true }) | add'; aws ec2 describe-security-groups | jq '[.SecurityGroups[].GroupId]|map({ (.|tostring): false })|add'; )"
# echo "MY_SEC_GROUPS=$MY_SEC_GROUPS"
echo "$MY_SEC_GROUPS" | jq -s '[.[1], .[0]]|add|to_entries|[group_by(.value)[]|{ (.[0].value|if . then "in-use" else "unused" end): [.[].key] }]|add' 



echo ">>> What CIDRs have Ingress Access to which Ports?"
aws ec2 describe-security-groups | jq '[ .SecurityGroups[].IpPermissions[] as $a | { "ports": [($a.FromPort|tostring),($a.ToPort|tostring)]|unique, "cidr": $a.IpRanges[].CidrIp } ] | [group_by(.cidr)[] | { (.[0].cidr): [.[].ports|join("-")]|unique }] | add'

echo ">>> How many Gigabytes of Volumes do I have, by Status?"
aws ec2 describe-volumes | jq -r '.Volumes | [ group_by(.State)[] | { (.[0].State): ([.[].Size] | add) } ] | add'

echo ">>> Which Lambda Functions Runtimes am I Using?"
aws lambda list-functions | jq ".Functions | group_by(.Runtime)|[.[]|{ runtime:.[0].Runtime, functions:[.[]|.FunctionName] }
]"

echo ">>> Is everyone taking the time to set memory size and the time out appropriately?"
aws lambda list-functions | jq ".Functions | group_by(.Runtime)|[.[]|{ (.[0].Runtime): [.[]|{ name: .FunctionName, timeout: .Timeout, memory: .MemorySize }] }]"
   # [{ "python3.6": [ { "name": "aws-controltower-NotificationForwarder", "timeout": 60, "memory": 128 }]

echo ">>> Lambda Function Environment Variables: exposing secrets in variables? Have a typo in a key?"
aws lambda list-functions | jq -r '[.Functions[]|{name: .FunctionName, env: .Environment.Variables}]|.[]|select(.env|length > 0)'

echo ">>> RDS (Relational Data Service) Instance Endpoints:"
aws rds describe-db-instances | jq -r '.DBInstances[] | { (.DBInstanceIdentifier):(.Endpoint.Address + ":" + (.Endpoint.Port|tostring))}'

echo ">>> How many AWS services?"
curl -s https://raw.githubusercontent.com/boto/botocore/develop/botocore/data/endpoints.json \
   | jq -r '.partitions[0].services | keys[]' | wc -l

echo ">>> EC2 parentage: Which EC2 Instances were created by Stacks?"
for stack in $(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE | jq -r '.StackSummaries[].StackName'); do aws cloudformation describe-stack-resources --stack-name $stack | jq -r '.StackResources[] | select (.ResourceType=="AWS::EC2::Instance")|.PhysicalResourceId'; done;

echo ">>> How many Snapshot volumes do I have?"
aws ec2 describe-snapshots --owner-ids self | jq '.Snapshots | length'

echo ">>> how large are EC2 Snapshots in total?"
aws ec2 describe-snapshots --owner-ids self | jq '[.Snapshots[].VolumeSize] | add'

echo ">>> H do they breakdown by the volume used to create them?"
aws ec2 describe-snapshots --owner-ids self | jq '.Snapshots | [ group_by(.VolumeId)[] | { (.[0].VolumeId): { "count": (.[] | length), "size": ([.[].VolumeSize] | add) } } ] | add'


echo ">>> getting the log group names (space delimited):"
logs=$(aws logs describe-log-groups | jq -r '.logGroups[].logGroupName')
echo ">>> log=$log "

echo ">>> first log stream for each:"
for group in $logs; do echo $(aws logs describe-log-streams --log-group-name $group --order-by LastEventTime --descending --max-items 1 | jq -r '.logStreams[0].logStreamName + " "'); done

exit -1


echo ">>> Loop through the groups and streams and get the last 10 messages since midnight:"
# for group in $logs; do for stream in $(aws logs describe-log-streams --log-group-name $group --order-by LastEventTime --descending --max-items 1 | jq -r '[ .logStreams[0].logStreamName + " "] | add'); do echo ">>>"; echo GROUP: $group; echo STREAM: $stream; aws logs get-log-events --limit 10 --log-group-name $group --log-stream-name $stream --start-time $(date -d 'today 00:00:00' '+%s%N' | cut -b1-13) | jq -r ".events[].message"; done; done


echo ">>> Much Data is in Each of my Buckets?"
   # CloudWatch contains the data, but if your account has more than a few buckets it’s very tedious to use.
   # This little command gives your the total size of the objects in each bucket, one per line, with human-friendly numbers:
for bucket in $( aws s3api list-buckets --query "Buckets[].Name" --output text); \
   do aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name BucketSizeBytes --dimensions Name=BucketName,Value=$bucket Name=StorageType,Value=StandardStorage --start-time $(date --iso-8601)T00:00 --end-time $(date --iso-8601)T23:59 --period 86400 --statistic Maximum | echo $bucket: $(numfmt --to si $(jq -r ".Datapoints[0].Maximum // 0")); done;

echo ">>> Prefer to have that is dollars per month? Just a little math ( based on the current standard tier price of $0.023 per GB per month):"
for bucket in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name BucketSizeBytes --dimensions Name=BucketName,Value=$bucket Name=StorageType,Value=StandardStorage --start-time $(date --iso-8601)T00:00 --end-time $(date --iso-8601)T23:59 --period 86400 --statistic Maximum | echo $bucket: \$$(jq -r "(.Datapoints[0].Maximum //
 0) * .023 / (1024*1024*1024) * 100.0 | floor / 100.0"); done;




------------------

# https://okigiveup.net/tutorials/discovering-aws-with-cli-part-1-basics/
# https://github.com/afroisalreadyinu/aws-containers
echo ">>> Create VPC based on CIDR"  # see https://docs.amazonaws.cn/en_us/vpc/latest/userguide/vpc-subnets-commands-example.html
# aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text

echo ">>> Step 1: Creating EC2 Instances to find (this is slow, ’cause there are a *lot* of AMIs) and hold it in an environment variable:"
export AMI_ID=$(aws ec2 describe-images --owners amazon | jq -r ".Images[] | { id: .ImageId, desc: .Description } | select(.desc?) | select(.desc | contains(\"Amazon Linux 2\")) | select(.desc | contains(\".NET Core 2.1\")) | .id")

echo ">>> AMI_ID=$AMI_ID Step 2: Create a key pair, to file keypair.pem :"
aws ec2 create-key-pair --key-name aurora-test-keypair > keypair.pem

echo ">>> TODO: Identify subnet id:"
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-subnets.html
# https://wiki.outscale.net/display/EN/Getting+Information+About+Your+Subnets
# TODO: <your_subnet_id>

echo ">>> Step 3: Create the instance using the AMI and the key pair, and hold onto the result in a file:"
aws ec2 run-instances --instance-type t2.micro --image-id $AMI_ID --region us-east-1 --subnet-id <your_subnet_id> --key-name keypair --count 1 > instance.json

echo ">>> Step 4: Grab the instance Id from the file:"
export INSTANCE_ID=$(jq -r .Instances[].InstanceId instance.json)

echo ">>> Step 5: Wait for the instance to spin-up, then grab it’s IP address and hold onto it in an environment variable:"
export INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text --query 'Reservations[*].Instances[*].PublicIpAddress')

------------------------

echo ">>> Which Services are being used?"
# While it *can* be answered in the Config console UI (given enough clicks), or using Cost Explorer (fewer clicks), 
if mac:
# For MacOS: https://stackoverflow.com/questions/63559669/get-first-date-of-current-month-in-macos-terminal
# And https://www.freebsd.org/cgi/man.cgi?date
   MONTH_FIRST_DAY=$( date -v1d -v"$(date '+%m')"m '+%Y-%m-%d' )  # yields 2021-09-01
      # The -v1d is a time adjust flag to move to the first day of the month
      # In -v"$(date '+%m')"m, we get the current month number using date '+%m' and use it to populate the month adjust field. So e.g. for Aug 2020, its set to -v8m
      # The '+%F' prints the date in YYYY-MM-DD format. If not supported in your date version, use +%Y-%m-%d explicitly.
      # To print all 12 months: for mon in {1..12}; do; date -v1d -v"$mon"m '+%F'; done
   # ERROR: MONTH_LAST_DAY=$( date -v2d -v-1d '+%Y-%m-%d' )  # for 2021-09-30
else
   MONTH_FIRST_DAY=$(date "+%Y-%m-01" -d "-1 Month")
endif
   # This requires GNU date and is not portable (notably Mac / *BSD date is different)
   aws ce get-cost-and-usage --time-period Start="$MONTH_FIRST_DAY",End=$(date --date="$(date +'%Y-%m-01') - 1 second" -I) \
      --granularity MONTHLY --metrics UsageQuantity \
      --group-by Type=DIMENSION,Key=SERVICE | jq '.ResultsByTime[].Groups[] | select(.Metrics.UsageQuantity.Amount > 0) | .Keys[0]'
      # date "+%Y-%m-01" yields 2021-09-01, see https://www.cyberciti.biz/faq/linux-unix-formatting-dates-for-display/
      # See https://stackoverflow.com/questions/27920201/how-can-i-get-the-1st-and-last-date-of-the-previous-month-in-a-bash-script/46897063

   echo ">>> What is each service costing me (for the current month):"
   aws ce get-cost-and-usage --time-period Start=$(date "+%Y-%m-01"),End=$(date --date="$(date +'%Y-%m-01') + 1 month  - 1 second" -I) \
      --granularity MONTHLY --metrics USAGE_QUANTITY BLENDED_COST  \
      --group-by Type=DIMENSION,Key=SERVICE | jq '[ .ResultsByTime[].Groups[] | select(.Metrics.BlendedCost.Amount > "0") | { (.Keys[0]): .Metrics.BlendedCost } ] | sort_by(.Amount) | add'

# cat vpc.dat | jq  '.[0]'
#'.Vpcs[] '
#echo vpc.dat | jq '.Vpcs[]  | select(.DOMAIN == "domain2") | .DOMAINID'
# jq '.arr | map( first(.[] | objects) // null | .text ) | index("VpcId") ' <vpc.dat

# jq '.Vpcs | to_entries | .[] | select(.value[3].text | contains("VpcId")) | .key' <vpc.dat
   # jq '.arr | to_entries | .[] | select(.value[3].text | contains("FooBar")) | .key' <test.json
   # .arr | map( first(.[] | objects) // null | .text ) | index("FooBar")
   # See https://stackoverflow.com/questions/53986312/have-jq-return-the-index-number-of-an-element-in-an-array/53986579

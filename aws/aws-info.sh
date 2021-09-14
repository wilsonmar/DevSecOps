#!/usr/bin/env bash

# aws-info.sh in https://github.com/wilsonmar/DevSecOps/blob/main/aws/aws-info.sh
# Based on https://medium.com/circuitpeople/aws-cli-with-jq-and-bash-9d54e2eabaf1
#          https://theagileadmin.com/2017/05/26/aws-cli-queries-and-jq/

# After you obtain a Terminal (console) in your environment,
# cd to folder, copy this line (without the # first character) and paste in the Terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/master/aws/aws-info.sh)"

# SETUP STEP 01 - Capture starting timestamp and display no matter how it ends:
THIS_PROGRAM="$0"
SCRIPT_VERSION="v0.1.8"
# clear  # screen (but not history)

EPOCH_START="$( date -u +%s )"  # such as 1572634619
LOG_DATETIME=$( date +%Y-%m-%dT%H:%M:%S%z)-$((1 + RANDOM % 1000))
echo "=========================== $LOG_DATETIME $THIS_PROGRAM $SCRIPT_VERSION"

# SETUP STEP 02 - Ensure run variables are based on arguments or defaults ..."
args_prompt() {
   echo "USAGE EXAMPLE:"
   echo "./sample.sh -u \"Default\" "
   echo "OPTIONS:"
   echo "   -E           to set -e to NOT stop on error"
   echo "   -x           to set -x to trace command lines"
#   echo "   -x           to set sudoers -e to stop on error"
   echo "   -v           to run -verbose (list space use and each image to console)"
   echo "   -q           -quiet headings for each step"
   echo " "
   echo "   -I           -Install brew, docker, docker-compose"
   echo "   -U           -Upgrade packages"
   echo "   -p           -p \"cdb-aws-09\" "
   echo " "
 }
if [ $# -eq 0 ]; then  # display if no parameters are provided:
   args_prompt
   exit 1
fi
exit_abnormal() {            # Function: Exit with error.
  echo "exiting abnormally"
  #args_prompt
  exit 1
}

# SETUP STEP 03 - Set Defaults (default true so flag turns it true):
   SET_EXIT=true                # -E
   RUN_QUIET=false              # -q
   SET_TRACE=false              # -x
   RUN_VERBOSE=false            # -v
   UPDATE_PKGS=false            # -U
   DOWNLOAD_INSTALL=false       # -I
   AWS_PROFILE="Default"        # -p

# SETUP STEP 04 - Read parameters specified:
while test $# -gt 0; do
  case "$1" in
    -E)
      export SET_EXIT=false
      shift
      ;;
    -q)
      export RUN_QUIET=true
      shift
      ;;
    -I)
      export DOWNLOAD_INSTALL=true
      shift
      ;;
    -x)
      export SET_TRACE=true
      shift
      ;;
    -U)
      export UPDATE_PKGS=true
      shift
      ;;
    -v)
      export RUN_VERBOSE=true
      shift
      ;;
    -p*)
      shift
             AWS_PROFILE=$( echo "$1" | sed -e 's/^[^=]*=//g' )
      export AWS_PROFILE
      shift
      ;;
    *)
      error "Parameter \"$1\" not recognized. Aborting."
      exit 0
      break
      ;;
  esac
done


# SETUP STEP 04 - Set ANSI color variables (based on aws_code_deploy.sh): 
bold="\e[1m"
dim="\e[2m"
# shellcheck disable=SC2034 # ... appears unused. Verify use (or export if used externally).
underline="\e[4m"
# shellcheck disable=SC2034 # ... appears unused. Verify use (or export if used externally).
blink="\e[5m"
reset="\e[0m"
red="\e[31m"
green="\e[32m"
# shellcheck disable=SC2034 # ... appears unused. Verify use (or export if used externally).
blue="\e[34m"
cyan="\e[36m"

# SETUP STEP 05 - Specify alternate echo commands:
h2() { if [ "${RUN_QUIET}" = false ]; then    # heading
   printf "\n${bold}\e[33m\u2665 %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
   fi
}
info() {   # output on every run
   printf "${dim}\n➜ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
note() { if [ "${RUN_VERBOSE}" = true ]; then
   printf "\n${bold}${cyan} ${reset} ${cyan}%s${reset}" "$(echo "$@" | sed '/./,$!d')"
   printf "\n"
   fi
}
success() {
   printf "\n${green}✔ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
error() {    # &#9747;
   printf "\n${red}${bold}✖ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
warning() {  # &#9758; or &#9755;
   printf "\n${cyan}☞ %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}
fatal() {   # Skull: &#9760;  # Star: &starf; &#9733; U+02606  # Toxic: &#9762;
   printf "\n${red}☢  %s${reset}\n" "$(echo "$@" | sed '/./,$!d')"
}

# SETUP STEP 06 - Check what operating system is in use:
   OS_TYPE="$( uname )"
   OS_DETAILS=""  # default blank.
if [ "$(uname)" == "Darwin" ]; then  # it's on a Mac:
      OS_TYPE="macOS"
      PACKAGE_MANAGER="brew"
elif [ "$(uname)" == "Linux" ]; then  # it's on a Mac:
   if command -v lsb_release ; then
      lsb_release -a
      OS_TYPE="Ubuntu"
      # TODO: OS_TYPE="WSL" ???
      PACKAGE_MANAGER="apt-get"

      # TODO: sudo dnf install pipenv  # for Fedora 28

      silent-apt-get-install(){  # see https://wilsonmar.github.io/bash-scripts/#silent-apt-get-install
         if [ "${RUN_VERBOSE}" = true ]; then
            info "apt-get install $1 ... "
            sudo apt-get install "$1"
         else
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq "$1" < /dev/null > /dev/null
         fi
      }
   elif [ -f "/etc/os-release" ]; then
      OS_DETAILS=$( cat "/etc/os-release" )  # ID_LIKE="rhel fedora"
      OS_TYPE="Fedora"
      PACKAGE_MANAGER="yum"
   elif [ -f "/etc/redhat-release" ]; then
      OS_DETAILS=$( cat "/etc/redhat-release" )
      OS_TYPE="RedHat"
      PACKAGE_MANAGER="yum"
   elif [ -f "/etc/centos-release" ]; then
      OS_TYPE="CentOS"
      PACKAGE_MANAGER="yum"
   else
      error "Linux distribution not anticipated. Please update script. Aborting."
      exit 0
   fi
else 
   error "Operating system not anticipated. Please update script. Aborting."
   exit 0
fi
# note "OS_DETAILS=$OS_DETAILS"

# SETUP STEP 07 - Define utility functions, such as bash function to kill process by name:
ps_kill(){  # $1=process name
      PSID=$(ps aux | grep $1 | awk '{print $2}')
      if [ -z "$PSID" ]; then
         h2 "Kill $1 PSID= $PSID ..."
         kill 2 "$PSID"
         sleep 2
      fi
}

# SETUP STEP 08 - Adjust Bash version:
BASH_VERSION=$( bash --version | grep bash | cut -d' ' -f4 | head -c 1 )
   if [ "${BASH_VERSION}" -ge "4" ]; then  # use array feature in BASH v4+ :
      DISK_PCT_FREE=$(read -d '' -ra df_arr < <(LC_ALL=C df -P /); echo "${df_arr[11]}" )
      FREE_DISKBLOCKS_START=$(read -d '' -ra df_arr < <(LC_ALL=C df -P /); echo "${df_arr[10]}" )
   else
      if [ "${UPDATE_PKGS}" = true ]; then
         h2 "Bash version ${BASH_VERSION} too old. Upgrading to latest ..."
         if [ "${PACKAGE_MANAGER}" == "brew" ]; then
            brew install bash
         elif [ "${PACKAGE_MANAGER}" == "apt-get" ]; then
            silent-apt-get-install "bash"
         elif [ "${PACKAGE_MANAGER}" == "yum" ]; then    # For Redhat distro:
            sudo yum install bash      # please test
         elif [ "${PACKAGE_MANAGER}" == "zypper" ]; then   # for [open]SuSE:
            sudo zypper install bash   # please test
         fi
         info "Now at $( bash --version  | grep 'bash' )"
         fatal "Now please run this script again now that Bash is up to date. Exiting ..."
         exit 0
      else   # carry on with old bash:
         DISK_PCT_FREE="0"
         FREE_DISKBLOCKS_START="0"
      fi
   fi

# SETUP STEP 09 - Display run ending:"
trap this_ending EXIT
trap this_ending INT QUIT TERM
this_ending() {
   EPOCH_END=$(date -u +%s);
   EPOCH_DIFF=$((EPOCH_END-EPOCH_START))
   # Using BASH_VERSION identified above:
   if [ "${BASH_VERSION}" -lt "4" ]; then
      FREE_DISKBLOCKS_END="0"
   else
      FREE_DISKBLOCKS_END=$(read -d '' -ra df_arr < <(LC_ALL=C df -P /); echo "${df_arr[10]}" )
   fi
   FREE_DIFF=$(((FREE_DISKBLOCKS_END-FREE_DISKBLOCKS_START)))
   MSG="End of script $SCRIPT_VERSION after $((EPOCH_DIFF/360)) seconds and $((FREE_DIFF*512)) bytes on disk."
   # echo 'Elapsed HH:MM:SS: ' $( awk -v t=$beg-seconds 'BEGIN{t=int(t*1000); printf "%d:%02d:%02d\n", t/3600000, t/60000%60, t/1000%60}' )
   success "$MSG"
   # note "Disk $FREE_DISKBLOCKS_START to $FREE_DISKBLOCKS_END"
}
sig_cleanup() {
    trap '' EXIT  # some shells call EXIT after the INT handler.
    false # sets $?
    this_ending
}

#################### Print run heading:

# SETUP STEP 09 - Operating environment information:
HOSTNAME=$( hostname )
PUBLIC_IP=$( curl -s ifconfig.me )

if [ "$OS_TYPE" == "macOS" ]; then  # it's on a Mac:
   note "BASHFILE=~/.bash_profile ..."
   BASHFILE="$HOME/.bash_profile"  # on Macs
else
   note "BASHFILE=~/.bashrc ..."
   BASHFILE="$HOME/.bashrc"  # on Linux
fi

      note "Running $0 in $PWD"  # $0 = script being run in Present Wording Directory.
      note "Start time $LOG_DATETIME"
      note "Bash $BASH_VERSION from $BASHFILE"
      note "OS_TYPE=$OS_TYPE using $PACKAGE_MANAGER from $DISK_PCT_FREE disk free"
      note "on hostname=$HOSTNAME at PUBLIC_IP=$PUBLIC_IP."
      note " "
# print all command arguments submitted:
#while (( "$#" )); do 
#  echo $1 
#  shift 
#done 


IFS=$'\n\t'  #  Internal Field Separator for word splitting is line or tab, not spaces.

# SETUP STEP 10 - Define run error handling:
EXIT_CODE=0
if [ "${SET_EXIT}" = true ]; then  # don't
   note "Set -e (no -E parameter  )..."
   set -e  # exits script when a command fails
   # set -eu pipefail  # pipefail counts as a parameter
else
   warning "Don't set -e (-E parameter)..."
fi
if [ "${SET_XTRACE}" = true ]; then
   note "Set -x ..."
   set -x  # (-o xtrace) to show commands for specific issues.
fi
# set -o nounset


##############################################################################

note "============= User "

# See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html
# note "Edit ~/.aws/credentials"
note "Setup credentials to AWS_PROFILE=$AWS_PROFILE :"

note "aws whoami: Calling UserId, Account, Arn?"
# https://docs.aws.amazon.com/cli/latest/reference/sts/get-caller-identity.html
aws sts get-caller-identity
retVal=$?
if [ $retVal -ne 0 ]; then
   exit -1 
fi

# note "When was AWS user account created?"
# See https://docs.aws.amazon.com/cli/latest/reference/iam/get-user.html
# ERROR: aws iam get-user --user-name "$AWS_PROFILE" --cli-input-json "json" | jq -r ".User.CreateDate[:4]" 

note "What AWS account is being used?"
{ aws sts get-caller-identity & aws iam list-account-aliases; } | jq -s ".|add"

note "Which region is being used?"
aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]'


note "============= AWS Services "

note "How many AWS services available?"
curl -s https://raw.githubusercontent.com/boto/botocore/develop/botocore/data/endpoints.json \
   | jq -r '.partitions[0].services | keys[]' | wc -l

# While it *can* be answered in the Config console UI (given enough clicks), 
# or using Cost Explorer (fewer clicks), 
if [ "$OS_TYPE" == "macOS" ]; then  # it's on a Mac:
   # For MacOS: https://stackoverflow.com/questions/63559669/get-first-date-of-current-month-in-macos-terminal
   # And https://www.freebsd.org/cgi/man.cgi?date
   MONTH_FIRST_DAY=$( date -v1d -v-1m '+%Y-%m-%d' )  # yields 2021-08-01 previous month start
   # MONTH_FIRST_DAY=$( date -v1d -v"$(date '+%m')"m '+%Y-%m-%d' )  # yields 2021-09-01
      # The -v1d is a time adjust flag to move to the first day of the month
      # In -v"$(date '+%m')"m, we get the current month number using date '+%m' and use it to populate the month adjust field. So e.g. for Aug 2020, its set to -v8m
      # The '+%F' prints the date in YYYY-MM-DD format. If not supported in your date version, use +%Y-%m-%d explicitly.
      # To print all 12 months: for mon in {1..12}; do; date -v1d -v"$mon"m '+%F'; done
   # MONTH_LAST_DAY=$( date -v1d -v-1d -v+1m +%Y-%m-%d )  # for 2021-09-30
   MONTH_LAST_DAY=$( date -v1d -v-1d -v+0m +%Y-%m-%d )  # for 2021-09-30

else
   # This uses GNU date on Linus: not portable (notably Mac / *BSD date is different)
   # https://unix.stackexchange.com/questions/223543/get-the-date-of-last-months-last-day-in-a-shell-script
   MONTH_FIRST_DAY=$( date "+%Y-%m-01" -d "-1 Month" )
   MONTH_LAST_DAY=$( date --date="$(date +'%Y-%m-01') - 1 second" -I )  # for 2021-09-30
fi
   note "From $OS_TYPE - $MONTH_FIRST_DAY to $MONTH_LAST_DAY "
   # See https://docs.aws.amazon.com/cli/latest/reference/ce/get-cost-and-usage.html
#   aws ce get-cost-and-usage --time-period Start="$MONTH_FIRST_DAY",End="$MONTH_LAST_DAY" \
#      --granularity MONTHLY --metrics UsageQuantity \
#      --group-by Type=DIMENSION,Key=SERVICE | jq '.ResultsByTime[].Groups[] | select(.Metrics.UsageQuantity.Amount > 0) | .Keys[0]'
      # date "+%Y-%m-01" yields 2021-09-01, see https://www.cyberciti.biz/faq/linux-unix-formatting-dates-for-display/
      # See https://stackoverflow.com/questions/27920201/how-can-i-get-the-1st-and-last-date-of-the-previous-month-in-a-bash-script/46897063

   note "What is each service costing me for the previous month:"
   aws ce get-cost-and-usage --time-period Start="$MONTH_FIRST_DAY",End="$MONTH_LAST_DAY" \
      --granularity MONTHLY --metrics USAGE_QUANTITY BLENDED_COST  \
      --group-by Type=DIMENSION,Key=SERVICE | jq '[ .ResultsByTime[].Groups[] | select(.Metrics.BlendedCost.Amount > "0") | { (.Keys[0]): .Metrics.BlendedCost } ] | sort_by(.Amount) | add'

   note "What is each service costing me for the current month:"
   aws ce get-cost-and-usage --time-period Start="$MONTH_FIRST_DAY",End="$MONTH_LAST_DAY" \
      --granularity MONTHLY --metrics USAGE_QUANTITY BLENDED_COST  \
      --group-by Type=DIMENSION,Key=SERVICE | jq '[ .ResultsByTime[].Groups[] | select(.Metrics.BlendedCost.Amount > "0") | { (.Keys[0]): .Metrics.BlendedCost } ] | sort_by(.Amount) | add'


note "How many Snapshot volumes do I have?"
aws ec2 describe-snapshots --owner-ids self | jq '.Snapshots | length'
   # 4

note "how large are EC2 Snapshots in total?"
aws ec2 describe-snapshots --owner-ids self | jq '[.Snapshots[].VolumeSize] | add'

note "How do Snapshots breakdown by the volume used to create them?"
aws ec2 describe-snapshots --owner-ids self \
   | jq '.Snapshots | [ group_by(.VolumeId)[] | { (.[0].VolumeId): { "count": (.[] | length), "size": ([.[].VolumeSize] | add) } } ] | add'


note "============= Networking "

note "What CIDRs have Ingress Access to which Ports?"
aws ec2 describe-security-groups | jq '[ .SecurityGroups[].IpPermissions[] as $a | { "ports": [($a.FromPort|tostring),($a.ToPort|tostring)]|unique, "cidr": $a.IpRanges[].CidrIp } ] | [group_by(.cidr)[] | { (.[0].cidr): [.[].ports|join("-")]|unique }] | add'


note "============= Lambda "

note "Which Lambda Functions Runtimes am I Using?"
aws lambda list-functions | jq ".Functions | group_by(.Runtime)|[.[]|{ runtime:.[0].Runtime, functions:[.[]|.FunctionName] }
]"

note "Is everyone taking the time to set memory size and the time out appropriately?"
aws lambda list-functions | jq ".Functions | group_by(.Runtime)|[.[]|{ (.[0].Runtime): [.[]|{ name: .FunctionName, timeout: .Timeout, memory: .MemorySize }] }]"
   # [{ "python3.6": [ { "name": "aws-controltower-NotificationForwarder", "timeout": 60, "memory": 128 }]

note "Lambda Function Environment Variables: exposing secrets in variables? Have a typo in a key?"
aws lambda list-functions | jq -r '[.Functions[]|{name: .FunctionName, env: .Environment.Variables}]|.[]|select(.env|length > 0)'


note "============= EC2 "

note "How many instances of each type running/stopped?"
aws ec2 describe-instances | jq -r "[[.Reservations[].Instances[]|{ state: .State.Name, type: .InstanceType }]|group_by(.state)|.[]|{state: .[0].state, types: [.[].type]|[group_by(.)|.[]|{type: .[0], count: ([.[]]|length)}] }]"
   # [ { "state": "running", "types": [ { "type": "t3.medium", "count": 1    } ] } ]

note "Which of my EC2 Security Groups are being used?"
MY_SEC_GROUPS="$( aws ec2 describe-network-interfaces | jq '[.NetworkInterfaces[].Groups[]|.]|map({ (.GroupId|tostring): true }) | add'; aws ec2 describe-security-groups | jq '[.SecurityGroups[].GroupId]|map({ (.|tostring): false })|add'; )"
# echo "MY_SEC_GROUPS=$MY_SEC_GROUPS"
echo "$MY_SEC_GROUPS" | jq -s '[.[1], .[0]]|add|to_entries|[group_by(.value)[]|{ (.[0].value|if . then "in-use" else "unused" end): [.[].key] }]|add' 


note "EC2 parentage: Which EC2 Instances were created by Stacks?"
for stack in $(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
   | jq -r '.StackSummaries[].StackName'); do aws cloudformation describe-stack-resources --stack-name $stack \
   | jq -r '.StackResources[] | select (.ResourceType=="AWS::EC2::Instance")|.PhysicalResourceId'; done;


note "============= Disk usage "

note "How many Gigabytes of Volumes do I have, by Status?"
aws ec2 describe-volumes | jq -r '.Volumes | [ group_by(.State)[] | { (.[0].State): ([.[].Size] | add) } ] | add'


note "RDS (Relational Data Service) Instance Endpoints:"
aws rds describe-db-instances | jq -r '.DBInstances[] | { (.DBInstanceIdentifier):(.Endpoint.Address + ":" + (.Endpoint.Port|tostring))}'


note "============= Logs "

note "getting the log group names (space delimited):"
logs=$(aws logs describe-log-groups | jq -r '.logGroups[].logGroupName')
note "log=$log "

note "first log stream for each:"
for group in $logs; do echo $(aws logs describe-log-streams --log-group-name $group --order-by LastEventTime --descending --max-items 1 | jq -r '.logStreams[0].logStreamName + " "'); done

exit -1


# note "Loop through the groups and streams and get the last 10 messages since midnight:"
# for group in $logs; do for stream in $(aws logs describe-log-streams --log-group-name $group --order-by LastEventTime --descending --max-items 1 | jq -r '[ .logStreams[0].logStreamName + " "] | add'); do h2 ""; echo GROUP: $group; echo STREAM: $stream; aws logs get-log-events --limit 10 --log-group-name $group --log-stream-name $stream --start-time $(date -d 'today 00:00:00' '+%s%N' | cut -b1-13) | jq -r ".events[].message"; done; done


note "How much Data is in Each of my S3 Buckets?"
   # CloudWatch contains the data, but if your account has more than a few buckets it’s very tedious to use.
   # This little command gives your the total size of the objects in each bucket, one per line, with human-friendly numbers:
for bucket in $( aws s3api list-buckets --query "Buckets[].Name" --output text); \
   do aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name BucketSizeBytes --dimensions Name=BucketName,Value=$bucket Name=StorageType,Value=StandardStorage --start-time $(date --iso-8601)T00:00 --end-time $(date --iso-8601)T23:59 --period 86400 --statistic Maximum \
   | echo $bucket: $(numfmt --to si $(jq -r ".Datapoints[0].Maximum // 0")); done;

note "In dollars per month? (based on the standard tier price of $0.023 per GB per month):"
for bucket in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do aws cloudwatch get-metric-statistics --namespace AWS/S3 --metric-name BucketSizeBytes --dimensions Name=BucketName,Value=$bucket Name=StorageType,Value=StandardStorage --start-time $(date --iso-8601)T00:00 --end-time $(date --iso-8601)T23:59 --period 86400 --statistic Maximum | echo $bucket: \$$(jq -r "(.Datapoints[0].Maximum //
 0) * .023 / (1024*1024*1024) * 100.0 | floor / 100.0"); done;




------------------

# https://okigiveup.net/tutorials/discovering-aws-with-cli-part-1-basics/
# https://github.com/afroisalreadyinu/aws-containers
note "Create VPC based on CIDR"  # see https://docs.amazonaws.cn/en_us/vpc/latest/userguide/vpc-subnets-commands-example.html
# aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query Vpc.VpcId --output text

note "Step 1: Creating EC2 Instances to find (this is slow, ’cause there are a *lot* of AMIs) and hold it in an environment variable:"
export AMI_ID=$(aws ec2 describe-images --owners amazon | jq -r ".Images[] | { id: .ImageId, desc: .Description } | select(.desc?) | select(.desc | contains(\"Amazon Linux 2\")) | select(.desc | contains(\".NET Core 2.1\")) | .id")

note "AMI_ID=$AMI_ID Step 2: Create a key pair, to file keypair.pem :"
aws ec2 create-key-pair --key-name aurora-test-keypair > keypair.pem

note "TODO: Identify subnet id:"
# https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-subnets.html
# https://wiki.outscale.net/display/EN/Getting+Information+About+Your+Subnets
# TODO: <your_subnet_id>

note "Step 3: Create the instance using the AMI and the key pair, and hold onto the result in a file:"
aws ec2 run-instances --instance-type t2.micro --image-id $AMI_ID --region us-east-1 --subnet-id <your_subnet_id> --key-name keypair --count 1 > instance.json

note "Step 4: Grab the instance Id from the file:"
export INSTANCE_ID=$(jq -r .Instances[].InstanceId instance.json)

note "Step 5: Wait for the instance to spin-up, then grab it’s IP address and hold onto it in an environment variable:"
export INSTANCE_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --output text --query 'Reservations[*].Instances[*].PublicIpAddress')

------------------------


# cat vpc.dat | jq  '.[0]'
#'.Vpcs[] '
#echo vpc.dat | jq '.Vpcs[]  | select(.DOMAIN == "domain2") | .DOMAINID'
# jq '.arr | map( first(.[] | objects) // null | .text ) | index("VpcId") ' <vpc.dat

# jq '.Vpcs | to_entries | .[] | select(.value[3].text | contains("VpcId")) | .key' <vpc.dat
   # jq '.arr | to_entries | .[] | select(.value[3].text | contains("FooBar")) | .key' <test.json
   # .arr | map( first(.[] | objects) // null | .text ) | index("FooBar")
   # See https://stackoverflow.com/questions/53986312/have-jq-return-the-index-number-of-an-element-in-an-array/53986579

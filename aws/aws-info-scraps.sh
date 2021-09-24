aws-info-scraps.sh


   if [ -z "${AWS_REGION_IN}" ]; then   # variable is blank
      error "-R parameter Region is blank. Aborting."
      exit -1
   else
      note "Replacing Region \"$AWS_REGION\" with -R \"$AWS_REGION_IN\" ..."
      # X aws configure set profile.???.region "$AWS_REGION_IN"  # in ~/.aws/config
      aws configure set region "$AWS_REGION_IN"
      retVal=$?
      if [ $retVal -ne 0 ]; then
         fatal "Error $retVal returned"
         exit -1 
      fi
   fi

#!/usr/bin/env bash
# This is awslogin.sh in https://github.com/wilsonmar/DevSecOps/main/bash/awslogin.sh
# STATUS: NOT OPERATIONAL. Initital copy from original source

# Use this to log in to AWS CLI based on credentials which have been encrypted.
# cd to folder ~/.aws, then copy this line and paste in the terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/main/bash/awslogin.sh)" -v -i

# USAGE: ./awslogin.sh

# STEP 0 - Install what's necessary
# STEP 1 - Unencrypt the gpg file
# STEP 2 - Invoke aws login
# STEP 3 - Remove the unencrypted file

echo ">>> STEP 0 - Install what's necessary"

echo ">>> STEP 1 - Unencrypt the gpg-encrypted file"
# See https://www.gnupg.org/gph/en/manual/x110.html
gpg credential.gpg

echo ">>> STEP 2 - Invoke aws login"

echo ">>> STEP 3 - Remove the unencrypted file"

#EOF
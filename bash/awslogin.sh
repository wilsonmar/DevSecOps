#!/usr/bin/env bash
# This is awslogin.sh in https://github.com/wilsonmar/DevSecOps/blob/main/bash/awslogin.sh
# STATUS: NOT OPERATIONAL. Encryption using Yubikey 3C929BE82896FF01 rather than regular key.

# Use this to log in to AWS CLI based on credentials which have been encrypted.
# cd to folder ~/.aws, then copy this line and paste in the terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/main/bash/awslogin.sh)" -v -i

# USAGE: ./awslogin.sh

# STEP 0 - Get params and install what's necessary
# STEP 1 - Encrypt the CLEARTEXT file
# STEP 2 - Decrypt the gpg file
# STEP 3 - Log into aws
# STEP 4 - Remove the dencrypted file

# Similar: https://github.com/techservicesillinois/awscli-login


echo ">>> STEP 0 - Get params and install what's necessary:"

   set -e  # exits script when a command fails


# Read command parameters

CLEARTEXT_FILEPATH="$HOME/.aws/credentials"
# Create ENCRYPTED_FILEPATH="$HOME/.aws/credentials.gpg"
ENCRYPTED_FILEPATH="${CLEARTEXT_FILEPATH}.gpg"
   # NOTE: When encrypting to ASCII Armor suitable for transfer, encrypted files have extension .asc rather than .gpg which are binary files.
PROFILE_NAME=""
GPG_USERID="Wilson Mar"
SIGNING_ID="E21961814AC0EF1B"  # from: gpg --list-secret-keys --keyid-format LONG
DASH_V_IN_COMMAND="-v"

# Verbose:
   echo ">>> CLEARTEXT_FILEPATH=$CLEARTEXT_FILEPATH"
   echo ">>> ENCRYPTED_FILEPATH=$ENCRYPTED_FILEPATH"
   echo ">>> GPG_USERID=$GPG_USERID"
   echo ">>> SIGNING_ID=$SIGNING_ID"


# Install Xcode Command Line Utilities if that or XCode GUI was not installed:
# TODO:

if ! command -v brew ; then   # brew not recognized:
   echo ">>> Installing brew using Ruby."
   /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
   # Verify:
   if ! command -v brew ; then   # not recognized:
      echo ">>> brew install failed. Aborting."
      exit 9
   fi
fi

if ! command -v aws ; then   # not recognized:
   echo ">>> Installing aws (password needed)"  # per https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-mac.html#cliv2-mac-install-cmd
   # NOTE: No brew install awscli2  # awscli is now obsolete
   cd
   mkdir -p $HOME/.aws
   cd $HOME/.aws
   # TODO: On Windows: https://awscli.amazonaws.com/AWSCLIV2.msi  # See https://www.sqlshack.com/learn-aws-cli-an-overview-of-aws-cli-aws-command-line-interface/
   # On MacOS:
   curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
   ls -al AWSCLIV2.pkg
   sudo installer -pkg AWSCLIV2.pkg -target /
      # installer: Package name is AWS Command Line Interface
      # installer: Upgrading at base path /
      # installer: The upgrade was successful.
   # Verify:
   if ! command -v aws ; then   # /usr/local/bin/aws
      echo ">>> aws install failed. Aborting."
      exit 9
   else
      aws --version
         # aws-cli/2.2.22 Python/3.8.8 Darwin/18.7.0 exe/x86_64 prompt/off
      echo ">>> Removing installer AWSCLIV2.pkg."
      rm AWSCLIV2.pkg
   fi
fi


if ! command -v gpg ; then   # not recognized:
   echo ">>> Installing gpg using brew."
   brew install gpg
   # https://gnupg.org/download/index.html
   # Verify:
   if ! command -v gpg ; then   # not recognized:
      echo ">>> gpg install failed. Aborting."
      exit 9
   fi
fi

# TODO: pinentry?


echo ">>> STEP 1 - Encrypt the CLEARTEXT file:"

# Get public key:
# gpg --keyserver pgp.mit.edu  --search-keys search_parameters
# Is this nessary?  gpg --import pub.asc
# Get PGP user???
   # https://www.digitalocean.com/community/tutorials/how-to-use-gpg-to-encrypt-and-sign-messages
   # http://www.spywarewarrior.com/uiuc/gpg/gpg-com-4.htm
   # https://www.ibm.com/docs/en/tms-and-wt/version-missing?topic=keys-example-using-gnupg-encrypt-files-pgp-key
   # https://www.gnupg.org/gph/en/manual/x110.html


# Normal is haing an encrypted file but no cleartext file:
if [ -f "${ENCRYPTED_FILEPATH}" ]; then
   echo ">>> Encrypted ${ENCRYPTED_FILEPATH} found. Continuing."
else
   echo ">>> Encrypted ${ENCRYPTED_FILEPATH} not found! "
   # Cleartext file needed to encrypt:
   if [ ! -f "${CLEARTEXT_FILEPATH}" ]; then   # not found 
      echo ">>> ClearText ${CLEARTEXT_FILEPATH} not found to encrypt. Aborting."
      exit 9
   else
      echo ">>> Encrypting to ${ENCRYPTED_FILEPATH} for recipient \"${GPG_USERID}\"."
      # About aws configure  # https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html
      # NOTE: command ignores --sign-with "$SIGNING_ID" 
      # "${CLEARTEXT_FILEPATH}" must be last:
      gpg "$DASH_V_IN_COMMAND" --encrypt --recipient "${GPG_USERID}" "${CLEARTEXT_FILEPATH}"
      # --armor not used here to gen .asc file instead of .gpg file.
      # WARNING: the --recipient option comes before the --encrypt option.
      # This should create "${ENCRYPTED_FILEPATH}" (with .gpg added)
      # Test response return code:
      # exit
      ls -al "${ENCRYPTED_FILEPATH}"
   fi
fi


echo ">>> STEP 2 - Decrypt the gpg-encrypted file:"
# See https://www.gnupg.org/gph/en/manual/x110.html
if [ ! -f "${ENCRYPTED_FILEPATH}" ]; then   # not found 
   echo ">>> Encrypted ${ENCRYPTED_FILEPATH} not found! Please encrypt credentials. Aborting."
   exit 9
else
   echo ">>> Decrypting ${ENCRYPTED_FILEPATH} "
   gpg "$DASH_V_IN_COMMAND" --decrypt "${ENCRYPTED_FILEPATH}" 
      # where filename is the name of some file in your account and USERNAME is your username. This command will create filename.gpg. At this point you may choose to remove filename in favor of the encrypted file filename.gpg.
   status=$?  # 0 = success. 
   if [ "$status" != "0" ]; then
      echo ">>> $status returned from gpg decrypt."
      # For list of return codes, see https://docs.aws.amazon.com/cli/latest/topic/return-codes.html
      exit 9
   fi
   echo "\n"  # caz gpg decrypt doesn't.
fi


echo ">>> STEP 3 - Log into aws:"
if [ -z "${PROFILE_NAME}" ]; then  # var not defined or blank:
   aws login 
else
   aws login "$PROFILE" 
fi
      # Username [username]: netid
      # Password: ********
      # Factor:
      # Please choose the role you would like to assume:
      #     Account: 978517677611
      #         [ 0 ]: Admin
      #     Account: 520135271718
      #         [ 1 ]: ReadOnlyUser
      #         [ 2 ]: S3Admin
      # Selection: 2

      # NOTE: To switch roles: aws logout 

# Verify login success.
   status=$?  # 0 = success. 
   if [ "$status" != "0" ]; then
      echo ">>> $status returned from aws login."
      # For list of return codes, see https://docs.aws.amazon.com/cli/latest/topic/return-codes.html
      exit 9
   else
      aws whoami
         # {
         #     "UserId": "ABCDEFGAZFAHIXMFIGLK3",
         #     "Account": "123456789718",
         #     "Arn": "arn:aws:iam::123456789718:user/John_Doe"
         # }      
      aws myip
         # 192.161.70.87
   fi
   
# See AWSCLI2 with MFA https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html
# https://www.youtube.com/watch?v=FBidz7mlB1s
# aws configure sso

# Verify login success:
# aws iam get-user


echo ">>> STEP 4 - Remove the decrypted file:"
if [ -f "${CLEARTEXT_FILEPATH}" ]; then   # found:
   echo ">>> ${CLEARTEXT_FILEPATH} still exists! Removing it."
   rm -rf "${CLEARTEXT_FILEPATH}"
else
   echo ">>> done."
fi


# https://docs.aws.amazon.com/cli/latest/reference/

#EOF
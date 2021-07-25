#!/usr/bin/env bash
# This is awslogin.sh in https://github.com/wilsonmar/DevSecOps/blob/main/bash/awslogin.sh
# STATUS: NOT OPERATIONAL. Encryption using Yubikey 3C929BE82896FF01 rather than regular key.

# Use this to log in to AWS CLI based on credentials which have been encrypted.
# cd to folder ~/.aws, then copy this line and paste in the terminal:
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/wilsonmar/DevSecOps/main/bash/awslogin.sh)" -v -i

# USAGE: ./awslogin.sh

# STEP 0 - Get params and install what's necessary
# STEP 1 - Encrypt the CLEARTEXT file
# STEP 2 - Unencrypt the gpg file
# STEP 3 - Invoke aws login
# STEP 4 - Remove the unencrypted file


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
fi

if ! command -v gpg ; then   # not recognized:
   echo ">>> Installing gpg using brew."
   brew install gpg
   # https://gnupg.org/download/index.html
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
   echo ">>> Encrypted ${ENCRYPTED_FILEPATH} found."
else
   echo ">>> Encrypted ${ENCRYPTED_FILEPATH} not found! "
   # Cleartext file needed to encrypt:
   if [ ! -f "${CLEARTEXT_FILEPATH}" ]; then   # not found 
      echo ">>> ClearText ${CLEARTEXT_FILEPATH} not found to encrypt. Aborting."
      exit 9
   else
      echo ">>> Encrypting ${CLEARTEXT_FILEPATH} for recipient \"${GPG_USERID}\"."
      gpg -v --sign-with "$SIGNING_ID" --recipient "${GPG_USERID}" --encrypt "${CLEARTEXT_FILEPATH}"
      # --armor not used here to gen .asc file instead of .gpg file.
      # WARNING: the --recipient option comes before the --encrypt option.
      # This should create "${ENCRYPTED_FILEPATH}" (with .gpg added)
      # Test response return code:
      # exit
      ls -al "${ENCRYPTED_FILEPATH}"
   fi
fi


echo ">>> STEP 2 - Unencrypt the gpg-encrypted file:"
# See https://www.gnupg.org/gph/en/manual/x110.html
if [ ! -f "${ENCRYPTED_FILEPATH}" ]; then   # not found 
   echo ">>> Encrypted ${ENCRYPTED_FILEPATH} not found! Please encrypt credentials. Aborting."
   exit 9
else
   echo ">>> Unencrypt ${ENCRYPTED_FILEPATH} "
   gpg --decrypt -v "${ENCRYPTED_FILEPATH}"
   # gpg --decrypt "${ENCRYPTED_FILEPATH}"  "${CLEARTEXT_FILEPATH}"
      # where filename is the name of some file in your account and USERNAME is your username. This command will create filename.gpg. At this point you may choose to remove filename in favor of the encrypted file filename.gpg.
   # if rc bad then exit
   #    exit
   # fi
fi


echo ">>> STEP 3 - Invoke aws login:"
if [ -z "${PROFILE_NAME}" ]; then  # var not defined:
   aws login
else
   aws login "$PROFILE"
fi

# TODO: Verify login success.


echo ">>> STEP 4 - Remove the unencrypted file:"
if [ -f "${CLEARTEXT_FILEPATH}" ]; then   # found:
   echo ">>> ${CLEARTEXT_FILEPATH} still exists! Removing it."
   rm -rf "${CLEARTEXT_FILEPATH}"
else
   echo ">>> done."
fi

#EOF
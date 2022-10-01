#!/usr/bin/env bash
# ftpretry.sh within github.com/wilsonmar/DevSecOps
# git "v1.1 new from mcwalter"
#
# This script wraps a call to Linux ncftpget in a sleep-retry loop, 
# to make it download a large file over an intermittent
# connection. Usage:
#    chmod +x ftpretry.sh
#    ./ftpretry.sh  server-name remote-file
# e.g:
#    ./ftpretry.sh   ftp.foohost.com pub/foo/bar/bigfile.iso
# See https://docs.oracle.com/cd/E86824_01/html/E54763/ncftpget-1.html
#
# Based on http://www.mcwalter.org/technology/shell/retry_ftp.html
# Copyright (C) 2003 W.Finlay McWalter and the Free Software Foundation.
# Licence: GPL v2.  v1  31st March 2003    Initial Version

# configuration settings
SLEEPTIME=10         # seconds between retries
NCFTPOPTIONS="-F -z" # command line options (passive, resume)
FTP_LOCALROOT=.      # local directory to which files should be retrieved

# Install if not found:

# For macos:
# AUTHOR Mike Gleason, NcFTP Software (http://www.ncftp.com).
NCFTPGET=ncftp    # name and path of Linux ncftpget executable
if ! command -v "${NCFTPGET}" >/dev/null; then  # not installed, so:
   brew install "${NCFTPGET}"
      # Installing from https://www.ncftp.com/ncftp/doc/ncftpget.html
fi
# TODO: other Linux
"${NCFTPGET}" --version <<EOF
exit
EOF
   # NcFTP 3.2.6 (Dec 04, 2016) by Mike Gleason (http://www.NcFTP.com/contact/).

# check parameters

if [ $# -ne 2 ] ; then
  echo "usage:"
  echo "  safeget server-name remote-file"
  exit 20
fi

# TODO: add support for username and password

# Inside ncftp> quit

until false 
do
  $NCFTPGET $1 $FTP_LOCALROOT $2
  RESULT=$?

  echo `date` ncftpget returns $RESULT

  case $RESULT in
  0)                    echo success
                        exit 0
                        ;;
  
  7|8|9|10|11)          echo nonrecoverable error \($RESULT\) 
                        exit $RESULT
                        ;;
  
  1|2|3|4|5|6)          echo recoverable error \($RESULT\)
                        sleep $SLEEPTIME
                        ;;
  
  *)                    echo unknown error code \($RESULT\)
                        exit $RESULT
                        ;;
  esac
done

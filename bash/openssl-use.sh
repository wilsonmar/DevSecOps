#!/bin/bash
# openssl-use.sh - encrypt files with aes-256-cbc cipher using openssl
# From https://superuser.com/questions/370388/simple-built-in-way-to-encrypt-and-decrypt-a-file-on-a-mac-via-command-line

# encrypt files:
if [ $1 == "-e" ];
then
    if [ -f "$2" ];
    then
    openssl aes-256-cbc -a -e -salt -in "$2" -out "$2.aes"
    else
       echo "This file does not exist!" 
    fi

# decrypt files:
elif [ $1 == "-d" ];then
    if [ -f "$2" ];
    then
        openssl aes-256-cbc -a -d -salt -in "$2" -out "$2.decrypt"
    else
        echo "This file does not exist!" 
    fi

# show help:
elif [ $1 == "--help" ];then
    echo "This software uses openssl for encrypting files with the aes-256-cbc cipher"
    echo "Usage for encrypting: ./encrypt -e [file]"
    echo "Usage for decrypting: ./encrypt -d [file]"
else
    echo "This action does not exist!"
    echo "Use ./encrypt --help to show help."
fi
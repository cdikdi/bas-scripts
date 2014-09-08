#!/bin/bash
###################
# by: Jonathan Garza
###################
# date: 09/07/2014
###################
# Sample script for planting our flag and changing files permissions so that
# others cannot modify it.
# 
###################

echo "This script checks for the existence of the flag file. If found will plant our flag in it"
echo "Checking..."

file=~/scripts/Flag.txt

if [ -e "$file" ];
    then 
	echo "Flag file exists"
    	echo "0xAAAFlagString" >> "$file" && echo "The Flag has been planted!!"

fi
if [ ! -e "$file" ];
   then 
	echo "The flag file does NOT exist"

fi

sleep 1s

# These lines will change file perm to read only for all owner,group,world.

if [ -w "$file" ];
   then 
	chmod 444 "$file" && echo "The Flag file is now secured!"

elif [ ! -w "$file" ];
   then 
	echo "The file is not writeable"
	exit 1
fi

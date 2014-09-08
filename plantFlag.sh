#!/bin/bash -x
###################
# by: Jonathan Garza
###################
# date: 09/07/2014
###################
# Sample script for planting our flag and changing files permissions so that
# others cannot modify it.
#
# ATTENTION: This is original work from arthor. Will accept additions/modifications to this version. Original source is with
# said author.
#
#################
# Modifcations:
# 09/07/14(JG): included the 'read' variable for taking input from user. Making it interactive for variable cases in which we must
# accomodate dynamic changes within script variables.
#
#
# 
###################

#file=~/scripts/Flag.txt

echo "This script checks for the existence of the flag file. If found will plant our flag in it"
read -p "Hi "$USER". Type the directory path of known flag.txt file here:" file

echo "your dir $file"
echo "Checking..."

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
	#added chattr +i for imutability
	chmod 444 "$file" && chattr +i "$file" && echo "The Flag file is now secured!"

elif [ ! -w "$file" ];
   then 
	echo "The file is not writeable"
	exit 1
fi

#!/bin/bash

# Bulk SAPR -> LZSS Conversion Script for Linux
# By VinsCool
# 
# The LZSS Program to be called must be located inside of the same Folder from which this Script is going to be executed
# Also, this Script will only search for SAPR Files located inside of Folders relative to the Script File itself, specifically
# This was done on purpose to avoid clutter, however it should be trivial to edit the Script to make it point elsewhere, if needed

# Script Variables used for 'Successful File Count', 'Current File Index', and 'Total File Count', in this order
count=0
index=0
total=0

# Started!
echo -e "> Searching for SAP Type R files..."

# First Pass, Count how many Files are expected to be processed
#for i in "$1"**/*.sap*;
for i in "$1"*RANDOM5/*.sap*;
do
	if [ -e "$i" ];
	then
		total=$((total+1))
		echo -e "Found '"$i"'"
	fi
done

# Reason for this quirk: RMT saves SAPR files using the .sapr extension, literally!
# Can't be bothered to narrow it down further, anything saved with the .sap extension, followed with a random 4th character will do
# At worst, the incompatible files will be rejected by LZSS instantly, since it will specifically look for the SAP Header anyway!
# Long story short: this is a non-issue, so let's just not think about it, everything should be fine ;)
if [ $total == 0 ];
then
	echo -e "> Found absolutely Nothing, maybe try a different folder?"
	exit
else
	echo -e "> A total of "$total" Files were found!"
fi

# Second Pass, Attempt to Process all of the Files that were found in First Pass, and Count how many of them returned without error
#for i in "$1"**/*.sap*;
for i in "$1"*RANDOM5/*.sap*;
do
	if [ -e "$i" ];
	then
		index=$((index+1))
		echo -e ""
		echo -e ">>> Processing File "$index" of "$total"..."
		echo -e ""
		echo -e "> Loaded '""$i""'"
		o="${i%.*}.lzss"
		./lzss -6 -q "$i" "$o"
		if [ $? -ne 0 ];
		then
			echo -e "> No data was saved!"
		else
			count=$((count+1))
			echo -e "> Saved '""$o""'"
		fi
	fi
done

# Finished!
echo -e ""
echo -e "> Done!"

# If everything went well, then good! If something went wrong, well shit!
if [ $count != $total ];
then
	echo -e "> Only "$count" of "$total" File(s) were processed without error, uh oh!"
else	
	echo -e "> All "$count" of "$total" File(s) were processed without error, nice!"
fi


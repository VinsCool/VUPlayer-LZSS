#!/bin/bash

# Bulk SAPR -> LZSS Conversion Script for Linux
# By VinsCool
# 
# The LZSS Program to be called must be located inside of the same Folder from which this Script is going to be executed
# Also, this Script will only search for SAPR Files located inside of Folders relative to the Script File itself, specifically
# This was done on purpose to avoid clutter, however it should be trivial to edit the Script to make it point elsewhere, if needed
# 
# Usage: './bulk.sh path arg1 arg2 arg3 arg4'
# 
# By default, the Script will only search for Files inside all Subfolders, but not inside the current Folder
# Path may be set to './', to limit the search inside all Subfolders, but exclude the current Folder
# Path may be set to '../' to limit the search inside the current Folder, but exclude all Subfolders, essentially the reverse idea
# Path may also be set to a given Subfolder name to limit the amount of data to process all at once from multiple Folders
# 
# Optionally, up to 4 additional Arguments may be passed from the Command Line, for more details, run './lzss -h'
# If the additional Arguments aren't needed, they could instead be omitted from the Command Line
# 
# If this makes absolutely no sense, just run './build.sh' and see what happens next, I guess...

# Script Variables used for 'Successful File Count', 'Current File Index', and 'Total File Count', in this order
count=0
index=0
total=0

# Started!
echo -e "> Searching for SAP Type R files..."

# Check for the First Argument to ensure it is not set to use an empty Path in order to be able use this Script properly
# This is also the Default Case for running this Script, to hopefully make things easier to understand for anyone without context
# If this is not Noob Friendly enough, then what the fuck are you doing here, seriously?
# RTFM, and don't even bother trying to contact me and waste my time for basic Command Line help
# If you can't figure it out all by yourself, well, this thing is not made for you, sorry
if [ "$1" == '' ];
then
	echo -e "> Error: No Path was specified!"
	./lzss -h
	echo -e "> Try running '"$0" ./' to get started"
	echo -e "> For more details, open '"$0"' in a text editor"
	exit
fi

# First Pass, Count how many Files are expected to be processed
# Optionally, the first Argument may be used to specify a Path to scan if more than 1 Folder is present and/or too many files are found
for i in "$1"*/*.sap*;
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
for i in "$1"*/*.sap*;
do
	if [ -e "$i" ];
	then
		index=$((index+1))
		echo -e ""
		echo -e ">>> Processing File "$index" of "$total"..."
		echo -e ""
		echo -e "> Loaded '""$i""'"
		o="${i%.*}.lzss"
		./lzss -6 -q "$i" "$o" "$2" "$3" "$4" "$5"
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


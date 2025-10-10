#!/bin/bash

echo -e "> Searching for SAPR files..."

for i in "$1"**/*.sapr;
do
	echo -e ""
	echo -e "> Loaded '""$i""'"
	o="${i%.*}.lzss"
	./lzss -6 -q "$i" "$o";
	echo -e "> Saved '""$o""'"
done

echo -e ""
echo -e "> Done!"


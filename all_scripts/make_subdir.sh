#!/usr/bin/bash

args=("$@")
filename=${args[0]}
 

while IFS=' ' read -r value1 value2 remainder; do 
#read -r line || [[ -n "$line" ]]; read -r value1 value2 remainder; do 
#       echo "read line $line"
	echo "$value2" 
	
done < "$filename"      
 

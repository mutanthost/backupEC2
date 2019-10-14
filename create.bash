#!/usr/bin/env bash

#Prompt user data
read -p "Enter database " database
read -p "Enter  rman script: " rmanscript
read -p "Enter another variable: " another1
read -p "Enter another variable: " another2
read -p "Enter yet another variable: " yav1

#Initialize data to zero integer.
balance=0

#Exit with an error message if data file already exists
if [ -f ./Data/$database.txt ]; then
    echo "Error: database config  file already exists"
else
    #Create database file based on input.
    echo "$database $rmanscript" > ./Data/$database.txt
    #Append variables to file
    echo "$database $rmanscript $another1 $another2 $yav1" >> ./Data/$database.txt
fi


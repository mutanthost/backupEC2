#!/usr/bin/env bash
#Prompt for database to search for.
echo ""
read -p "Enter database: " database

#Search the Data directory for the database
#and display search results. Display an error message if the database 
#is NOT found.
# Options: -F fixed pattern (i.e. is NOT regular expression)
#          -w matches whole word and NOT as a substring of another word
#          -l only list file names
grep -F -w -l $database ./Data/* > /dev/null || echo "Error: database not found" 

for file in $(grep -F -w -l $database ./Data/*); do
    cat < $file
done
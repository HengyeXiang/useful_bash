#!/bin/bash

# Define the script name you want to run on each .com file
SCRIPT_NAME="qg16.smp"  # Replace with the actual script name

# Loop through all .com files in the current directory
for file in *.com; do
  if [[ -f "$file" ]]; then  # Check if it's a file
    echo "Processing $file"
    $SCRIPT_NAME "$file"  # Execute the script directly with the file as an argument
  fi
done
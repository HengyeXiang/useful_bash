#!/bin/bash

# Step 1: Define the input file containing template lines (input.txt in this example).
TEMPLATE_FILE="input.txt"

# Step 2: Loop through all .out files in the current directory.
for file in *.out; do

    # Extract the base name of the file to create the corresponding .com file.
    base_name="${file%.out}"
    # change the ts suffix below to your desired file name suffix, like for single point, change it to sp
    output_file="${base_name}_ts.com"

    # Step 3: Identify the start and end lines for extraction.
    # Find the line number for the last occurrence where the line starts with "Charge =".
    start_line=$(grep -n "^\s*Charge =" "$file" | tail -n 1 | awk -F: '{print $1}')

    # Check if start_line was successfully extracted and is not empty.
    if [[ -z "$start_line" || ! "$start_line" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid or missing line number for 'Charge =' in file $file"
        continue
    fi

    # Add 2 to start reading two lines after "Charge = ...".
    extract_start=$((start_line + 2))

    # Find the line number where "Recover connectivity data from disk." appears.
    end_line=$(grep -n "Recover connectivity data from disk." "$file" | awk -F: '{print $1}')

    # Check if end_line was successfully extracted and is not empty.
    if [[ -z "$end_line" || ! "$end_line" =~ ^[0-9]+$ ]]; then
        echo "Error: Invalid or missing line number for 'Recover connectivity data from disk.' in file $file"
        continue
    fi

    # Step 4: Extract the required lines and reformat the data for comma-separated values.
    awk -F',' -v start="$extract_start" -v end="$end_line" 'NR >= start && NR < end {
        atom=$1; x=$3; y=$4; z=$5;
        printf("%s                  %9.6f    %9.6f    %9.6f\n", atom, x, y, z); # Add leading whitespace and align columns properly
    }' "$file" > coordinates.tmp

    # Step 5: Write the template and extracted coordinates into the .com file.
    {
        # Write the first seven lines of the template file.
        # This depends on your input file format
        # Number 7 usually includes lines of core, memory, keyword, note, charge and multiplicity info
        head -n 7 "$TEMPLATE_FILE"

        # Write the extracted coordinates.
        cat coordinates.tmp

        # Write the lines after the seventh line of the template file.
        tail -n +8 "$TEMPLATE_FILE"
    } > "$output_file"

    # Step 6: Clean up temporary files.
    rm coordinates.tmp

done





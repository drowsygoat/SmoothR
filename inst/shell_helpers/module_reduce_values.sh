#!/bin/bash

# used to reduce the file size by sunntin signif digits and removing unnecessary columns from the data

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="pigzz"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
DRY="no"

process_file() {
    local input=$1
    local output=$2

    # Example modification: copy the file content (you can replace this with actual processing)

    echo "Input: $input"
    echo "Output: $output"

    export input output

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" \
    'zcat "$input" | cut -f1,2,3,4,5 | subset_rows.sh -s 0.01 -h > "$output" && pigz -f "$output"'


    # 'zcat "$input_file" | cut -f1,2,3,4,5 > "$output_file" && pigz -f "$output_file"'
    # 'zcat "$input_file" | reduce_values.sh 1,2,3,4,5 3,4,5 > "$output_file" && pigz -f "$output_file"'
}

# Directory and pattern
input_directory=${1:-.}  # Default to current directory if no argument is given

# Check if output directory is provided as the second argument
output_directory=${2:-$input_directory}

patterns=("*eQTL_trans_reduced.txt.gz")

file_counter=0

# Iterate over files in the directory matching the pattern

for pattern in "${patterns[@]}"; do
    for file in ${input_directory}/${pattern}; do
        # Check if the file exists (necessary if no files match the pattern)
        if [ ! -f "$file" ]; then
            echo "No files found matching pattern: $pattern in directory: $directory"
            continue
        fi

        # Extract the base name up to the first dot
        base_name=$(basename "$file")
        name_until_dot="${base_name%%.*}"

        # Construct the output file name
        output_file="${output_directory}/${name_until_dot}_reduced_sub.txt"
        
        if [[ ! "$file" == *dardel* ]]; then
            process_file "$file" "$output_file"
            echo "Processed $file -> $output_file"
            ((file_counter++))
        else
            echo "Skipping ${file} cause ${output_file}.gz exists."
        fi
    done
done

echo "Total files processed: $file_counter"

        # if [ ! -f "${output_file}.fgz" ]; then
        #     process_file "$file" "$output_file"
        #     echo "Processed $file -> $output_file"
        #     ((file_counter++))
        # else
#!/bin/bash


# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="pigzz"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
DRY="with_eval"

process_file() {
    local input_file=$1
    local output_file=$2

    # Example modification: copy the file content (you can replace this with actual processing)

    echo "$input_file"
    echo "$output_file"

    export input_file output_file

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" \
    'zcat "$input_file" | reduce_values.sh 1,2,4 3,4,5 > "$output_file"'
}

# Directory and pattern
input_directory=${1:-.}  # Default to current directory if no argument is given

# Check if output directory is provided as the second argument
output_directory=${2:-$input_directory}

pattern="*eQTL_*.txt.gz"

file_counter=0

# Iterate over files in the directory matching the pattern
for file in ${input_directory}/${pattern}; do
    # Check if the file exists (necessary if no files match the pattern)
    if [ ! -f "$file" ]; then
        echo "No files found matching pattern: $pattern in directory: $directory"
        continue
    fi

    ((file_counter++))

    # Extract the base name up to the first dot
    base_name=$(basename "$file")
    name_until_dot="${base_name%%.*}"

    # Construct the output file name
    output_file="${output_directory}/${name_until_dot}_reduced.txt"

    # Apply the processing function
    process_file "$file" "$output_file"

    echo "Processed $file -> $output_file"

done

echo "Total files processed: $file_counter"

# && pigz -f "$output_file"
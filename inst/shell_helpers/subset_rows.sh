#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -s fraction [-h] [input_file]"
    echo "  -s fraction   Fraction of lines to select (between 0 and 1)"
    echo "  -h            Preserve the header row"
    echo "  input_file    Optional input file. If not provided, reads from standard input."
    exit 1
}

# Initialize variables
header_flag=0

# Parse command-line options
while getopts ":s:h" opt; do
    case ${opt} in
        s )
            fraction=${OPTARG}
            ;;
        h )
            header_flag=1
            ;;
        \? )
            usage
            ;;
        : )
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Check if the fraction argument is provided
if [ -z "${fraction}" ]; then
    usage
fi

# Ensure fraction is between 0 and 1
if (( $(echo "$fraction <= 0" | bc -l) )) || (( $(echo "$fraction > 1" | bc -l) )); then
    echo "Fraction must be between 0 and 1"
    exit 1
fi

# Check if input is from a file or standard input
if [ $# -eq 1 ]; then
    input_file=$1
    # Get the total number of lines in the file
    total_lines=$(wc -l < "$input_file")
elif [ -t 0 ]; then
    # No file provided and no input from a pipe
    usage
else
    # Read from standard input
    input_file="/dev/stdin"
    # Count the lines in standard input (redirected from stdin to a temporary file)
    temp_file=$(mktemp -p .)
    cat > "$temp_file"
    total_lines=$(wc -l < "$temp_file")
    input_file="$temp_file"
fi

# Calculate number of lines to select, rounded to the nearest integer
num_lines=$(echo "$fraction * $total_lines + 0.5" | bc | awk '{print int($1)}')

if [ $header_flag -eq 1 ]; then
    # Extract the header
    header=$(head -n 1 "$input_file")

    # Exclude the header from the file before shuffling
    if [ "$input_file" == "/dev/stdin" ]; then
        tail -n +2 "$temp_file" > "${temp_file}.noheader"
        selected_lines=$(shuf -n $((num_lines - 1)) "${temp_file}.noheader")
    else
        tail -n +2 "$input_file" > "${input_file}.noheader"
        selected_lines=$(shuf -n $((num_lines - 1)) "${input_file}.noheader")
    fi
    
    # Print the header and the selected lines
    echo "$header"
    echo "$selected_lines"
else
    # Use shuf to select the random lines and output to stdout
    shuf -n "$num_lines" "$input_file"
fi

# Clean up the temporary file if used
if [ -n "$temp_file" ]; then
    rm "$temp_file" "${temp_file}.noheader"
elif [ -n "${input_file}.noheader" ]; then
    rm "${input_file}.noheader"
fi
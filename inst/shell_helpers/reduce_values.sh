#!/bin/bash

# Path to the AWK script
AWK_SCRIPT_PATH="/cfs/klemming/projects/snic/sllstore2017078/lech/RR/scAnalysis/SmoothR/inst/awk/reduce_values.awk"

#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 input_file columns_to_keep columns_to_format"
    echo "  columns_to_keep   Comma-separated list of columns to keep (e.g., '1,2,3')"
    echo "  columns_to_format Comma-separated list of columns to format (e.g., '4,5')"
    echo "  If no input_file is provided, reads from standard input."
    exit 1
}

# Function to format and keep selected columns of a file or stdin
function reduce_values() {
    local file=$1
    local keep_columns=$2
    local format_columns=$3

    if [[ -n "$file" && "$file" != "-" ]]; then
        gawk -v keep_cols="$keep_columns" -v format_cols="$format_columns" -f $AWK_SCRIPT_PATH "$file"
    else
        gawk -v keep_cols="$keep_columns" -v format_cols="$format_columns" -f $AWK_SCRIPT_PATH
    fi
}

# Check if the number of arguments is at least 3 (for input file, columns to keep, and columns to format)
if [[ $# -lt 2 ]]; then
    usage
fi

# Check if the last argument is a valid file or stdin indicator
if [[ -f "${!#}" || "${!#}" == "-" ]]; then
    input_file="${!#}"
    keep_columns="${1}"
    format_columns="${2}"
else
    input_file="-"
    keep_columns="${1}"
    format_columns="${2}"
fi

# Call the function with the determined input file, columns to keep, and columns to format
reduce_values "$input_file" "$keep_columns" "$format_columns"
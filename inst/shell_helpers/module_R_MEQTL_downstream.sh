#!/bin/bash

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="main"
PARTITION="main"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
DRY="with_eval"

PREFIX="linear"
p_value_threshold="NULL"

process_file() {
    local input=$1
    local output=$2

    # Example modification: copy the file content (you can replace this with actual processing)

    echo "$input"
    echo "$output"

    export input output PREFIX p_value_threshold

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" 'processMEQTLdata.R "$input" "$PREFIX" "$p_value_threshold"'
}

# Directory and pattern
input_directory=${1:-.}  # Default to current directory if no argument is given

# Check if output directory is provided as the second argument
output_directory=${2:-$input_directory}


gather_ntests.R "$input_directory" ntests\\.txt $PREFIX

process_file $input_directory
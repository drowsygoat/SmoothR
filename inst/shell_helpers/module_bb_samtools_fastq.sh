#!/bin/bash

# this is to run bb repair.sh
# for the recovered by Martin SOLiD fastq somehow irepair.sh was exiting with OOM (Terminating due to java.lang.OutOfMemoryError: Java heap space) - whole node used - did not wait
# added sorting with seqkit by name 

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="bb1_rep_bam"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=1
DRY="no"
MODULES="bioinfo-tools,bbmap,samtools"

if [ -d "$JOB_NAME" ]; then
    echo "Warning: Directory $JOB_NAME already exists." >&2
    # exit 1
else
    mkdir -p "$JOB_NAME"
fi

process_file() {
    local input=$1
    local output=$2
    local output2=$3

    echo ""
    echo "Input: $input"
    echo "Output: $output"
    echo "Output2: $output2"

    export input output output2

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    'samtools fastq \
    -1 ${output}  \
    -2 ${output2} \
    ${input}'
    
}

cd  "$JOB_NAME"

SAMPLES="/cfs/klemming/projects/snic/sllstore2017078/lech/sarek/parental_bam_data/*Paired*.bam"

for SAMPLE in $SAMPLES; do
    # Extract the base name by removing the suffix '_1.fastq.gz'
    base=$(basename "$SAMPLE")
    name="${base%__.sorted.bam}"
    dirName="$(dirname ${SAMPLE})"

    # Define input file names
    in1="${SAMPLE}"
    out1="${name}_extracted_1.fastq.gz"
    out2="${name}_extracted_2.fastq.gz"
    
    # Run repair.sh
    process_file ${in1} ${out1} ${out2}

done
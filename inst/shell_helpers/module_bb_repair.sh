#!/bin/bash

# this is to run bb repair.sh
# for the recovered by Martin SOLiD fastq somehow irepair.sh was exiting with OOM (Terminating due to java.lang.OutOfMemoryError: Java heap space) - whole node used - did not wait
# added sorting with seqkit by name 

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="shared_repair_bb_only"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=30
DRY="no"
MODULES="bioinfo-tools,bbmap,SeqKit/2.4.0,samtools"

if [ -d "$JOB_NAME" ]; then
    echo "Warning: Directory $JOB_NAME already exists." >&2
    # exit 1
else
    mkdir -p "$JOB_NAME"
fi

process_file() {
    local input=$1
    local input2=$2
    local output=$3
    local output2=$4
    local outs=$5

    echo ""
    echo "Input: $input"
    sqecho "Input2: $input2"
    echo "Output: $output"
    echo "Output2: $output2"
    echo "Singletons: $outs"

    export input output input2 output2 outs

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    'repair.sh in1=${input} in2=${input2} out1=${output} out2=${output2} outs=${outs} ain=t -eoom -Xmx10g usejni=t'
}

cd  "$JOB_NAME"

SAMPLES=$(ls /cfs/klemming/projects/snic/sllstore2017078/lech/sarek/parental_bam_data/extracted_fastq/*_1.fastq.gz)

for SAMPLE in $SAMPLES; do
    # Extract the base name by removing the suffix '_1.fastq.gz'
    base=$(basename "$SAMPLE")     
    name="${base%_1.fastq.gz}"
    dirName="$(dirname ${SAMPLE})"

    # Define input file names
    in1="${dirName}/${name}_1.fastq.gz"
    in2="${dirName}/${name}_2.fastq.gz"
    out1="${name}_repaired_1.fastq.gz"
    out2="${name}_repaired_2.fastq.gz"
    outs="${name}_singletons.fastq.gz"
    
    # Run repair.sh
    process_file ${in1} ${in2} ${out1} ${out2} ${outs}

done


# seqkit sort -n ${input} -o seqkit_temp1.fastq.gz;
    # seqkit sort -n ${input2} -o seqkit_temp2.fastq.gz;
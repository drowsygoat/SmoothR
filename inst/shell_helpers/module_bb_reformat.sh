#!/bin/bash

# this is to run bb reformat.sh

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="bb1_reformat"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=10
DRY="with_eval"
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

    export input output input2 output2 outs

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    'reformat.sh in=${input} out1=${output} out2=${output2} -eoom -Xmx64g usejni=t'
}

cd  "$JOB_NAME"

SAMPLES=$"/cfs/klemming/projects/supr/sllstore2017078/parental_SOLiD/ail_founders_extraction/ugc_428-2/pairing/F3-F5-BC-Paired.bam"

for SAMPLE in $SAMPLES; do
    # Extract the base name by removing the suffix '_1.fastq.gz'
    base=$(basename "$SAMPLE")
    name="${base%.bam}"
    dirName="$(dirname ${SAMPLE})"

    # Define input file names
    in1="${dirName}/${name}.bam"
    out1="${name}_reformat_1.fastq.gz"
    out2="${name}_reformat_2.fastq.gz"
    
    # Run repair.sh
    process_file ${in1} ${out1} ${out2}

done


# find /cfs/klemming/projects/supr/sllstore2017078/parental_SOLiD/ail_founders_extraction -type f -regex ".*F3.*bam"
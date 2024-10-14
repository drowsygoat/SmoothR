#!/bin/bash

# this is to run bb repair.sh
# for the recovered by Martin SOLiD fastq somehow irepair.sh was exiting with OOM (Terminating due to java.lang.OutOfMemoryError: Java heap space) - whole node used - 

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="repair_sb_ail"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=30
DRY="with_eval"
MODULES="singularity"

# Path mappings
LOCAL_BASE_PATH="/cfs/klemming/projects/snic/sllstore2017078/lech"
CONTAINER_BASE_PATH="/mnt"
SANDBOXES_PATH="/cfs/klemming/projects/supr/sllstore2017078/lech/singularity_sandboxes/"

# Function to translate paths
translate_path() {
    local path=$1
    echo "${path/$LOCAL_BASE_PATH/$CONTAINER_BASE_PATH}"
}

if [ -d "$JOB_NAME" ]; then
    echo "Warning: Directory $JOB_NAME already exists." >&2
    # exit 1
else
    mkdir -p "$JOB_NAME"
fi

process_file() {
    # local input=$1
    # local input2=$2
    # local output=$3
    # local output2=$4
    # local outs=$5

    # Translate paths to container perspective
    local input=$(translate_path "$1")
    local input2=$(translate_path "$2")
    local output=$(translate_path "$3")
    local output2=$(translate_path "$4")
    local outs=$(translate_path "$5")

    echo ""
    echo "Input: $input"
    echo "Output: $output"
    echo "Input2: $input2"
    echo "Output2: $output2"
    echo "Singletons: $outs"

    export input output input2 output2 outs SANDBOXES_PATH LOCAL_BASE_PATH CONTAINER_BASE_PATH 

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    'singularity run --bind ${LOCAL_BASE_PATH}:${CONTAINER_BASE_PATH} ${SANDBOXES_PATH}/bbmap_sb repair.sh in1=${input} in2=${input2} out1=${output} out2=${output2} outs=${outs} ain=t -eoom -Xmx10g usejni=t'
}

cd  "$JOB_NAME"

SAMPLES=$(ls /cfs/klemming/projects/snic/sllstore2017078/lech/testground/bbmap/VE-3293-SC1_S16_L002_*_001.fastq.gz)
# SAMPLES=$(ls /cfs/klemming/projects/snic/sllstore2017078/lech/sarek/parental_solid_by_Martin/*_1.fastq.gz)

for SAMPLE in $SAMPLES; do

    base=$(basename "$SAMPLE")     
    name="${base%_R1_001.fastq.gz}"
    dirName="$(dirname ${SAMPLE})"

    in1="${dirName}/${name}_R1_001.fastq.gz"
    in2="${dirName}/${name}_R2_001.fastq.gz"
    out1="${name}_repaired_R1_001.fastq.gz"
    out2="${name}_repaired_R2_001.fastq.gz"
    outs="${name}_singletons.fastq.gz"
    
    # Run repair.sh
    process_file ${in1} ${in2} ${out1} ${out2} ${outs}
done


# -Djava.io.tmpdir=.
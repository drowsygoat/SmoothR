#!/bin/bash

# Haplotypecaller valilla = no reclalibration - this is to get known variants

# MODULE PARAMETERS
RUN_COMMAND="run_shell_command.sh"
JOB_NAME="haplotypecaller_vanilla"
PARTITION="shared"
NODES=1
TIME="23:05:00"
TASKS=1
CPUS=16
DRY="dry"
MODULES="bioinfo-tools"

if [ -d "$JOB_NAME" ]; then
    echo "Warning: Directory $JOB_NAME already exists." >&2
    # exit 1
else
    mkdir -p "$JOB_NAME"
fi

REF="/cfs/klemming/projects/snic/sllstore2017078/lech/sarek/refs/112/genome/Gallus_gallus.bGalGal1.mat.broiler.GRCg7b.dna_sm.toplevel.fa"

process_file() {
    local input=$1
    local output=$2
    local output2=$3

    echo ""
    echo "Input: $input"
    echo "Output: $output"

    export input output CPUS REF

    $RUN_COMMAND -J "$JOB_NAME" -p "$PARTITION" -n "$TASKS" -t "$TIME" -N "$NODES" -c "$CPUS" -d "$DRY" -o $MODULES \
    'gatk -T HaplotypeCaller -R  -ERC GVCF -I ${input} -nct ${CPUS} -o ${output}'
}

# cd  "$JOB_NAME"

SAMPLES=$(find /cfs/klemming/projects/snic/sllstore2017078/lech/sarek/run1_no_GATK/preprocessing/markduplicates -type f -name "*bam")

for SAMPLE in $SAMPLES; do
    # Extract the base name by removing the suffix '_1.fastq.gz'
    base=$(basename "$SAMPLE")
    name="${base%.bam}"
    dirName="$(dirname ${SAMPLE})"

    # Define input file names
    in1="${dirName}/${name}.bam"
    out="${name}_haplotypecaller_vanilla.g.vcf"
    
    # Run repair.sh
    process_file ${in1} ${out}

done